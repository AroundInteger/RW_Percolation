function lattice = generate_templated_growth_2d_logical(L, p, template_lattice)
% Ultra-fast growth using pure logical operations and indexing
% L: lattice size (L x L)
% p: target occupation probability
% template_lattice: optional existing lattice to build upon

% if nargin < 3 || isempty(template_lattice)
%     lattice = false(L, L);
%     center = round(L/2);
%     lattice(center, center) = true;
%     current_sites = 1;
% else
%     lattice = logical(template_lattice);
%     current_sites = sum(lattice(:));
% end
if nargin < 3 || isempty(template_lattice)
    % Start from scratch with random nucleation sites
    lattice = false(L, L);
    
    if p > 0
        % For p > 0, create multiple random nucleation sites
        % Number of initial sites scales with probability
        num_nucleation_sites = max(1, round(p * L * 0.1)); % 10% of target density
        
        % Randomly place nucleation sites
        nucleation_indices = randperm(L^2, num_nucleation_sites);
        lattice(nucleation_indices) = true;
        
        current_sites = num_nucleation_sites;
    else
        % For p = 0, just start with center seed
        center = round(L/2);
        lattice(center, center) = true;
        current_sites = 1;
    end
else
    % Use existing lattice as template
    lattice = logical(template_lattice);
    current_sites = sum(lattice(:));
end
target_sites = round(p * L^2);

% Pre-allocate for efficiency
max_iterations = target_sites - current_sites;
if max_iterations <= 0
    lattice = double(lattice);
    return;
end

% Use logical indexing for maximum speed
while current_sites < target_sites
    % Shift operations to find neighbors (faster than dilation)
    neighbors = false(L, L);
    
    % Shift up, down, left, right
    neighbors(1:end-1, :) = neighbors(1:end-1, :) | lattice(2:end, :);
    neighbors(2:end, :) = neighbors(2:end, :) | lattice(1:end-1, :);
    neighbors(:, 1:end-1) = neighbors(:, 1:end-1) | lattice(:, 2:end);
    neighbors(:, 2:end) = neighbors(:, 2:end) | lattice(:, 1:end-1);
    
    % Find candidates
    candidate_mask = neighbors & ~lattice;
    
    if ~any(candidate_mask(:))
        break;
    end
    
    % Find all candidate positions
    [candidate_x, candidate_y] = find(candidate_mask);
    num_candidates = length(candidate_x);
    
    % Calculate batch size for efficiency
    batch_size = min(num_candidates, max(1, round(num_candidates * 0.2)));
    batch_size = min(batch_size, target_sites - current_sites);
    
    if batch_size == 0
        break;
    end
    
    % Randomly select batch
    selected_indices = randperm(num_candidates, batch_size);
    
    % Add all sites in batch using linear indexing for speed
    linear_indices = sub2ind([L, L], candidate_x(selected_indices), candidate_y(selected_indices));
    lattice(linear_indices) = true;
    
    current_sites = current_sites + batch_size;
end

% Convert back to double
lattice = double(lattice);

% Display final statistics
final_density = sum(lattice(:)) / L^2;
fprintf('Target density: %.3f, Achieved density: %.3f\n', p, final_density);
fprintf('Target sites: %d, Achieved sites: %d\n', target_sites, sum(lattice(:)));
end