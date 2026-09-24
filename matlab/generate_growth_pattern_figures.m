function generate_growth_pattern_figures()
% Generate 2D growth pattern visualizations for the paper
% Creates figures showing different lattice generation methods at various p-values
clc; close all
% Parameters
L = 200;  % 2D lattice size for visualization
p_values = [0.1, 0.3, 0.5, 0.7];  % Occupation probabilities to visualize
num_methods = 4;

% Method names and options
method_names = {'Random Percolation', 'Density Increment', '6N Templating', '26N Templating'};
method_opts = {
    struct('mode', 'random'),    struct('mode', 'density_increment'),...
    struct('mode', 'templated', 'connectivity', 6, 'periodic', true),...
    struct('mode', 'templated', 'connectivity', 26, 'periodic', true)

};

% Create output directory
output_dir = '../paper_drafts/figures';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Set random seed for reproducibility
rng(23);

fprintf('Generating growth pattern visualizations...\n');

% Generate lattices for each method and p-value
lattices = cell(length(p_values), num_methods);

for method_idx = 1:num_methods
    fprintf('  Method %d: %s\n', method_idx, method_names{method_idx});
    
    for p_idx = 1:length(p_values)
        p = p_values(p_idx);
        fprintf('    p = %.1f\n', p);
        
        % Generate 3D lattice
        lattice_3d = generate_templated_growth_3d_advanced(L, p, method_opts{method_idx});
        
        % Take 2D slice (middle slice)
        lattice_2d = lattice_3d(:, :, round(L/2));
        
        % Store for visualization
        lattices{p_idx, method_idx} = lattice_2d;
    end
end

% Create main growth patterns figure
create_growth_patterns_figure(lattices, p_values, method_names, output_dir,L );

% Create connectivity rules figure
create_connectivity_rules_figure(output_dir);

fprintf('Growth pattern figures generated successfully!\n');
fprintf('Output directory: %s\n', output_dir);

end

function create_growth_patterns_figure(lattices, p_values, method_names, output_dir, L)
% Create the main growth patterns figure

% Create figure
fig = figure('Position', [100, 100, 1200, 1000]);
set(fig, 'Color', 'white');

% Panel layout: 4 rows (p-values) x 4 columns (methods)
for p_idx = 1:length(p_values)
    for method_idx = 1:4
        subplot_idx = (p_idx - 1) * 4 + method_idx;
        subplot(4, 4, subplot_idx);
        
        % Get lattice data
        lattice = lattices{p_idx, method_idx};
        
        % Create visualization
        imagesc(lattice);
        colormap(gca, [1 1 1; 0 0 0]);  % White for unoccupied, black for occupied
        axis equal tight;
        axis off;
        
        % Add labels
        if p_idx == 1
            title(method_names{method_idx}, 'FontSize', 10, 'FontWeight', 'bold');
        end
        
        if method_idx == 1
            ylabel(sprintf('p = %.1f', p_values(p_idx)), 'FontSize', 10, 'FontWeight', 'bold');
        end
        
        % Add scale bar for bottom-left panel
        if p_idx == length(p_values) && method_idx == 1
            hold on;
            scale_length = L/10;  % 10% of lattice size
            line([10, 10+scale_length], [L-10, L-10], 'Color', 'red', 'LineWidth', 2);
            text(10+scale_length/2, L-15, sprintf('%d units', round(scale_length)), ...
                'HorizontalAlignment', 'center', 'Color', 'red', 'FontSize', 8);
        end
    end
end

% Add overall title
sgtitle('Growth Patterns for Different Lattice Generation Methods', ...
    'FontSize', 14, 'FontWeight', 'bold');

% Save figure
% saveas(fig, fullfile(output_dir, 'growth_patterns.png'));
% saveas(fig, fullfile(output_dir, 'growth_patterns.fig'));

% Create individual method figures
for method_idx = 1:4
    create_individual_method_figure(lattices, p_values, method_names{method_idx}, method_idx, output_dir);
end

close(fig);
end

function create_individual_method_figure(lattices, p_values, method_name, method_idx, output_dir)
% Create individual figure for each method

fig = figure('Position', [100, 100, 800, 600]);
set(fig, 'Color', 'white');

