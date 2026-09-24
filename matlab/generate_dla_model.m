function lattice = generate_dla_model(L, p, seed_pos)
% generate_dla_model.m
% Generate 3D Diffusion Limited Aggregation (DLA) model
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

% 6-neighbor connectivity for DLA
neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];

% Growth loop
max_attempts = 50000;  % Maximum attempts per particle
attempt = 0;
successful_attempts = 0;

while current_sites < target_sites && attempt < max_attempts
    attempt = attempt + 1;
    
    % Start random walk from boundary
    % Choose random position on boundary
    boundary_side = randi(6);
    switch boundary_side
        case 1  % x = 1
            start_pos = [1, randi(L), randi(L)];
        case 2  % x = L
            start_pos = [L, randi(L), randi(L)];
        case 3  % y = 1
            start_pos = [randi(L), 1, randi(L)];
        case 4  % y = L
            start_pos = [randi(L), L, randi(L)];
        case 5  % z = 1
            start_pos = [randi(L), randi(L), 1];
        case 6  % z = L
            start_pos = [randi(L), randi(L), L];
    end
    
    % Random walk
    pos = start_pos;
    max_steps = 1000;
    step = 0;
    
    while step < max_steps
        % Random move
        move = neighbors(randi(6), :);
        new_pos = pos + move;
        
        % Check boundaries
        if all(new_pos >= 1) && all(new_pos <= L)
            % Check if hitting occupied site (neighbor of current position)
            if lattice(new_pos(1), new_pos(2), new_pos(3))
                % Add current position to lattice (not the occupied neighbor)
                if ~lattice(pos(1), pos(2), pos(3))
                    lattice(pos(1), pos(2), pos(3)) = true;
                    current_sites = current_sites + 1;
                    successful_attempts = successful_attempts + 1;
                    break;
                end
            else
                % Move to new position
                pos = new_pos;
            end
        else
            % Hit boundary, restart walk
            break;
        end
        
        step = step + 1;
    end
    
    % If we've made too many attempts, break
    if attempt >= max_attempts
        fprintf('DLA model: Maximum attempts reached\n');
        break;
    end
end

% Verify final density
final_density = sum(lattice(:)) / numel(lattice);
fprintf('DLA model: Target p=%.3f, Achieved p=%.3f, Success rate=%.2f%%\n', ...
        p, final_density, 100*successful_attempts/attempt);

end
