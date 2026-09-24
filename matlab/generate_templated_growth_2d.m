function lattice = generate_templated_growth_2d(L, p, template_lattice)
% 2D Templated growth - sites must be adjacent to existing occupied sites
% L: lattice size (L x L)
% p: target occupation probability
% template_lattice: optional existing lattice to build upon (if empty, starts from center seed)

if nargin < 3 || isempty(template_lattice)
    % Start from scratch with center seed
    lattice = zeros(L, L);
    center = round(L/2);
    lattice(center, center) = 1;
    current_sites = 1;
else
    % Use existing lattice as template
    lattice = template_lattice;
    current_sites = sum(lattice(:));
end

target_sites = round(p * L^2);

while current_sites < target_sites
    % Find all unoccupied sites adjacent to occupied sites
    [occupied_x, occupied_y] = ind2sub([L, L], find(lattice));
    adjacent_candidates = [];
    
    for i = 1:length(occupied_x)
        x = occupied_x(i); 
        y = occupied_y(i);
        
        % Check 4 neighbors (up, down, left, right)
        neighbors = [x-1,y; x+1,y; x,y-1; x,y+1];
        
        for j = 1:size(neighbors,1)
            nx = neighbors(j,1); 
            ny = neighbors(j,2);
            
            % Check boundaries
            if nx > 0 && nx <= L && ny > 0 && ny <= L
                if lattice(nx, ny) == 0
                    adjacent_candidates(end+1) = sub2ind([L,L], nx, ny);
                end
            end
        end
    end
    
    adjacent_candidates = unique(adjacent_candidates);
    
    if isempty(adjacent_candidates)
        break;  % No more adjacent sites available
    end
    
    % Select random adjacent site
    selected_idx = adjacent_candidates(randi(length(adjacent_candidates)));
    lattice(selected_idx) = 1;
    current_sites = current_sites + 1;
end

% Display final statistics
final_density = sum(lattice(:)) / L^2;
fprintf('Target density: %.3f, Achieved density: %.3f\n', p, final_density);
fprintf('Target sites: %d, Achieved sites: %d\n', target_sites, sum(lattice(:)));
end