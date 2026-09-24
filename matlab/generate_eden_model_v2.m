function lattice = generate_eden_model_v2(L, p, seed_pos)
% generate_eden_model_v2.m
% Generate 3D Eden growth model - improved version
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

% Growth loop - much simpler approach
max_attempts = 100000;
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
    
    % Randomly select a neighbor direction
    neighbor_idx = randi(6);
    nx = x + neighbors(neighbor_idx, 1);
    ny = y + neighbors(neighbor_idx, 2);
    nz = z + neighbors(neighbor_idx, 3);
    
    % Check if neighbor is valid and unoccupied
    if nx >= 1 && nx <= L && ny >= 1 && ny <= L && nz >= 1 && nz <= L
        if ~lattice(nx, ny, nz)
            lattice(nx, ny, nz) = true;
            current_sites = current_sites + 1;
        end
    end
end

if attempt >= max_attempts
    fprintf('Eden model v2: Maximum attempts reached\n');
end

% Verify final density
final_density = sum(lattice(:)) / numel(lattice);
fprintf('Eden model v2: Target p=%.3f, Achieved p=%.3f\n', p, final_density);

end
