function visualize_lattice_types(L, p_values, save_figures)
% VISUALIZE_LATTICE_TYPES Comprehensive visualization of different 3D lattice types
%
% This function generates and visualizes 7 different types of 3D lattices:
% 1. Templated (6-neighbor, open boundaries)
% 2. Density increment (no adjacency constraints)
% 3. Random percolation
% 4. Templated (26-neighbor, open boundaries)
% 5. Templated (6-neighbor, periodic boundaries)
% 6. Templated with obstacle mask
% 7. Templated with neighbor threshold >= 2
%
% Inputs:
%   L - Lattice size (creates LxLxL lattices)
%   p_values - Array of occupation probabilities to test
%   save_figures - Boolean to save figures (default: true)
%
% Usage:
%   visualize_lattice_types(60, [0.2, 0.5, 0.7])
%   visualize_lattice_types(80, 0.3:0.1:0.6, false)

if nargin < 1, L = 60; end
if nargin < 2, p_values = [0.2, 0.3116, 0.5, 0.6884]; end
if nargin < 3, save_figures = true; end

fprintf('=== 3D Lattice Type Visualization ===\n');
fprintf('Lattice size: %dx%dx%d\n', L, L, L);
fprintf('Testing %d probability values\n', length(p_values));
fprintf('Generating %d lattice types\n\n', 7);

% Create output directory for saved figures
output_dir = '';
if save_figures
    output_dir = fullfile(pwd, 'Clusters');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    fprintf('Figures will be saved to: %s\n\n', output_dir);
end

% Lattice type names and descriptions
lattice_names = {
    'Templated (6N, open)',
    'Density increment',
    'Random percolation',
    'Templated (26N, open)',
    'Templated (6N, periodic)',
    'Templated with obstacle',
    'Templated (min 2 neighbors)'
};

lattice_descriptions = {
    'Adjacency-constrained growth from existing sites',
    'Random addition without adjacency constraints',
    'Independent Bernoulli percolation',
    '26-neighbor connectivity for richer growth',
    'Periodic boundary conditions',
    'Growth around spherical obstacle',
    'Requires at least 2 occupied neighbors'
};

% Build obstacle mask for mode 6
[X, Y, Z] = ndgrid(1:L, 1:L, 1:L);
center = (L+1)/2;
radius = L/4;
mask_obstacle = true(L, L, L);
mask_obstacle((X-center).^2 + (Y-center).^2 + (Z-center).^2 < radius^2) = false;

% Generate all lattices
fprintf('Generating lattices...\n');
lattices = cell(length(p_values), 7);
base_template = false(L, L, L);

for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('  p = %.4f (%d/%d)\n', p, p_idx, length(p_values));
    
    % 1) Templated (6N, open)
    opts = struct('mode', 'templated', 'connectivity', 6, 'periodic', false, 'template', base_template);
    lattices{p_idx, 1} = generate_templated_growth_3d_advanced(L, p, opts);
    base_template = logical(lattices{p_idx, 1});
    
    % 2) Density increment (no adjacency)
    opts = struct('mode', 'density_increment', 'template', false(L, L, L));
    lattices{p_idx, 2} = generate_templated_growth_3d_advanced(L, p, opts);
    
    % 3) Random percolation
    opts = struct('mode', 'random');
    lattices{p_idx, 3} = generate_templated_growth_3d_advanced(L, p, opts);
    
    % 4) Templated 26N
    opts = struct('mode', 'templated', 'connectivity', 26, 'template', base_template);
    lattices{p_idx, 4} = generate_templated_growth_3d_advanced(L, p, opts);
    
    % 5) Templated periodic
    opts = struct('mode', 'templated', 'connectivity', 6, 'periodic', true, 'template', base_template);
    lattices{p_idx, 5} = generate_templated_growth_3d_advanced(L, p, opts);
    
    % 6) Templated with obstacle mask
    opts = struct('mode', 'templated', 'connectivity', 6, 'template', base_template, 'mask', mask_obstacle);
    lattices{p_idx, 6} = generate_templated_growth_3d_advanced(L, p, opts);
    
    % 7) Templated with neighbor threshold >= 2
    opts = struct('mode', 'templated', 'connectivity', 6, 'template', base_template, 'min_neighbors', 2);
    lattices{p_idx, 7} = generate_templated_growth_3d_advanced(L, p, opts);
