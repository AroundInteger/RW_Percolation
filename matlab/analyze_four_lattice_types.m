function analyze_four_lattice_types(p_values, L, output_dir)
% ANALYZE_FOUR_LATTICE_TYPES Comprehensive analysis of four lattice types
%
% This function performs detailed analysis of the four lattice variants
% as a function of percolation probability p, including:
% - Structural properties and connectivity
% - Cluster statistics and percolation behavior
% - Universality class indicators
% - Critical region analysis
% - Variant comparison and classification
%
% Inputs:
%   p_values - Array of percolation values
%   L - Lattice size
%   output_dir - Output directory (default: 'Clusters')

if nargin < 3, output_dir = 'Clusters'; end

fprintf('=== Four Lattice Types Analysis ===\n');
fprintf('Comprehensive Analysis of Lattice Variants vs Percolation\n\n');

% Define the four lattice variants
variants = {'6N_Templated', '26N_Templated', 'Density_Increment', 'Random_Percolation'};
variant_descriptions = {
    '6N_Templated: 6-connectivity templated growth with sequential p-dependence',
    '26N_Templated: 26-connectivity templated growth with sequential p-dependence',
    'Density_Increment: Density-based growth from empty template',
    'Random_Percolation: Standard random site percolation'
};

% Critical regions
p_c = 0.3116;           % Standard percolation threshold
p_c_prime = 0.6884;     % Critical gel-point

fprintf('Lattice Variants:\n');
for v = 1:length(variants)
    fprintf('  %d. %s\n', v, variant_descriptions{v});
end
fprintf('\n');

fprintf('Critical Regions:\n');
fprintf('  • p_c = 0.3116: Standard percolation threshold\n');
fprintf('  • p_c_prime = 0.6884: Critical gel-point (viscoelastic transition)\n');
fprintf('  • Fine resolution: 10 values in [0.61, 0.69] around gel-point\n\n');

% Initialize analysis arrays
num_p = length(p_values);
num_variants = length(variants);

% Structural properties
density_accuracy = zeros(num_p, num_variants);
connectivity_indicators = zeros(num_p, num_variants);
cluster_statistics = zeros(num_p, num_variants, 4);  % [num_clusters, largest_cluster, avg_cluster, density]

% Load and analyze each lattice
fprintf('Loading and analyzing %d lattice configurations...\n', num_p * num_variants);
fprintf('Progress: [');
progress_bar_length = 50;

for p_idx = 1:num_p
    p = p_values(p_idx);
    
    for variant_idx = 1:num_variants
        variant = variants{variant_idx};
        analysis_idx = (p_idx - 1) * num_variants + variant_idx;
        
        % Update progress bar
        progress = analysis_idx / (num_p * num_variants);
        filled_length = round(progress * progress_bar_length);
        fprintf(repmat('█', 1, filled_length));
        fprintf(repmat('░', 1, progress_bar_length - filled_length));
        fprintf('] %.1f%%\r', progress * 100);
        
        try
            % Load the lattice
            [lattice, metadata] = load_lattice_for_microrheology(variant, p, L, output_dir);
            
            % Calculate structural properties
            occupied_sites = logical(lattice);
            total_sites = numel(lattice);
            num_occupied = sum(occupied_sites(:));
            actual_density = num_occupied / total_sites;
            
            % Density accuracy (difference from target)
            density_accuracy(p_idx, variant_idx) = abs(actual_density - p);
            
            % Analyze clusters
            [num_clusters, cluster_sizes] = analyze_3d_clusters(lattice);
            
            % Store cluster statistics
            if ~isempty(cluster_sizes)
                largest_cluster = max(cluster_sizes);
                avg_cluster = mean(cluster_sizes);
            else
                largest_cluster = 0;
                avg_cluster = 0;
            end
            
            cluster_statistics(p_idx, variant_idx, :) = [num_clusters, largest_cluster, avg_cluster, actual_density];
            
            % Calculate connectivity indicator (fraction of sites in largest cluster)
            if largest_cluster > 0
                connectivity_indicators(p_idx, variant_idx) = largest_cluster / total_sites;
            else
                connectivity_indicators(p_idx, variant_idx) = 0;
            end
            
        catch ME
            fprintf('\nError analyzing %s at p=%.4f: %s\n', variant, p, ME.message);
            % Set error values
            density_accuracy(p_idx, variant_idx) = NaN;
            connectivity_indicators(p_idx, variant_idx) = NaN;
            cluster_statistics(p_idx, variant_idx, :) = [NaN, NaN, NaN, NaN];
        end
    end
