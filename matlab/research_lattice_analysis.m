function research_lattice_analysis(L, p_values, save_results, output_dir)
% RESEARCH_LATTICE_ANALYSIS Comprehensive analysis for research purposes
%
% This function generates and analyzes 4 key lattice variants across a comprehensive
% range of percolation values, focusing on cluster analysis and structural properties.
%
% Inputs:
%   L - Lattice size (creates LxLxL lattices)
%   p_values - Array of occupation probabilities to test
%   save_results - Boolean to save results (default: true)
%   output_dir - Output directory (default: 'Clusters')
%
% Usage:
%   research_lattice_analysis(500, p_values, true)
%   research_lattice_analysis(500, p_values, true, 'custom_output')

if nargin < 1, L = 500; end
if nargin < 2, p_values = [0, 0.05:0.05:0.3, 0.3116, 0.35:0.01:0.69, 0.6884, 0.69:0.01:0.85, 0.85, 0.86:0.01:0.88, 0.9, 0.95]; end
if nargin < 3, save_results = true; end
if nargin < 4, output_dir = 'Clusters'; end

fprintf('=== Research Lattice Analysis ===\n');
fprintf('Lattice size: %dx%dx%d\n', L, L, L);
fprintf('Testing %d probability values\n', length(p_values));
fprintf('Generating 4 key lattice variants\n\n');

% Create output directory
if save_results
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    fprintf('Results will be saved to: %s\n\n', output_dir);
end

% Lattice variant names and descriptions
variant_names = {
    '6N_Templated',
    '26N_Templated', 
    'Density_Increment',
    'Random_Percolation'
};

variant_descriptions = {
    '6-neighbor templated growth with nucleation',
    '26-neighbor templated growth with nucleation',
    'Random addition without adjacency constraints',
    'Independent Bernoulli percolation'
};

% Initialize results storage
num_variants = 4;
num_p_values = length(p_values);

% Cluster statistics: [p_values, variants, stats: num_clusters, largest_cluster, avg_cluster_size, density]
cluster_stats = zeros(num_p_values, num_variants, 4);

% Lattice storage - always save individual variants for microrheological analysis
store_lattices = true;
fprintf('Note: Storing individual lattice variants for microrheological analysis\n');
fprintf('Each variant will be saved separately to manage memory\n');

% Progress tracking
fprintf('Generating lattices and analyzing clusters...\n');
fprintf('Progress: [');
progress_bar_length = 50;

% Generate and analyze all lattices
base_template = false(L, L, L); % Start with empty template

for p_idx = 1:num_p_values
    p = p_values(p_idx);
    
    % Update progress bar
    progress = p_idx / num_p_values;
    filled_length = round(progress * progress_bar_length);
    fprintf(repmat('█', 1, filled_length));
    fprintf(repmat('░', 1, progress_bar_length - filled_length));
    fprintf('] %.1f%%\r', progress * 100);
    
    % Generate all 4 variants
    for variant = 1:num_variants
        try
            switch variant
                case 1 % 6N Templated
                    opts = struct('mode', 'templated', 'connectivity', 6, 'template', base_template);
                    lattice = generate_templated_growth_3d_advanced(L, p, opts);
                    
                case 2 % 26N Templated
                    opts = struct('mode', 'templated', 'connectivity', 26, 'template', base_template);
                    lattice = generate_templated_growth_3d_advanced(L, p, opts);
                    
                case 3 % Density Increment
                    opts = struct('mode', 'density_increment', 'template', false(L, L, L));
                    lattice = generate_templated_growth_3d_advanced(L, p, opts);
                    
                case 4 % Random Percolation
                    opts = struct('mode', 'random');
                    lattice = generate_templated_growth_3d_advanced(L, p, opts);
            end
            
            % Analyze clusters first
            [num_clusters, cluster_sizes] = analyze_3d_clusters(lattice);
            
            % Calculate statistics
            density = sum(lattice(:)) / L^3;
            cluster_stats(p_idx, variant, 1) = num_clusters;
            
            if ~isempty(cluster_sizes)
                cluster_stats(p_idx, variant, 2) = max(cluster_sizes);
                cluster_stats(p_idx, variant, 3) = mean(cluster_sizes);
            else
                cluster_stats(p_idx, variant, 2) = 0;
                cluster_stats(p_idx, variant, 3) = 0;
            end
            
            cluster_stats(p_idx, variant, 4) = density;
            
            % Save individual lattice variant immediately
            if save_results
                variant_name = variant_names{variant};
                filename = sprintf('Lattice_%s_p%.4f_L%d.mat', variant_name, p, L);
                filepath = fullfile(output_dir, filename);
                
                % Save with metadata
                lattice_data = struct();
                lattice_data.lattice = lattice;
                lattice_data.p_value = p;
                lattice_data.variant = variant_name;
                lattice_data.L = L;
                lattice_data.generation_time = datetime('now');
                lattice_data.cluster_stats = [num_clusters, max(cluster_sizes), mean(cluster_sizes), density];
                
                save(filepath, '-struct', 'lattice_data');
                fprintf('    Saved: %s\n', filename);
                
                % Clear lattice from memory to save space
                clear lattice_data;
            end
            
        catch ME
            fprintf('\nError generating variant %d for p=%.4f: %s\n', variant, p, ME.message);
            % Set error values
            cluster_stats(p_idx, variant, :) = [0, 0, 0, 0];
        end
    end
    
    % Update base template for templated variants (use 6N as base)
    % Note: We need to regenerate the 6N lattice from previous p-value for templating
    % since we're not storing all lattices in memory
    if p_idx > 1
        % Regenerate the 6N lattice from previous p-value for templating
        prev_p = p_values(p_idx - 1);
        opts = struct('mode', 'templated', 'connectivity', 6, 'template', base_template);
        base_template = logical(generate_templated_growth_3d_advanced(L, prev_p, opts));
    end
