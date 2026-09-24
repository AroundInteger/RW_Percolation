function lattice = generate_rod_template(L, target_sites, orientation, actionable)
% Generate rod-like template structures reminiscent of fibrin networks
% lattice = generate_rod_template(L, target_sites, orientation, actionable)
%
% Inputs:
%   L - lattice size (LxLxL)
%   target_sites - number of sites to occupy
%   orientation - 'x', 'y', 'z', or 'random' for rod direction
%   actionable - logical LxLxL mask of allowed sites
%
% Output:
%   lattice - logical LxLxL lattice with rod-like structures

if nargin < 4
    actionable = true(L, L, L);
end

lattice = false(L, L, L);

if target_sites <= 0
    return;
end

% Handle random orientation
if strcmp(orientation, 'random')
    orientations = {'x', 'y', 'z'};
    orientation = orientations{randi(3)};
end

% Calculate rod parameters
% For rod-like structures, we want elongated shapes rather than spherical
% Number of rods scales with target density
num_rods = max(1, round(sqrt(target_sites / 10))); % Scale with target sites
sites_per_rod = round(target_sites / num_rods);

% Generate rod centers randomly
rod_centers = [];
attempts = 0;
max_attempts = 1000;

while length(rod_centers) < num_rods && attempts < max_attempts
    attempts = attempts + 1;
    
    % Random center position
    center = [randi(L), randi(L), randi(L)];
    
    % Check if center is actionable
    if actionable(center(1), center(2), center(3))
        % Check minimum distance from existing rods
        min_distance = L / 10; % Minimum separation between rods
        too_close = false;
        
        for i = 1:size(rod_centers, 1)
            distance = norm(center - rod_centers(i, :));
            if distance < min_distance
                too_close = true;
                break;
            end
        end
        
        if ~too_close
            rod_centers = [rod_centers; center];
        end
    end
end

% If we couldn't place enough rods, place what we can
if isempty(rod_centers)
    % Fallback: place one rod at center
    center = round(L/2);
    rod_centers = [center, center, center];
    num_rods = 1;
end

% Generate each rod
for rod_idx = 1:size(rod_centers, 1)
    center = rod_centers(rod_idx, :);
    
    % Rod length scales with lattice size
    max_length = round(L * 0.3); % Maximum rod length
    rod_length = min(max_length, round(sites_per_rod / 3)); % Width of rod
    
    % Rod width (perpendicular to main axis)
    rod_width = max(1, round(rod_length / 4)); % Thinner than length
    
    % Generate rod based on orientation
    switch orientation
        case 'x'
            % Rod along x-axis
            x_start = max(1, center(1) - round(rod_length/2));
            x_end = min(L, center(1) + round(rod_length/2));
            y_start = max(1, center(2) - round(rod_width/2));
            y_end = min(L, center(2) + round(rod_width/2));
            z_start = max(1, center(3) - round(rod_width/2));
            z_end = min(L, center(3) + round(rod_width/2));
            
            for x = x_start:x_end
                for y = y_start:y_end
                    for z = z_start:z_end
                        if actionable(x, y, z)
                            lattice(x, y, z) = true;
                        end
                    end
                end
            end
            
        case 'y'
            % Rod along y-axis
            x_start = max(1, center(1) - round(rod_width/2));
            x_end = min(L, center(1) + round(rod_width/2));
            y_start = max(1, center(2) - round(rod_length/2));
            y_end = min(L, center(2) + round(rod_length/2));
            z_start = max(1, center(3) - round(rod_width/2));
            z_end = min(L, center(3) + round(rod_width/2));
            
            for x = x_start:x_end
                for y = y_start:y_end
                    for z = z_start:z_end
                        if actionable(x, y, z)
                            lattice(x, y, z) = true;
                        end
                    end
                end
            end
            
        case 'z'
            % Rod along z-axis
            x_start = max(1, center(1) - round(rod_width/2));
            x_end = min(L, center(1) + round(rod_width/2));
            y_start = max(1, center(2) - round(rod_width/2));
            y_end = min(L, center(2) + round(rod_width/2));
            z_start = max(1, center(3) - round(rod_length/2));
            z_end = min(L, center(3) + round(rod_length/2));
            
            for x = x_start:x_end
                for y = y_start:y_end
                    for z = z_start:z_end
                        if actionable(x, y, z)
                            lattice(x, y, z) = true;
                        end
                    end
                end
            end
    end
end

% If we haven't reached target_sites, add random sites
current_sites = sum(lattice(:));
if current_sites < target_sites
    additional_needed = target_sites - current_sites;
    idx_unocc = find(actionable & ~lattice);
    
    if ~isempty(idx_unocc)
        k = min(additional_needed, length(idx_unocc));
        sel = idx_unocc(randperm(length(idx_unocc), k));
        lattice(sel) = true;
    end
end

% Ensure we don't exceed target
current_sites = sum(lattice(:));
if current_sites > target_sites
    % Randomly remove excess sites
    idx_occ = find(lattice);
    excess = current_sites - target_sites;
    sel = idx_occ(randperm(length(idx_occ), excess));
    lattice(sel) = false;
end

end