end

fprintf('Lattice generation complete!\n\n');

% Create comprehensive visualizations
create_comprehensive_visualizations(lattices, p_values, lattice_names, lattice_descriptions, L, save_figures, output_dir);

% Create interactive exploration figure
create_interactive_explorer(lattices, p_values, lattice_names, L, save_figures, output_dir);

% Create cluster analysis comparison
create_cluster_analysis(lattices, p_values, lattice_names, L, save_figures, output_dir);

% Create 3D isosurface comparison
create_3d_isosurface_comparison(lattices, p_values, lattice_names, L, save_figures, output_dir);

% Create enhanced structure comparison (focuses on templated variants)
fprintf('Creating enhanced structure comparison (templated variants only)...\n');
compare_lattice_structures(L, p_values, save_figures);

fprintf('\n=== Visualization Complete ===\n');
if save_figures
    fprintf('All figures saved to: %s\n', output_dir);
end

end

function create_comprehensive_visualizations(lattices, p_values, lattice_names, lattice_descriptions, L, save_figures, output_dir)
% Create comprehensive 2D slice visualizations for all lattice types

fprintf('Creating comprehensive 2D slice visualizations...\n');

% Choose middle slices for visualization
z_slice = round(L/2);
y_slice = round(L/2);
x_slice = round(L/2);

for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    
    % Create figure with all lattice types
    fig = figure('Position', [100, 100, 1600, 1200], 'Name', sprintf('Lattice Types Comparison - p = %.4f', p));
    
    % Create 2x4 subplot layout
    for lat_type = 1:7
        subplot(2, 4, lat_type);
        
        % Show Z-slice (middle slice)
        imagesc(lattices{p_idx, lat_type}(:, :, z_slice));
        title(sprintf('%s\np = %.4f', lattice_names{lat_type}, p), 'FontSize', 10);
        axis equal tight;
        colorbar;
        
        % Add density information
        density = sum(lattices{p_idx, lat_type}(:)) / L^3;
        xlabel(sprintf('Density: %.4f', density));
        
        % Color scheme for better visibility
        colormap(gca, 'hot');
    end
    
    % Add obstacle visualization for mode 6
    subplot(2, 4, 6);
    hold on;
    imagesc(lattices{p_idx, 6}(:, :, z_slice));
    
    % Overlay obstacle boundary
    [X, Y] = meshgrid(1:L, 1:L);
    center = (L+1)/2;
    radius = L/4;
    obstacle_boundary = (X-center).^2 + (Y-center).^2 == radius^2;
    [obs_y, obs_x] = find(obstacle_boundary);
    plot(obs_x, obs_y, 'b-', 'LineWidth', 2);
    
    title(sprintf('Templated with Obstacle\np = %.4f', p), 'FontSize', 10);
    axis equal tight;
    colorbar;
    colormap(gca, 'hot');
    
    % Add overall title
    sgtitle(sprintf('3D Lattice Types Comparison - L = %d, p = %.4f', L, p), 'FontSize', 14);
    
    if save_figures
        filename = fullfile(output_dir, sprintf('lattice_types_p%.4f_L%d.png', p, L));
        saveas(fig, filename, 'png');
        fprintf('  Saved: %s\n', filename);
    end
end

end

function create_interactive_explorer(lattices, p_values, lattice_names, L, save_figures, output_dir)
% Create interactive figure for exploring different slices and lattice types

fprintf('Creating interactive lattice explorer...\n');

fig = figure('Position', [200, 200, 1400, 800], 'Name', 'Interactive Lattice Explorer');

% Create controls
uicontrol('Style', 'text', 'String', 'Lattice Type:', 'Position', [20, 750, 100, 20]);
lattice_popup = uicontrol('Style', 'popup', 'String', lattice_names, 'Position', [130, 750, 200, 20], 'Callback', @update_display);