end

fprintf('\n\nAnalysis complete!\n\n');

% Create comprehensive analysis plots
fprintf('Creating analysis plots...\n');
create_structural_analysis_plots(density_accuracy, connectivity_indicators, cluster_statistics, p_values, variants, L, output_dir);
create_critical_region_analysis(density_accuracy, connectivity_indicators, cluster_statistics, p_values, variants, L, p_c, p_c_prime, output_dir);
create_variant_comparison_analysis(density_accuracy, connectivity_indicators, cluster_statistics, p_values, variants, L, p_c, p_c_prime, output_dir);

% Save numerical results
fprintf('Saving numerical results...\n');
results_file = fullfile(output_dir, sprintf('four_lattice_types_analysis_L%d.mat', L));
save(results_file, 'density_accuracy', 'connectivity_indicators', 'cluster_statistics', ...
     'p_values', 'variants', 'L', 'p_c', 'p_c_prime');

% Save CSV for external analysis
csv_file = fullfile(output_dir, sprintf('four_lattice_types_analysis_L%d.csv', L));
save_analysis_results_to_csv(density_accuracy, connectivity_indicators, cluster_statistics, p_values, variants, L, csv_file);

fprintf('Results saved to:\n');
fprintf('  %s\n', results_file);
fprintf('  %s\n', csv_file);

% Display comprehensive summary
display_comprehensive_summary(density_accuracy, connectivity_indicators, cluster_statistics, p_values, variants, p_c, p_c_prime);

fprintf('\n=== Four Lattice Types Analysis Complete ===\n');
fprintf('Comprehensive analysis ready for universality class discovery!\n');

end

function create_structural_analysis_plots(density_accuracy, connectivity_indicators, cluster_statistics, p_values, variants, L, output_dir)
% Create structural analysis plots

fig = figure('Position', [100, 100, 1600, 1200], 'Name', sprintf('Structural Analysis L=%d', L));

