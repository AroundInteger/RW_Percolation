function lattice = generate_eden_model(L, p, seed_pos)
% generate_eden_model.m
% Generate 3D Eden growth model
% 
% Inputs:
%   L - lattice size (LxLxL)
%   p - target occupation probability
%   seed_pos - [x,y,z] position of initial seed (optional)
%
% Output:
%   lattice - 3D logical array representing occupied sites

if nargin < 3
    % Default seed position at center
    seed_pos = [round(L/2), round(L/2), round(L/2)];
end

% Initialize lattice
lattice = false(L, L, L);

% Place initial seed
lattice(seed_pos(1), seed_pos(2), seed_pos(3)) = true;

% Calculate target number of sites
target_sites = round(p * L^3);
current_sites = 1;

% 6-neighbor connectivity for Eden growth
neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];

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
    
    % If there are unoccupied neighbors, add one randomly
    if ~isempty(unoccupied_neighbors)
        neighbor_idx = randi(size(unoccupied_neighbors, 1));
        nx = unoccupied_neighbors(neighbor_idx, 1);
        ny = unoccupied_neighbors(neighbor_idx, 2);
        nz = unoccupied_neighbors(neighbor_idx, 3);
        
        lattice(nx, ny, nz) = true;
        current_sites = current_sites + 1;
    end
    % If no unoccupied neighbors, continue with next attempt
end

if attempt >= max_attempts
    fprintf('Eden model: Maximum attempts reached\n');
end

% Verify final density
final_density = sum(lattice(:)) / numel(lattice);
fprintf('Eden model: Target p=%.3f, Achieved p=%.3f\n', p, final_density);

end