uicontrol('Style', 'text', 'String', 'Probability:', 'Position', [20, 720, 100, 20]);
p_popup = uicontrol('Style', 'popup', 'String', arrayfun(@(x) sprintf('%.4f', x), p_values, 'UniformOutput', false), 'Position', [130, 720, 200, 20], 'Callback', @update_display);

uicontrol('Style', 'text', 'String', 'Slice Direction:', 'Position', [20, 690, 100, 20]);
slice_popup = uicontrol('Style', 'popup', 'String', {'Z-slice', 'Y-slice', 'X-slice'}, 'Position', [130, 690, 200, 20], 'Callback', @update_display);

uicontrol('Style', 'text', 'String', 'Slice Index:', 'Position', [20, 660, 100, 20]);
slice_slider = uicontrol('Style', 'slider', 'Min', 1, 'Max', L, 'Value', round(L/2), 'Position', [130, 660, 200, 20], 'Callback', @update_display);

% Create display area
subplot('Position', [0.4, 0.1, 0.55, 0.8]);

% Initialize display
update_display();

    function update_display(~, ~)
        lat_type = get(lattice_popup, 'Value');
        p_idx = get(p_popup, 'Value');
        slice_dir = get(slice_popup, 'Value');
        slice_idx = round(get(slice_slider, 'Value'));
        
        % Get current lattice
        current_lattice = lattices{p_idx, lat_type};
        
        % Create slice based on direction
        switch slice_dir
            case 1 % Z-slice
                slice_data = current_lattice(:, :, slice_idx);
                title_str = sprintf('Z-slice at z = %d', slice_idx);
            case 2 % Y-slice
                slice_data = squeeze(current_lattice(:, slice_idx, :));
                title_str = sprintf('Y-slice at y = %d', slice_idx);
            case 3 % X-slice
                slice_data = squeeze(current_lattice(slice_idx, :, :));
                title_str = sprintf('X-slice at x = %d', slice_idx);
        end
        
        % Display slice
        imagesc(slice_data);
        title(sprintf('%s\n%s\np = %.4f', lattice_names{lat_type}, title_str, p_values(p_idx)));
        axis equal tight;
        colorbar;
        colormap(gca, 'hot');
        
        % Add density and cluster info
        density = sum(current_lattice(:)) / L^3;
        [num_clusters, cluster_sizes] = analyze_3d_clusters(current_lattice);
        if ~isempty(cluster_sizes)
            largest_cluster = max(cluster_sizes);
        else
            largest_cluster = 0;
        end
        xlabel(sprintf('Density: %.4f | Clusters: %d | Largest: %d', density, num_clusters, largest_cluster));
    end

if save_figures
    % Note: Interactive explorer with UI components cannot be saved with saveas
    % Create a static version for saving
    try
        filename = fullfile(output_dir, sprintf('interactive_explorer_L%d.png', L));
        % Try to save, but skip if UI components prevent it
        saveas(fig, filename, 'png');
        fprintf('  Saved: %s\n', filename);
    catch
        fprintf('  Interactive explorer not saved (contains UI components)\n');
    end
end

end

function create_cluster_analysis(lattices, p_values, lattice_names, L, save_figures, output_dir)
% Create cluster analysis comparison across all lattice types

fprintf('Creating cluster analysis comparison...\n');

% Analyze clusters for all lattices
cluster_stats = zeros(length(p_values), 7, 3); % [p_values, lattice_types, stats: num_clusters, largest_cluster, avg_cluster_size]

for p_idx = 1:length(p_values)
    for lat_type = 1:7
        [num_clusters, cluster_sizes] = analyze_3d_clusters(lattices{p_idx, lat_type});
        cluster_stats(p_idx, lat_type, 1) = num_clusters;
        if ~isempty(cluster_sizes)
            cluster_stats(p_idx, lat_type, 2) = max(cluster_sizes);
            cluster_stats(p_idx, lat_type, 3) = mean(cluster_sizes);
        else
            cluster_stats(p_idx, lat_type, 2) = 0;
            cluster_stats(p_idx, lat_type, 3) = 0;
        end
    end
end

