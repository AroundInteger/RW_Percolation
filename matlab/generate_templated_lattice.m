function lattice = generate_templated_lattice(L, p, method)
% generate_templated_lattice.m
% Generate templated lattice (6N or 26N)
% 
% Inputs:
%   L - lattice size (LxLxL)
%   p - target occupation probability
%   method - '6N' or '26N' for connectivity
%
% Output:
%   lattice - 3D logical array representing occupied sites

lattice = false(L, L, L);

% Start with a seed
center = round(L/2);
lattice(center, center, center) = true;

% Grow according to method
if strcmp(method, '6N')
    % 6-neighbor connectivity
    neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];
else % 26N
    % 26-neighbor connectivity
    [X, Y, Z] = meshgrid(-1:1, -1:1, -1:1);
    neighbors = [X(:), Y(:), Z(:)];
    neighbors(all(neighbors == 0, 2), :) = []; % Remove center
end

% Grow until target density
target_sites = round(p * L^3);
current_sites = 1;

while current_sites < target_sites
    % Find occupied sites
    [occupied_x, occupied_y, occupied_z] = ind2sub([L, L, L], find(lattice));
    
    if isempty(occupied_x)
        break;
    end
    
    % Randomly select an occupied site
    idx = randi(length(occupied_x));
    x = occupied_x(idx);
    y = occupied_y(idx);
    z = occupied_z(idx);
    
    % Try to add a neighbor
    for n = 1:size(neighbors, 1)
        nx = x + neighbors(n, 1);
        ny = y + neighbors(n, 2);
        nz = z + neighbors(n, 3);
        
        if nx >= 1 && nx <= L && ny >= 1 && ny <= L && nz >= 1 && nz <= L
            if ~lattice(nx, ny, nz) && rand < 0.5
                lattice(nx, ny, nz) = true;
                current_sites = current_sites + 1;
                break;
            end
        end
    end
end

end
