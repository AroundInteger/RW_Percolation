function lattice = generate_hybrid_models(L, p, method)
% generate_hybrid_models.m
% Generate lattices using hybrid approaches that are more efficient
% 
% Inputs:
%   L - lattice size (LxLxL)
%   p - target occupation probability
%   method - 'eden_hybrid', 'dla_hybrid', 'tunable_hybrid'
%
% Output:
%   lattice - 3D logical array representing occupied sites

switch method
    case 'eden_hybrid'
        lattice = generate_eden_hybrid(L, p);
    case 'dla_hybrid'
        lattice = generate_dla_hybrid(L, p);
    case 'tunable_hybrid'
        lattice = generate_tunable_hybrid(L, p);
    otherwise
        error('Unknown method: %s', method);
end

end

function lattice = generate_eden_hybrid(L, p)
    % Hybrid Eden model - combines growth with random filling
    lattice = false(L, L, L);
    
    % Start with a seed
    center = round(L/2);
    lattice(center, center, center) = true;
    
    % Calculate target number of sites
    target_sites = round(p * L^3);
    current_sites = 1;
    
    % 6-neighbor connectivity
    neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];
    
    % Growth phase - grow until we have a reasonable cluster
    growth_target = min(target_sites, round(0.1 * L^3));
    
    while current_sites < growth_target
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
    
    % Fill remaining sites randomly to reach target density
    remaining_sites = target_sites - current_sites;
    if remaining_sites > 0
        % Find unoccupied sites
        [unoccupied_x, unoccupied_y, unoccupied_z] = ind2sub([L, L, L], find(~lattice));
        
        if ~isempty(unoccupied_x) && remaining_sites <= length(unoccupied_x)
            % Randomly select remaining sites
            idx = randperm(length(unoccupied_x), remaining_sites);
            for i = 1:length(idx)
                lattice(unoccupied_x(idx(i)), unoccupied_y(idx(i)), unoccupied_z(idx(i))) = true;
            end
        end
    end
    
    % Verify final density
    final_density = sum(lattice(:)) / numel(lattice);
    fprintf('Eden hybrid: Target p=%.3f, Achieved p=%.3f\n', p, final_density);
end

function lattice = generate_dla_hybrid(L, p)
    % Hybrid DLA model - combines DLA growth with random filling
    lattice = false(L, L, L);
    
    % Start with a seed
    center = round(L/2);
    lattice(center, center, center) = true;
    
    % Calculate target number of sites
    target_sites = round(p * L^3);
    current_sites = 1;
    
    % 6-neighbor connectivity
    neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];
    
    % DLA growth phase - limited attempts
    max_dla_attempts = 5000;
    dla_attempt = 0;
    
    while current_sites < target_sites && dla_attempt < max_dla_attempts
        dla_attempt = dla_attempt + 1;
        
        % Start random walk from boundary
        boundary_side = randi(6);
        switch boundary_side
            case 1, start_pos = [1, randi(L), randi(L)];
            case 2, start_pos = [L, randi(L), randi(L)];
            case 3, start_pos = [randi(L), 1, randi(L)];
            case 4, start_pos = [randi(L), L, randi(L)];
            case 5, start_pos = [randi(L), randi(L), 1];
            case 6, start_pos = [randi(L), randi(L), L];
        end
        
        % Random walk
        pos = start_pos;
        max_steps = 100;
        step = 0;
        
        while step < max_steps
            move = neighbors(randi(6), :);
            new_pos = pos + move;
            
            if all(new_pos >= 1) && all(new_pos <= L)
                if lattice(new_pos(1), new_pos(2), new_pos(3))
                    if ~lattice(pos(1), pos(2), pos(3))
                        lattice(pos(1), pos(2), pos(3)) = true;
                        current_sites = current_sites + 1;
                        break;
                    end
                else
                    pos = new_pos;
                end
            else
                break;
            end
            step = step + 1;
        end
    end
    
    % Fill remaining sites randomly to reach target density
    remaining_sites = target_sites - current_sites;
    if remaining_sites > 0
        [unoccupied_x, unoccupied_y, unoccupied_z] = ind2sub([L, L, L], find(~lattice));
        
        if ~isempty(unoccupied_x) && remaining_sites <= length(unoccupied_x)
            idx = randperm(length(unoccupied_x), remaining_sites);
            for i = 1:length(idx)
                lattice(unoccupied_x(idx(i)), unoccupied_y(idx(i)), unoccupied_z(idx(i))) = true;
            end
        end
    end
    
    % Verify final density
    final_density = sum(lattice(:)) / numel(lattice);
    fprintf('DLA hybrid: Target p=%.3f, Achieved p=%.3f\n', p, final_density);
end

function lattice = generate_tunable_hybrid(L, p)
    % Hybrid tunable model - combines templated growth with random filling
    lattice = false(L, L, L);
    
    % Start with a seed
    center = round(L/2);
    lattice(center, center, center) = true;
    
    % Calculate target number of sites
    target_sites = round(p * L^3);
    current_sites = 1;
    
    % 6-neighbor connectivity
    neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];
    
    % Templated growth phase
    growth_target = min(target_sites, round(0.2 * L^3));
    
    while current_sites < growth_target
        [occupied_x, occupied_y, occupied_z] = ind2sub([L, L, L], find(lattice));
        
        if isempty(occupied_x)
            break;
        end
        
        idx = randi(length(occupied_x));
        x = occupied_x(idx);
        y = occupied_y(idx);
        z = occupied_z(idx);
        
        neighbor_idx = randi(6);
        nx = x + neighbors(neighbor_idx, 1);
        ny = y + neighbors(neighbor_idx, 2);
        nz = z + neighbors(neighbor_idx, 3);
        
        if nx >= 1 && nx <= L && ny >= 1 && ny <= L && nz >= 1 && nz <= L
            if ~lattice(nx, ny, nz)
                lattice(nx, ny, nz) = true;
                current_sites = current_sites + 1;
            end
        end
    end
    
    % Fill remaining sites randomly to reach target density
    remaining_sites = target_sites - current_sites;
    if remaining_sites > 0
        [unoccupied_x, unoccupied_y, unoccupied_z] = ind2sub([L, L, L], find(~lattice));
        
        if ~isempty(unoccupied_x) && remaining_sites <= length(unoccupied_x)
            idx = randperm(length(unoccupied_x), remaining_sites);
            for i = 1:length(idx)
                lattice(unoccupied_x(idx(i)), unoccupied_y(idx(i)), unoccupied_z(idx(i))) = true;
            end
        end
    end
    
    % Verify final density
    final_density = sum(lattice(:)) / numel(lattice);
    fprintf('Tunable hybrid: Target p=%.3f, Achieved p=%.3f\n', p, final_density);
end