end

fprintf('\n\nLattice generation and analysis complete!\n\n');

% Create comprehensive analysis plots
if save_results
    fprintf('Creating analysis plots...\n');
    create_research_analysis_plots(cluster_stats, p_values, variant_names, L, output_dir);
    create_cluster_evolution_plots(cluster_stats, p_values, variant_names, L, output_dir);
    create_density_validation_plots(cluster_stats, p_values, variant_names, L, output_dir);
end

% Save numerical results
if save_results
    fprintf('Saving numerical results...\n');
    
    % Save cluster statistics
    results_file = fullfile(output_dir, sprintf('cluster_analysis_L%d_p%.2f_to_p%.2f.mat', L, p_values(1), p_values(end)));
    save(results_file, 'cluster_stats', 'p_values', 'variant_names', 'L', 'variant_descriptions');
    
    % Save CSV for external analysis
    csv_file = fullfile(output_dir, sprintf('cluster_analysis_L%d_p%.2f_to_p%.2f.csv', L, p_values(1), p_values(end)));
    save_cluster_stats_to_csv(cluster_stats, p_values, variant_names, csv_file);
    
    fprintf('Results saved to:\n');
    fprintf('  %s\n', results_file);
    fprintf('  %s\n', csv_file);
end

% Display summary statistics
display_summary_statistics(cluster_stats, p_values, variant_names);

fprintf('\n=== Research Analysis Complete ===\n');
if save_results
    fprintf('All results saved to: %s\n', output_dir);
end

end

function create_research_analysis_plots(cluster_stats, p_values, variant_names, L, output_dir)
% Create comprehensive analysis plots

fig = figure('Position', [100, 100, 1600, 1200], 'Name', sprintf('Research Analysis L=%d', L));