% Subplot 1: Density accuracy comparison
subplot(2, 3, 1);
for v = 1:length(variants)
    valid_indices = ~isnan(density_accuracy(:, v));
    if any(valid_indices)
        plot(p_values(valid_indices), density_accuracy(valid_indices, v), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Target Percolation Probability p');
ylabel('Density Error |p_{actual} - p_{target}|');
title('Density Accuracy vs Target P');
legend('Location', 'best');
grid on;

% Subplot 2: Connectivity indicators
subplot(2, 3, 2);
for v = 1:length(variants)
    valid_indices = ~isnan(connectivity_indicators(:, v));
    if any(valid_indices)
        plot(p_values(valid_indices), connectivity_indicators(valid_indices, v), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Connectivity Indicator (Largest Cluster / Total Sites)');
title('Connectivity vs P');
legend('Location', 'best');
grid on;

% Subplot 3: Number of clusters
subplot(2, 3, 3);
for v = 1:length(variants)
    num_clusters = squeeze(cluster_statistics(:, v, 1));
    valid_indices = ~isnan(num_clusters);
    if any(valid_indices)
        plot(p_values(valid_indices), num_clusters(valid_indices), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Number of Clusters');
title('Cluster Count vs P');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 4: Largest cluster size
subplot(2, 3, 4);
for v = 1:length(variants)
    largest_cluster = squeeze(cluster_statistics(:, v, 2));
    valid_indices = ~isnan(largest_cluster);
    if any(valid_indices)
        plot(p_values(valid_indices), largest_cluster(valid_indices), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Largest Cluster Size');
title('Largest Cluster vs P');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 5: Average cluster size
subplot(2, 3, 5);
for v = 1:length(variants)
    avg_cluster = squeeze(cluster_statistics(:, v, 3));
    valid_indices = ~isnan(avg_cluster);
    if any(valid_indices)
        plot(p_values(valid_indices), avg_cluster(valid_indices), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Average Cluster Size');
title('Average Cluster Size vs P');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 6: Actual vs target density
subplot(2, 3, 6);
for v = 1:length(variants)
    actual_density = squeeze(cluster_statistics(:, v, 4));
    valid_indices = ~isnan(actual_density);
    if any(valid_indices)
        plot(p_values(valid_indices), actual_density(valid_indices), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
% Add perfect line
plot([0, 1], [0, 1], '--k', 'LineWidth', 1, 'DisplayName', 'Perfect');
xlabel('Target Percolation Probability p');
ylabel('Actual Density');
title('Actual vs Target Density');
legend('Location', 'best');
grid on;

sgtitle(sprintf('Structural Analysis - Four Lattice Types, L=%d', L), 'FontSize', 16);

% Save figure
filename = fullfile(output_dir, sprintf('structural_analysis_L%d.png', L));
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function create_critical_region_analysis(density_accuracy, connectivity_indicators, cluster_statistics, p_values, variants, L, p_c, p_c_prime, output_dir)
% Create critical region analysis plots

fig = figure('Position', [200, 200, 1400, 800], 'Name', sprintf('Critical Region Analysis L=%d', L));

% Subplot 1: Standard percolation threshold region (p_c)
subplot(2, 2, 1);
p_c_mask = abs(p_values - p_c) < 0.05;
p_c_values = p_values(p_c_mask);

for v = 1:length(variants)
    connectivity_at_pc = connectivity_indicators(p_c_mask, v);
    valid_indices = ~isnan(connectivity_at_pc);
    if any(valid_indices)
        plot(p_c_values(valid_indices), connectivity_at_pc(valid_indices), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Connectivity Indicator');
title(sprintf('Critical Region: p_c = %.4f ± 0.05', p_c));
legend('Location', 'best');
grid on;

% Subplot 2: Critical gel-point region (p_c_prime)
subplot(2, 2, 2);
p_c_prime_mask = abs(p_values - p_c_prime) < 0.05;
p_c_prime_values = p_values(p_c_prime_mask);

for v = 1:length(variants)
    connectivity_at_pcp = connectivity_indicators(p_c_prime_mask, v);
    valid_indices = ~isnan(connectivity_at_pcp);
    if any(valid_indices)
        plot(p_c_prime_values(valid_indices), connectivity_at_pcp(valid_indices), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Connectivity Indicator');
title(sprintf('Critical Region: p_c'' = %.4f ± 0.05', p_c_prime));
legend('Location', 'best');
grid on;

% Subplot 3: Fine resolution around gel-point
subplot(2, 2, 3);
fine_resolution_mask = p_values >= 0.61 & p_values <= 0.69;
p_fine = p_values(fine_resolution_mask);

for v = 1:length(variants)
    connectivity_fine = connectivity_indicators(fine_resolution_mask, v);
    valid_indices = ~isnan(connectivity_fine);
    if any(valid_indices)
        plot(p_fine(valid_indices), connectivity_fine(valid_indices), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);
xlabel('Percolation Probability p');
ylabel('Connectivity Indicator');
title('Fine Resolution: p ∈ [0.61, 0.69]');
legend('Location', 'best');
grid on;

% Subplot 4: Variant comparison at critical points
subplot(2, 2, 4);
[~, p_c_idx] = min(abs(p_values - p_c));
[~, p_c_prime_idx] = min(abs(p_values - p_c_prime));

critical_points = [p_c, p_c_prime];
critical_labels = {'p_c = 0.3116', 'p_c'' = 0.6884'};

for p_idx = [p_c_idx, p_c_prime_idx]
    connectivity_at_critical = connectivity_indicators(p_idx, :);
    valid_indices = ~isnan(connectivity_at_critical);
    if any(valid_indices)
        bar(1:length(variants), connectivity_at_critical, 'DisplayName', sprintf('p=%.4f', p_values(p_idx)));
        hold on;
    end
end

set(gca, 'XTickLabel', variants);
xlabel('Lattice Variant');
ylabel('Connectivity Indicator');
title('Connectivity at Critical Points');
legend('Location', 'best');
grid on;

sgtitle(sprintf('Critical Region Analysis - Four Lattice Types, L=%d', L), 'FontSize', 14);

% Save figure
filename = fullfile(output_dir, sprintf('critical_region_analysis_L%d.png', L));
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function create_variant_comparison_analysis(density_accuracy, connectivity_indicators, cluster_statistics, p_values, variants, L, p_c, p_c_prime, output_dir)
% Create variant comparison analysis plots

fig = figure('Position', [300, 300, 1400, 800], 'Name', sprintf('Variant Comparison Analysis L=%d', L));

% Subplot 1: Variant classification matrix
subplot(2, 2, 1);
% Create a classification matrix based on connectivity behavior
classification_matrix = zeros(length(variants), length(variants));

for v1 = 1:length(variants)
    for v2 = 1:length(variants)
        if v1 ~= v2
            % Calculate similarity based on connectivity patterns
            conn1 = connectivity_indicators(:, v1);
            conn2 = connectivity_indicators(:, v2);
            valid_indices = ~isnan(conn1) & ~isnan(conn2);
            
            if sum(valid_indices) > 5
                correlation = corr(conn1(valid_indices), conn2(valid_indices));
                classification_matrix(v1, v2) = correlation;
            else
                classification_matrix(v1, v2) = NaN;
            end
        end
    end
end

imagesc(classification_matrix);
colorbar;
set(gca, 'XTick', 1:length(variants), 'XTickLabel', variants);
set(gca, 'YTick', 1:length(variants), 'YTickLabel', variants);
xlabel('Lattice Variant');
ylabel('Lattice Variant');
title('Variant Similarity Matrix (Correlation)');
colormap('jet');

% Subplot 2: Universality class indicators
subplot(2, 2, 2);
% Calculate universality class indicators based on critical behavior
universality_indicators = zeros(length(variants), 1);

for v = 1:length(variants)
    % Focus on behavior around critical points
    p_c_mask = abs(p_values - p_c) < 0.05;
    p_c_prime_mask = abs(p_values - p_c_prime) < 0.05;
    
    conn_pc = connectivity_indicators(p_c_mask, v);
    conn_pcp = connectivity_indicators(p_c_prime_mask, v);
    
    valid_pc = ~isnan(conn_pc);
    valid_pcp = ~isnan(conn_pcp);
    
    if any(valid_pc) && any(valid_pcp)
        % Universality indicator: how different is behavior at p_c vs p_c_prime
        behavior_diff = abs(mean(conn_pc(valid_pc)) - mean(conn_pcp(valid_pcp)));
        universality_indicators(v) = behavior_diff;
    else
        universality_indicators(v) = NaN;
    end
end

bar(universality_indicators);
set(gca, 'XTickLabel', variants);
xlabel('Lattice Variant');
ylabel('Universality Class Indicator');
title('Universality Class Indicators');
grid on;

% Subplot 3: Critical region behavior comparison
subplot(2, 2, 3);
critical_behavior = zeros(length(variants), 2);  % [p_c behavior, p_c_prime behavior]

for v = 1:length(variants)
    [~, p_c_idx] = min(abs(p_values - p_c));
    [~, p_c_prime_idx] = min(abs(p_values - p_c_prime));
    
    critical_behavior(v, 1) = connectivity_indicators(p_c_idx, v);
    critical_behavior(v, 2) = connectivity_indicators(p_c_prime_idx, v);
end

bar(critical_behavior);
set(gca, 'XTickLabel', variants);
xlabel('Lattice Variant');
ylabel('Connectivity Indicator');
title('Critical Region Behavior Comparison');
legend('p_c = 0.3116', 'p_c'' = 0.6884', 'Location', 'best');
grid on;

% Subplot 4: Variant ranking by different metrics
subplot(2, 2, 4);
% Rank variants by different metrics
metrics = {'Density Accuracy', 'Connectivity Stability', 'Critical Behavior'};
variant_rankings = zeros(length(variants), length(metrics));

for v = 1:length(variants)
    % Density accuracy (lower is better)
    density_err = density_accuracy(:, v);
    valid_density = ~isnan(density_err);
    if any(valid_density)
        variant_rankings(v, 1) = mean(density_err(valid_density));
    end
    
    % Connectivity stability (lower variance is better)
    conn = connectivity_indicators(:, v);
    valid_conn = ~isnan(conn);
    if sum(valid_conn) > 1
        variant_rankings(v, 2) = std(conn(valid_conn));
    end
    
    % Critical behavior (higher difference indicates stronger universality)
    variant_rankings(v, 3) = universality_indicators(v);
end

% Normalize rankings (0-1 scale, higher is better)
for m = 1:length(metrics)
    if m == 3  % Critical behavior: higher is better
        variant_rankings(:, m) = variant_rankings(:, m) / max(variant_rankings(:, m));
    else  % Density accuracy and connectivity stability: lower is better
        variant_rankings(:, m) = 1 - (variant_rankings(:, m) / max(variant_rankings(:, m)));
    end
end

bar(variant_rankings);
set(gca, 'XTickLabel', variants);
xlabel('Lattice Variant');
ylabel('Normalized Score');
title('Variant Ranking by Different Metrics');
legend(metrics, 'Location', 'best');
grid on;

sgtitle(sprintf('Variant Comparison Analysis - Four Lattice Types, L=%d', L), 'FontSize', 14);

% Save figure
filename = fullfile(output_dir, sprintf('variant_comparison_analysis_L%d.png', L));
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function save_analysis_results_to_csv(density_accuracy, connectivity_indicators, cluster_statistics, p_values, variants, L, csv_file)
% Save analysis results to CSV format

% Create table structure
num_p = length(p_values);
num_variants = length(variants);

% Prepare data for CSV
csv_data = [];
headers = {'p_value', 'variant', 'density_accuracy', 'connectivity_indicator', ...
           'num_clusters', 'largest_cluster', 'avg_cluster', 'actual_density'};

for p_idx = 1:num_p
    for v = 1:num_variants
        p = p_values(p_idx);
        variant = v;  % Use index for CSV
        
        density_err = density_accuracy(p_idx, v);
        conn_ind = connectivity_indicators(p_idx, v);
        num_clust = cluster_statistics(p_idx, v, 1);
        largest_clust = cluster_statistics(p_idx, v, 2);
        avg_clust = cluster_statistics(p_idx, v, 3);
        actual_dens = cluster_statistics(p_idx, v, 4);
        
        if ~isnan(density_err)
            row = [p, variant, density_err, conn_ind, num_clust, largest_clust, avg_clust, actual_dens];
            csv_data = [csv_data; row];
        end
    end
end

% Create table and save
T = array2table(csv_data, 'VariableNames', headers);
writetable(T, csv_file);

end

function display_comprehensive_summary(density_accuracy, connectivity_indicators, cluster_statistics, p_values, variants, p_c, p_c_prime)
% Display comprehensive summary of four lattice types analysis

fprintf('\n=== Comprehensive Analysis Summary ===\n');

% Overall statistics
fprintf('Overall Statistics:\n');
for v = 1:length(variants)
    fprintf('  %s:\n', variants{v});
    
    % Density accuracy
    density_err = density_accuracy(:, v);
    valid_density = ~isnan(density_err);
    if any(valid_density)
        fprintf('    Density accuracy: mean error %.4f ± %.4f\n', mean(density_err(valid_density)), std(density_err(valid_density)));
    end
    
    % Connectivity
    conn = connectivity_indicators(:, v);
    valid_conn = ~isnan(conn);
    if any(valid_conn)
        fprintf('    Connectivity range: [%.6f, %.6f]\n', min(conn(valid_conn)), max(conn(valid_conn)));
    end
    
    % Clusters
    num_clust = squeeze(cluster_statistics(:, v, 1));
    valid_clust = ~isnan(num_clust);
    if any(valid_clust)
        fprintf('    Cluster count: mean %.0f ± %.0f\n', mean(num_clust(valid_clust)), std(num_clust(valid_clust)));
    end
end

% Critical region analysis
fprintf('\nCritical Region Analysis:\n');
[~, p_c_idx] = min(abs(p_values - p_c));
[~, p_c_prime_idx] = min(abs(p_values - p_c_prime));

fprintf('  Standard percolation (p_c = %.4f):\n', p_c);
for v = 1:length(variants)
    if ~isnan(connectivity_indicators(p_c_idx, v))
        fprintf('    %s: connectivity = %.6f\n', variants{v}, connectivity_indicators(p_c_idx, v));
    end
end

fprintf('  Critical gel-point (p_c'' = %.4f):\n', p_c_prime);
for v = 1:length(variants)
    if ~isnan(connectivity_indicators(p_c_prime_idx, v))
        fprintf('    %s: connectivity = %.6f\n', variants{v}, connectivity_indicators(p_c_prime_idx, v));
    end
end

% Variant classification
fprintf('\nVariant Classification:\n');
fprintf('  1. 6N_Templated: Sequential templated growth with 6-connectivity\n');
fprintf('     - Shows strong p-dependence due to templating\n');
fprintf('     - Expected to show distinct universality class\n\n');

fprintf('  2. 26N_Templated: Sequential templated growth with 26-connectivity\n');
fprintf('     - Higher connectivity than 6N, but similar templating\n');
fprintf('     - May show intermediate universality behavior\n\n');

fprintf('  3. Density_Increment: Density-based growth from empty template\n');
fprintf('     - No sequential p-dependence\n');
fprintf('     - Expected to show standard percolation behavior\n\n');

fprintf('  4. Random_Percolation: Standard random site percolation\n');
fprintf('     - Reference case for universality class comparison\n');
fprintf('     - Expected to show standard percolation behavior\n\n');

% Universality class indicators
fprintf('Universality Class Indicators:\n');
for v = 1:length(variants)
    % Calculate behavior difference between critical points
    conn_pc = connectivity_indicators(p_c_idx, v);
    conn_pcp = connectivity_indicators(p_c_prime_idx, v);
    
    if ~isnan(conn_pc) && ~isnan(conn_pcp)
        behavior_diff = abs(conn_pc - conn_pcp);
        fprintf('  %s: critical behavior difference = %.6f\n', variants{v}, behavior_diff);
        
        if behavior_diff > 0.1
            fprintf('    → Strong universality class indicator\n');
        elseif behavior_diff > 0.05
            fprintf('    → Moderate universality class indicator\n');
        else
            fprintf('    → Weak universality class indicator\n');
        end
    end
end

fprintf('\nNext Steps for Universality Class Discovery:\n');
fprintf('1. Run random walk analysis to extract α exponents\n');
fprintf('2. Calculate phase angles δ = πα/2 for viscoelastic properties\n');
fprintf('3. Identify τ_l and τ_cr time scales from MSD curves\n');
fprintf('4. Compare universality classes across variants\n');
fprintf('5. Focus on critical regions: p_c = 0.3116 and p_c_prime = 0.6884\n');

end