% Create comparison plots
fig = figure('Position', [300, 300, 1400, 1000], 'Name', 'Cluster Analysis Comparison');

% Number of clusters
subplot(2, 2, 1);
for lat_type = 1:7
    plot(p_values, squeeze(cluster_stats(:, lat_type, 1)), 'o-', 'LineWidth', 2, 'DisplayName', lattice_names{lat_type});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Number of Clusters');
title('Number of Clusters vs. p');
legend('Location', 'best');
grid on;

% Largest cluster size
subplot(2, 2, 2);
for lat_type = 1:7
    plot(p_values, squeeze(cluster_stats(:, lat_type, 2)), 's-', 'LineWidth', 2, 'DisplayName', lattice_names{lat_type});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Largest Cluster Size');
title('Largest Cluster Size vs. p');
legend('Location', 'best');
grid on;

% Average cluster size
subplot(2, 2, 3);
for lat_type = 1:7
    plot(p_values, squeeze(cluster_stats(:, lat_type, 3)), '^-', 'LineWidth', 2, 'DisplayName', lattice_names{lat_type});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Average Cluster Size');
title('Average Cluster Size vs. p');
legend('Location', 'best');
grid on;

% Cluster size distribution for selected p-value
subplot(2, 2, 4);
p_idx = round(length(p_values)/2); % Middle p-value
p_selected = p_values(p_idx);

for lat_type = 1:7
    [~, cluster_sizes] = analyze_3d_clusters(lattices{p_idx, lat_type});
    if ~isempty(cluster_sizes) && any(cluster_sizes > 0)
        histogram(cluster_sizes, 20, 'DisplayName', lattice_names{lat_type}, 'FaceAlpha', 0.7);
        hold on;
    end
end
xlabel('Cluster Size');
ylabel('Frequency');
title(sprintf('Cluster Size Distribution (p = %.4f)', p_selected));
legend('Location', 'best');
set(gca, 'YScale', 'log');

sgtitle(sprintf('Cluster Analysis Comparison - L = %d', L), 'FontSize', 14);

if save_figures
    filename = fullfile(output_dir, sprintf('cluster_analysis_L%d.png', L));
    saveas(fig, filename, 'png');
    fprintf('  Saved: %s\n', filename);
end

end

function create_3d_isosurface_comparison(lattices, p_values, lattice_names, L, save_figures, output_dir)
% Create 3D isosurface visualizations for comparison

fprintf('Creating 3D isosurface comparisons...\n');

% Choose a representative p-value for 3D visualization
p_idx = round(length(p_values)/2);
p_selected = p_values(p_idx);

% Create 3D visualization
fig = figure('Position', [400, 400, 1600, 1200], 'Name', '3D Isosurface Comparison');

% Create 2x4 subplot layout for 3D views
for lat_type = 1:7
    subplot(2, 4, lat_type);
    
    % Get current lattice
    current_lattice = lattices{p_idx, lat_type};
    
    % Create 3D isosurface
    [x, y, z] = meshgrid(1:L, 1:L, 1:L);
    
    % Use isosurface with threshold 0.5
    p = patch(isosurface(x, y, z, current_lattice, 0.5));
    p.FaceColor = 'red';
    p.EdgeColor = 'none';
    alpha(0.7);
    
    view(3);
    axis equal;
    grid on;
    title(sprintf('%s\np = %.4f', lattice_names{lat_type}, p_selected), 'FontSize', 9);
    
    % Set consistent view angles
    view(45, 30);
    
    % Add density info
    density = sum(current_lattice(:)) / L^3;
    text(0.02, 0.98, sprintf('Density: %.3f', density), 'Units', 'normalized', 'VerticalAlignment', 'top', 'FontSize', 8);
end

sgtitle(sprintf('3D Isosurface Comparison - L = %d, p = %.4f', L, p_selected), 'FontSize', 14);

if save_figures
    filename = fullfile(output_dir, sprintf('3d_isosurfaces_p%.4f_L%d.png', p_selected, L));
    saveas(fig, filename, 'png');
    fprintf('  Saved: %s\n', filename);
end

end