% Subplot 1: Number of clusters
subplot(2, 3, 1);
for variant = 1:4
    plot(p_values, squeeze(cluster_stats(:, variant, 1)), 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Number of Clusters');
title('Cluster Count Evolution');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 2: Largest cluster size
subplot(2, 3, 2);
for variant = 1:4
    plot(p_values, squeeze(cluster_stats(:, variant, 2)), 's-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Largest Cluster Size');
title('Largest Cluster Evolution');
legend('Location', 'best');
grid on;

% Subplot 3: Average cluster size
subplot(2, 3, 3);
for variant = 1:4
    plot(p_values, squeeze(cluster_stats(:, variant, 3)), '^-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Average Cluster Size');
title('Average Cluster Size Evolution');
legend('Location', 'best');
grid on;

% Subplot 4: Density validation
subplot(2, 3, 4);
for variant = 1:4
    plot(p_values, squeeze(cluster_stats(:, variant, 4)), 'd-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
plot(p_values, p_values, 'k--', 'LineWidth', 2, 'DisplayName', 'Target');
xlabel('Target Probability p');
ylabel('Achieved Density');
title('Density Validation');
legend('Location', 'best');
grid on;

% Subplot 5: Critical region focus (around p=0.3116)
subplot(2, 3, 5);
critical_mask = p_values >= 0.25 & p_values <= 0.4;
p_critical = p_values(critical_mask);
for variant = 1:4
    plot(p_critical, squeeze(cluster_stats(critical_mask, variant, 1)), 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Number of Clusters');
title('Critical Region Focus (p=0.25-0.4)');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 6: High percolation focus (around p=0.6884)
subplot(2, 3, 6);
high_mask = p_values >= 0.65 & p_values <= 0.75;
p_high = p_values(high_mask);
for variant = 1:4
    plot(p_high, squeeze(cluster_stats(high_mask, variant, 1)), 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Number of Clusters');
title('High Percolation Focus (p=0.65-0.75)');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

sgtitle(sprintf('Comprehensive Research Analysis - L = %d', L), 'FontSize', 16);

% Save figure
filename = fullfile(output_dir, sprintf('research_analysis_L%d.png', L));
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function create_cluster_evolution_plots(cluster_stats, p_values, variant_names, L, output_dir)
% Create detailed cluster evolution plots

fig = figure('Position', [200, 200, 1600, 800], 'Name', sprintf('Cluster Evolution L=%d', L));

% Create 2x2 subplot layout
for variant = 1:4
    subplot(2, 2, variant);
    
    % Plot all cluster statistics for this variant
    yyaxis left;
    plot(p_values, squeeze(cluster_stats(:, variant, 1)), 'b-o', 'LineWidth', 2, 'DisplayName', 'Number of Clusters');
    ylabel('Number of Clusters');
    set(gca, 'YScale', 'log');
    
    yyaxis right;
    plot(p_values, squeeze(cluster_stats(:, variant, 2)), 'r-s', 'LineWidth', 2, 'DisplayName', 'Largest Cluster');
    ylabel('Largest Cluster Size');
    
    xlabel('Occupation Probability p');
    title(sprintf('%s Evolution', variant_names{variant}));
    grid on;
    
    % Add legend
    legend('Location', 'best');
end

sgtitle(sprintf('Cluster Evolution Analysis - L = %d', L), 'FontSize', 14);

% Save figure
filename = fullfile(output_dir, sprintf('cluster_evolution_L%d.png', L));
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function create_density_validation_plots(cluster_stats, p_values, variant_names, L, output_dir)
% Create density validation plots

fig = figure('Position', [300, 300, 1400, 600], 'Name', sprintf('Density Validation L=%d', L));

% Subplot 1: Overall density validation
subplot(1, 2, 1);
for variant = 1:4
    plot(p_values, squeeze(cluster_stats(:, variant, 4)), 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
plot(p_values, p_values, 'k--', 'LineWidth', 3, 'DisplayName', 'Target');
xlabel('Target Probability p');
ylabel('Achieved Density');
title('Density Validation - All Variants');
legend('Location', 'best');
grid on;
axis equal;

% Subplot 2: Density error analysis
subplot(1, 2, 2);
for variant = 1:4
    density_error = abs(squeeze(cluster_stats(:, variant, 4)) - p_values);
    plot(p_values, density_error, 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xlabel('Target Probability p');
ylabel('Absolute Density Error');
title('Density Error Analysis');
legend('Location', 'best');
grid on;

sgtitle(sprintf('Density Validation Analysis - L = %d', L), 'FontSize', 14);

% Save figure
filename = fullfile(output_dir, sprintf('density_validation_L%d.png', L));
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function save_cluster_stats_to_csv(cluster_stats, p_values, variant_names, csv_file)
% Save cluster statistics to CSV format

% Create table structure
num_p = length(p_values);
num_variants = size(cluster_stats, 2);

% Prepare data for CSV
csv_data = [];
headers = {'p_value', 'variant', 'num_clusters', 'largest_cluster', 'avg_cluster_size', 'density'};

for p_idx = 1:num_p
    for variant = 1:num_variants
        row = [p_values(p_idx), variant, squeeze(cluster_stats(p_idx, variant, :))'];
        csv_data = [csv_data; row];
    end
end

% Create table and save
T = array2table(csv_data, 'VariableNames', headers);
writetable(T, csv_file);

end

function display_summary_statistics(cluster_stats, p_values, variant_names)
% Display summary statistics

fprintf('\n=== Summary Statistics ===\n');

% Find critical regions
critical_p = 0.3116;
high_p = 0.6884;

[~, critical_idx] = min(abs(p_values - critical_p));
[~, high_idx] = min(abs(p_values - high_p));

fprintf('Critical region (p ≈ %.4f):\n', critical_p);
for variant = 1:4
    num_clusters = cluster_stats(critical_idx, variant, 1);
    largest_cluster = cluster_stats(critical_idx, variant, 2);
    fprintf('  %s: %d clusters, largest %d\n', variant_names{variant}, num_clusters, largest_cluster);
end

fprintf('\nHigh percolation (p ≈ %.4f):\n', high_p);
for variant = 1:4
    num_clusters = cluster_stats(high_idx, variant, 1);
    largest_cluster = cluster_stats(high_idx, variant, 2);
    fprintf('  %s: %d clusters, largest %d\n', variant_names{variant}, num_clusters, largest_cluster);
end

% Density accuracy
fprintf('\nDensity accuracy summary:\n');
for variant = 1:4
    density_errors = abs(squeeze(cluster_stats(:, variant, 4)) - p_values);
    mean_error = mean(density_errors);
    max_error = max(density_errors);
    fprintf('  %s: mean error %.6f, max error %.6f\n', variant_names{variant}, mean_error, max_error);
end

end
