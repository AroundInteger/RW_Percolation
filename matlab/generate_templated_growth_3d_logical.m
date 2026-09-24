function lattice = generate_templated_growth_3d_logical(L, p, template_lattice)
% Ultra-fast 3D growth using pure logical operations and indexing
% L: lattice size (L x L x L)
% p: target occupation probability
% template_lattice: optional existing lattice to build upon

if nargin < 3 || isempty(template_lattice)
    % Start from scratch with random nucleation sites
    lattice = false(L, L, L);
    
    if p > 0
        % For p > 0, create multiple random nucleation sites
        % Number of initial sites scales with probability
        num_nucleation_sites = max(1, round(p * L^2 * 0.1)); % 10% of target density
        
        % Randomly place nucleation sites
        nucleation_indices = randperm(L^3, num_nucleation_sites);
        lattice(nucleation_indices) = true;
        
        current_sites = num_nucleation_sites;
    else
        % For p = 0, just start with center seed
        center = round(L/2);
        lattice(center, center, center) = true;
        current_sites = 1;
    end
else
    % Use existing lattice as template
    lattice = logical(template_lattice);
    current_sites = sum(lattice(:));
end

target_sites = round(p * L^3);

% Pre-allocate for efficiency
max_iterations = target_sites - current_sites;
if max_iterations <= 0
    lattice = double(lattice);
    return;
end

% Use logical indexing for maximum speed
while current_sites < target_sites
    % Shift operations to find neighbors (faster than dilation)
    neighbors = false(L, L, L);
    
    % Shift in x-direction (left, right)
    neighbors(1:end-1, :, :) = neighbors(1:end-1, :, :) | lattice(2:end, :, :);
    neighbors(2:end, :, :) = neighbors(2:end, :, :) | lattice(1:end-1, :, :);
    
    % Shift in y-direction (up, down)
    neighbors(:, 1:end-1, :) = neighbors(:, 1:end-1, :) | lattice(:, 2:end, :);
    neighbors(:, 2:end, :) = neighbors(:, 2:end, :) | lattice(:, 1:end-1, :);
    
    % Shift in z-direction (forward, backward)
    neighbors(:, :, 1:end-1) = neighbors(:, :, 1:end-1) | lattice(:, :, 2:end);
    neighbors(:, :, 2:end) = neighbors(:, :, 2:end) | lattice(:, :, 1:end-1);
    
    % Find candidates
    candidate_mask = neighbors & ~lattice;
    
    if ~any(candidate_mask(:))
        break;
    end
    
    % Find all candidate positions using linear indices
    candidate_linear_indices = find(candidate_mask);
    num_candidates = length(candidate_linear_indices);
    
    % Calculate batch size for efficiency
    batch_size = min(num_candidates, max(1, round(num_candidates * 0.2)));
    batch_size = min(batch_size, target_sites - current_sites);
    
    if batch_size == 0
        break;
    end
    
    % Randomly select batch
    selected_indices = randperm(num_candidates, batch_size);
    
    % Add all sites in batch using linear indexing for speed
    selected_linear_indices = candidate_linear_indices(selected_indices);
    lattice(selected_linear_indices) = true;
    
    current_sites = current_sites + batch_size;
end

% Convert back to double
lattice = double(lattice);

% Display final statistics
final_density = sum(lattice(:)) / L^3;
fprintf('Target density: %.3f, Achieved density: %.3f\n', p, final_density);
fprintf('Target sites: %d, Achieved sites: %d\n', target_sites, sum(lattice(:)));
end
