function lattice = generate_tunable_gel_point_lattice(L, p, target_gel_point, method)
% generate_tunable_gel_point_lattice.m
% Generate lattice with tunable gel-point positioning
% 
% Inputs:
%   L - lattice size (LxLxL)
%   p - target occupation probability
%   target_gel_point - desired gel-point position (0 < target_gel_point < 1)
%   method - '6N', '26N', 'hybrid', or 'adaptive'
%
% Output:
%   lattice - 3D logical array representing occupied sites

if nargin < 4
    method = '6N';
end

% Initialize lattice
lattice = false(L, L, L);

% Place initial seed
center = round(L/2);
lattice(center, center, center) = true;

% Calculate target number of sites
target_sites = round(p * L^3);
current_sites = 1;

% Define connectivity based on method
switch method
    case '6N'
        % 6-neighbor connectivity
        neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];
        connectivity_factor = 1.0;
    case '26N'
        % 26-neighbor connectivity
        [X, Y, Z] = meshgrid(-1:1, -1:1, -1:1);
        neighbors = [X(:), Y(:), Z(:)];
        neighbors(all(neighbors == 0, 2), :) = []; % Remove center
        connectivity_factor = 1.5;
    case 'hybrid'
        % Hybrid connectivity (6N + 26N)
        [X, Y, Z] = meshgrid(-1:1, -1:1, -1:1);
        neighbors = [X(:), Y(:), Z(:)];
        neighbors(all(neighbors == 0, 2), :) = []; % Remove center
        connectivity_factor = 1.2;
    case 'adaptive'
        % Adaptive connectivity based on target gel-point
        [X, Y, Z] = meshgrid(-1:1, -1:1, -1:1);
        neighbors = [X(:), Y(:), Z(:)];
        neighbors(all(neighbors == 0, 2), :) = []; % Remove center
        connectivity_factor = 1.0 + 0.5 * target_gel_point;
    otherwise
        error('Unknown method: %s', method);
end

% Calculate growth parameters based on target gel-point
% Higher target gel-point requires more constrained growth
growth_constraint = 1.0 - target_gel_point;
templating_strength = 0.5 + 0.5 * target_gel_point;

% Growth loop
max_attempts = 10000;
attempt = 0;

while current_sites < target_sites && attempt < max_attempts
    attempt = attempt + 1;
    
    % Find all occupied sites
    [occupied_x, occupied_y, occupied_z] = ind2sub([L, L, L], find(lattice));
    
    if isempty(occupied_x)
        break;
    end
    
    % Calculate current density
    current_density = current_sites / (L^3);
    
    % Adjust growth probability based on density and target gel-point
    if current_density < target_gel_point
        % Below gel-point: more aggressive growth
        growth_prob = 0.8 * (1 - current_density);
    else
        % Above gel-point: more constrained growth
        growth_prob = 0.3 * growth_constraint;
    end
    
    % Randomly select an occupied site
    idx = randi(length(occupied_x));
    x = occupied_x(idx);
    y = occupied_y(idx);
    z = occupied_z(idx);
    
    % Find unoccupied neighbors
    unoccupied_neighbors = [];
    for n = 1:size(neighbors, 1)
        nx = x + neighbors(n, 1);
        ny = y + neighbors(n, 2);
        nz = z + neighbors(n, 3);
        
        if nx >= 1 && nx <= L && ny >= 1 && ny <= L && nz >= 1 && nz <= L
            if ~lattice(nx, ny, nz)
                unoccupied_neighbors = [unoccupied_neighbors; nx, ny, nz];
            end
        end
    end
    
    % If there are unoccupied neighbors, add one with probability
    if ~isempty(unoccupied_neighbors) && rand < growth_prob
        neighbor_idx = randi(size(unoccupied_neighbors, 1));
        nx = unoccupied_neighbors(neighbor_idx, 1);
        ny = unoccupied_neighbors(neighbor_idx, 2);
        nz = unoccupied_neighbors(neighbor_idx, 3);
        
        lattice(nx, ny, nz) = true;
        current_sites = current_sites + 1;
    end
    % If no unoccupied neighbors or growth rejected, continue with next attempt
end

if attempt >= max_attempts
    fprintf('Tunable gel-point: Maximum attempts reached\n');
end

% Verify final density
final_density = sum(lattice(:)) / numel(lattice);
fprintf('Tunable gel-point (%s): Target p=%.3f, Achieved p=%.3f, Target gel-point=%.3f\n', ...
        method, p, final_density, target_gel_point);

end
