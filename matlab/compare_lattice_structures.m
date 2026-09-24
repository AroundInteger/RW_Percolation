function compare_lattice_structures(L, p_values, save_figures)
% COMPARE_LATTICE_STRUCTURES Enhanced comparison focusing on structural differences
%
% This function creates detailed comparisons that highlight the subtle but important
% differences between templated lattice variants that may not be visible in basic
% 2D slice visualizations.
%
% Inputs:
%   L - Lattice size (creates LxLxL lattices)
%   p_values - Array of occupation probabilities to test
%   save_figures - Boolean to save figures (default: true)

if nargin < 1, L = 60; end
if nargin < 2, p_values = [0.3116, 0.6884, 0.85]; end
if nargin < 3, save_figures = false; end

fprintf('=== Enhanced Lattice Structure Comparison ===\n');
fprintf('Focusing on structural differences between templated variants\n\n');

% Create output directory
output_dir = '';
if save_figures
    output_dir = fullfile(pwd, 'Clusters');
    if ~exist(output_dir, 'dir'), mkdir(output_dir); end
end

% Focus on the 4 main templated variants that should show differences
lattice_names = {
    'Templated 6N',
    'Templated 26N', 
    'Templated Periodic',
    'Templated Min-2N'
};

% Generate lattices with fixed seed for reproducible comparison
rng(42);
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('Analyzing p = %.3f\n', p);
    
    % Generate all 4 templated variants with same seed
    lattices = cell(4, 1);
    cluster_stats = zeros(4, 3); % [num_clusters, largest_cluster, avg_cluster_size]
    
    for variant = 1:4
        rng(42); % Same seed for fair comparison
        switch variant
            case 1 % 6N templated
                opts = struct('mode', 'templated', 'connectivity', 6);
            case 2 % 26N templated  
                opts = struct('mode', 'templated', 'connectivity', 26);
            case 3 % Periodic templated
                opts = struct('mode', 'templated', 'connectivity', 6, 'periodic', true);
            case 4 % Min 2 neighbors
                opts = struct('mode', 'templated', 'connectivity', 6, 'min_neighbors', 2);
        end
        
        lattices{variant} = generate_templated_growth_3d_advanced(L, p, opts);
        
        % Analyze clusters
        [num_clusters, cluster_sizes] = analyze_3d_clusters(lattices{variant});
        cluster_stats(variant, 1) = num_clusters;
        if ~isempty(cluster_sizes)
            cluster_stats(variant, 2) = max(cluster_sizes);
            cluster_stats(variant, 3) = mean(cluster_sizes);
        end
        
        fprintf('  %s: %d clusters, largest %d, avg %.1f\n', ...
            lattice_names{variant}, cluster_stats(variant, 1), ...
            cluster_stats(variant, 2), cluster_stats(variant, 3));
    end
    
    % Create enhanced visualizations
    create_structure_comparison_figure(lattices, lattice_names, p, L, save_figures, output_dir);
    create_connectivity_analysis_figure(lattices, lattice_names, cluster_stats, p, L, save_figures, output_dir);
end

fprintf('\n=== Enhanced Comparison Complete ===\n');

end

function create_structure_comparison_figure(lattices, lattice_names, p, L, save_figures, output_dir)
% Create figure showing multiple views to highlight structural differences

fig = figure('Position', [100, 100, 1600, 1000], 'Name', sprintf('Structure Comparison p=%.3f', p));

% Show 3 different slices for each variant
slice_positions = [round(L*0.3), round(L*0.5), round(L*0.7)]; % 30%, 50%, 70%

for variant = 1:4
    for slice_idx = 1:3
        subplot_idx = (variant-1)*3 + slice_idx;
        subplot(4, 3, subplot_idx);
        
        z_slice = slice_positions(slice_idx);
        slice_data = lattices{variant}(:, :, z_slice);
        
        imagesc(slice_data);
        axis equal tight;
        
        if slice_idx == 1
            ylabel(lattice_names{variant}, 'FontWeight', 'bold');
        end
        if variant == 1
            title(sprintf('Slice z=%d (%.0f%%)', z_slice, z_slice/L*100));
        end
        
        % Add density info
        density = sum(lattices{variant}(:)) / L^3;
        if variant == 4 && slice_idx == 3
            xlabel(sprintf('Density: %.3f', density));
        end
        
        colormap(gca, 'hot');
        set(gca, 'FontSize', 8);
    end
end

sgtitle(sprintf('Structural Comparison: Multiple Slices (p=%.3f, L=%d)', p, L), 'FontSize', 14);

if save_figures
    filename = fullfile(output_dir, sprintf('structure_comparison_p%.3f_L%d.png', p, L));
    saveas(fig, filename, 'png');
    fprintf('  Saved: %s\n', filename);
end

end

function create_connectivity_analysis_figure(lattices, lattice_names, cluster_stats, p, L, save_figures, output_dir)
% Create detailed connectivity analysis

fig = figure('Position', [200, 200, 1400, 800], 'Name', sprintf('Connectivity Analysis p=%.3f', p));

% Subplot 1: Cluster statistics bar chart
subplot(2, 3, 1);
bar(cluster_stats(:, 1));
set(gca, 'XTickLabel', lattice_names, 'XTickLabelRotation', 45);
ylabel('Number of Clusters');
title('Cluster Count Comparison');
grid on;

subplot(2, 3, 2);
bar(cluster_stats(:, 2));
set(gca, 'XTickLabel', lattice_names, 'XTickLabelRotation', 45);
ylabel('Largest Cluster Size');
title('Largest Cluster Comparison');
grid on;

subplot(2, 3, 3);
bar(cluster_stats(:, 3));
set(gca, 'XTickLabel', lattice_names, 'XTickLabelRotation', 45);
ylabel('Average Cluster Size');
title('Average Cluster Size');
grid on;

% Subplot 4-6: Cluster size distributions
for variant = 1:3  % Show first 3 variants (skip min-2N as it's very different)
    subplot(2, 3, 3 + variant);
    
    [num_clusters, cluster_sizes] = analyze_3d_clusters(lattices{variant});
    if ~isempty(cluster_sizes) && any(cluster_sizes > 1)
        num_bins = round(min(50, max(10, num_clusters/10)));
        histogram(cluster_sizes, num_bins, 'FaceAlpha', 0.7);
        set(gca, 'YScale', 'log');
        xlabel('Cluster Size');
        ylabel('Frequency');
        title(lattice_names{variant});
        grid on;
    else
        text(0.5, 0.5, 'No clusters > 1', 'HorizontalAlignment', 'center', ...
            'Units', 'normalized', 'FontSize', 12);
        title(lattice_names{variant});
    end
end

sgtitle(sprintf('Connectivity Analysis (p=%.3f, L=%d)', p, L), 'FontSize', 14);

if save_figures
    filename = fullfile(output_dir, sprintf('connectivity_analysis_p%.3f_L%d.png', p, L));
    saveas(fig, filename, 'png');
    fprintf('  Saved: %s\n', filename);
end

end