for p_idx = 1:length(p_values)
    subplot(2, 2, p_idx);
    
    % Get lattice data
    lattice = lattices{p_idx, method_idx};
    
    % Create visualization
    imagesc(lattice);
    colormap(gca, [1 1 1; 0 0 0]);  % White for unoccupied, black for occupied
    axis equal tight;
    axis off;
    
    % Add title
    title(sprintf('%s, p = %.1f', method_name, p_values(p_idx)), ...
        'FontSize', 12, 'FontWeight', 'bold');
    
    % Add scale bar
    hold on;
    L = size(lattice, 1);
    scale_length = L/10;
    line([10, 10+scale_length], [L-10, L-10], 'Color', 'red', 'LineWidth', 2);
    text(10+scale_length/2, L-15, sprintf('%d units', round(scale_length)), ...
        'HorizontalAlignment', 'center', 'Color', 'red', 'FontSize', 10);
end

% % Save figure
% filename = sprintf('growth_patterns_%s.png', lower(strrep(method_name, ' ', '_')));
% saveas(fig, fullfile(output_dir, filename));
% 
% close(fig);
end

function create_connectivity_rules_figure(output_dir)
% Create figure showing neighbor connectivity rules

fig = figure('Position', [100, 100, 1000, 500]);
set(fig, 'Color', 'white');

% 6N Connectivity
subplot(1, 2, 1);
% Create a 3x3x3 grid showing 6N connectivity
[X, Y, Z] = meshgrid(1:3, 1:3, 1:3);
center = [2, 2, 2];

% Plot center point
scatter3(center(1), center(2), center(3), 100, 'filled', 'MarkerFaceColor', 'red');
hold on;

% Plot 6N neighbors (face-adjacent)
neighbors_6N = [
    1, 2, 2; 3, 2, 2;  % x-direction
    2, 1, 2; 2, 3, 2;  % y-direction
    2, 2, 1; 2, 2, 3   % z-direction
];

scatter3(neighbors_6N(:,1), neighbors_6N(:,2), neighbors_6N(:,3), 80, 'filled', 'MarkerFaceColor', 'blue');

% Draw lines to show connectivity
for i = 1:size(neighbors_6N, 1)
    line([center(1), neighbors_6N(i,1)], [center(2), neighbors_6N(i,2)], [center(3), neighbors_6N(i,3)], ...
        'Color', 'black', 'LineWidth', 2);
end

% Plot other points (not connected)
other_points = [];
for x = 1:3
    for y = 1:3
        for z = 1:3
            if ~(x == 2 && y == 2 && z == 2) && ~ismember([x,y,z], neighbors_6N, 'rows')
                other_points = [other_points; x, y, z];
            end
        end
    end
end
scatter3(other_points(:,1), other_points(:,2), other_points(:,3), 60, 'filled', 'MarkerFaceColor', 'lightgray');

xlabel('X'); ylabel('Y'); zlabel('Z');
title('6N Connectivity (6 neighbors)', 'FontSize', 12, 'FontWeight', 'bold');
axis equal;
view(45, 30);
grid on;

% 26N Connectivity
subplot(1, 2, 2);
% Plot center point
scatter3(center(1), center(2), center(3), 100, 'filled', 'MarkerFaceColor', 'red');
hold on;

% Plot all 26 neighbors
neighbors_26N = [];
for x = 1:3
    for y = 1:3
        for z = 1:3
            if ~(x == 2 && y == 2 && z == 2)
                neighbors_26N = [neighbors_26N; x, y, z];
            end
        end
    end
end

scatter3(neighbors_26N(:,1), neighbors_26N(:,2), neighbors_26N(:,3), 80, 'filled', 'MarkerFaceColor', 'blue');

% Draw lines to show connectivity
for i = 1:size(neighbors_26N, 1)
    line([center(1), neighbors_26N(i,1)], [center(2), neighbors_26N(i,2)], [center(3), neighbors_26N(i,3)], ...
        'Color', 'black', 'LineWidth', 1);
end

xlabel('X'); ylabel('Y'); zlabel('Z');
title('26N Connectivity (26 neighbors)', 'FontSize', 12, 'FontWeight', 'bold');
axis equal;
view(45, 30);
grid on;

% Add legend
legend({'Center site', 'Neighbors', 'Other sites'}, 'Location', 'best');

% Save figure
saveas(fig, fullfile(output_dir, 'neighbor_connectivity_rules.png'));
saveas(fig, fullfile(output_dir, 'neighbor_connectivity_rules.fig'));

close(fig);
end
