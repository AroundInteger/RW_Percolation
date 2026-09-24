function viscoelastic_lattice_analysis(L, p_values, save_results, output_dir)
% VISCOELASTIC_LATTICE_ANALYSIS Specialized analysis for G', G'', tan(delta), tau_l, tau_cr research
%
% This function generates lattices specifically optimized for viscoelastic analysis
% and universality class research, with focus on critical regions around
% p_c = 0.3116 and p_c_prime = 0.6884.
%
% Inputs:
%   L - Lattice size (creates LxLxL lattices)
%   p_values - Array of occupation probabilities to test
%   save_results - Boolean to save results (default: true)
%   output_dir - Output directory (default: 'Clusters')

if nargin < 1, L = 500; end
if nargin < 2, p_values = [0, 0.05:0.05:0.3, 0.3116, 0.35:0.01:0.69, 0.6884, 0.69:0.01:0.85, 0.85, 0.86:0.01:0.88, 0.9, 0.95]; end
if nargin < 3, save_results = true; end
if nargin < 4, output_dir = 'Clusters'; end

fprintf('=== Viscoelastic Lattice Analysis ===\n');
fprintf('G'', G'''', tan(delta), tau_l, tau_cr Analysis for Universality Class Research\n\n');
fprintf('Lattice size: %dx%dx%d\n', L, L, L);
fprintf('Testing %d probability values\n', length(p_values));
fprintf('Generating 4 key lattice variants\n\n');

% Check parallel processing capabilities
try
    pool = gcp('nocreate');
    if isempty(pool)
        fprintf('Starting parallel pool for variant generation...\n');
        parpool('local');
        pool = gcp;
    end
    fprintf('Parallel processing: %d workers available\n', pool.NumWorkers);
    fprintf('Expected speedup: ~%dx for variant generation\n\n', min(4, pool.NumWorkers));
catch ME
    fprintf('Warning: Parallel processing not available. Using sequential processing.\n');
    fprintf('Error: %s\n\n', ME.message);
end

% Create output directory
if save_results
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    fprintf('Results will be saved to: %s\n\n', output_dir);
end

% Lattice variant names optimized for viscoelastic analysis
variant_names = {
    '6N_Templated',
    '26N_Templated', 
    'Density_Increment',
    'Random_Percolation'
};

variant_descriptions = {
    '6-neighbor templated growth (most connected)',
    '26-neighbor templated growth (more fragmented)',  
    'Random addition without adjacency constraints',
    'Independent Bernoulli percolation (baseline)'
};

% Critical region identification
p_c = 0.3116;           % Standard percolation threshold
p_c_prime = 0.6884;     % Critical gel-point (viscoelastic transition)

% Find indices for critical regions
[~, p_c_idx] = min(abs(p_values - p_c));
[~, p_c_prime_idx] = min(abs(p_values - p_c_prime));

fprintf('Critical Regions Identified:\n');
fprintf('  p_c = %.4f at index %d (p = %.4f)\n', p_c, p_c_idx, p_values(p_c_idx));
fprintf('  p_c_prime = %.4f at index %d (p = %.4f)\n', p_c_prime, p_c_prime_idx, p_values(p_c_prime_idx));

% Identify fine resolution regions
fine_resolution_mask = p_values >= 0.61 & p_values <= 0.69;
fine_resolution_p = p_values(fine_resolution_mask);
fprintf('  Fine resolution around gel-point: %d values in [%.2f, %.2f]\n', ...
    sum(fine_resolution_mask), min(fine_resolution_p), max(fine_resolution_p));

fprintf('\n');

% Initialize results storage
num_variants = 4;
num_p_values = length(p_values);

% Cluster statistics: [p_values, variants, stats: num_clusters, largest_cluster, avg_cluster_size, density]
cluster_stats = zeros(num_p_values, num_variants, 4);

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
    
    % Generate all 4 variants in parallel
    % Note: We use parfor for variants since they're independent for each p-value
    % The base_template is shared across all variants for this p-value
    
    % Pre-allocate temporary storage for parallel processing
    temp_lattices = cell(1, num_variants);
    temp_cluster_stats = zeros(num_variants, 4);
    temp_filenames = cell(1, num_variants);
    temp_errors = false(1, num_variants);
    
    parfor variant = 1:num_variants
        try
            % Local variables for this iteration
            local_lattice = [];
            local_num_clusters = 0;
            local_largest_cluster = 0;
            local_avg_cluster_size = 0;
            local_density = 0;
            local_filename = '';
            
            switch variant
                case 1 % 6N Templated
                    opts = struct('mode', 'templated', 'connectivity', 6, 'template', base_template);
                    local_lattice = generate_templated_growth_3d_advanced(L, p, opts);
                    
                case 2 % 26N Templated
                    opts = struct('mode', 'templated', 'connectivity', 26, 'template', base_template);
                    local_lattice = generate_templated_growth_3d_advanced(L, p, opts);
                    
                case 3 % Density Increment
                    opts = struct('mode', 'density_increment', 'template', false(L, L, L));
                    local_lattice = generate_templated_growth_3d_advanced(L, p, opts);
                    
                case 4 % Random Percolation
                    opts = struct('mode', 'random');
                    local_lattice = generate_templated_growth_3d_advanced(L, p, opts);
            end
            
            % Analyze clusters
            [local_num_clusters, cluster_sizes] = analyze_3d_clusters(local_lattice);
            
            % Calculate statistics
            local_density = sum(local_lattice(:)) / L^3;
            
            if ~isempty(cluster_sizes)
                local_largest_cluster = max(cluster_sizes);
                local_avg_cluster_size = mean(cluster_sizes);
            else
                local_largest_cluster = 0;
                local_avg_cluster_size = 0;
            end
            
            % Prepare filename
            variant_name = variant_names{variant};
            local_filename = sprintf('Lattice_%s_p%.4f_L%d.mat', variant_name, p, L);
            
            % Store results in output arrays
            temp_lattices{variant} = local_lattice;
            temp_cluster_stats(variant, :) = [local_num_clusters, local_largest_cluster, local_avg_cluster_size, local_density];
            temp_filenames{variant} = local_filename;
            temp_errors(variant) = false;
            
        catch ME
            fprintf('\nError generating variant %d for p=%.4f: %s\n', variant, p, ME.message);
            temp_errors(variant) = true;
            temp_cluster_stats(variant, :) = [0, 0, 0, 0];
        end
    end
    
    % Transfer results from parallel processing to main arrays
    for variant = 1:num_variants
        if ~temp_errors(variant)
            % Store cluster statistics
            cluster_stats(p_idx, variant, :) = temp_cluster_stats(variant, :);
            
            % Save individual lattice variant immediately
            if save_results
                variant_name = variant_names{variant};
                filename = temp_filenames{variant};
                filepath = fullfile(output_dir, filename);
                
                % Save with enhanced metadata for viscoelastic analysis
                lattice_data = struct();
                lattice_data.lattice = temp_lattices{variant};
                lattice_data.p_value = p;
                lattice_data.variant = variant_name;
                lattice_data.L = L;
                lattice_data.generation_time = datetime('now');
                lattice_data.cluster_stats = temp_cluster_stats(variant, :);
                
                % Add viscoelastic analysis metadata
                lattice_data.is_critical_region = abs(p - p_c) < 0.01;
                lattice_data.is_gel_point_region = abs(p - p_c_prime) < 0.01;
                lattice_data.expected_behavior = get_expected_behavior(p, p_c, p_c_prime);
                lattice_data.analysis_notes = get_analysis_notes(p, p_c, p_c_prime);
                
                save(filepath, '-struct', 'lattice_data');
                fprintf('    Saved: %s\n', filename);
            end
        else
            % Set error values
            cluster_stats(p_idx, variant, :) = [0, 0, 0, 0];
        end
    end
    
    % Clear temporary storage
    clear temp_lattices temp_cluster_stats temp_filenames temp_errors;
    
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

% Create specialized viscoelastic analysis plots
if save_results
    fprintf('Creating viscoelastic analysis plots...\n');
    create_viscoelastic_analysis_plots(cluster_stats, p_values, variant_names, L, output_dir, p_c, p_c_prime);
    create_critical_region_analysis(cluster_stats, p_values, variant_names, L, output_dir, p_c, p_c_prime);
    create_gel_point_transition_analysis(cluster_stats, p_values, variant_names, L, output_dir, p_c, p_c_prime);
end

% Save numerical results
if save_results
    fprintf('Saving numerical results...\n');
    
    % Save cluster statistics
    results_file = fullfile(output_dir, sprintf('viscoelastic_analysis_L%d_p%.2f_to_p%.2f.mat', L, p_values(1), p_values(end)));
    save(results_file, 'cluster_stats', 'p_values', 'variant_names', 'L', 'variant_descriptions', 'p_c', 'p_c_prime');
    
    % Save CSV for external analysis
    csv_file = fullfile(output_dir, sprintf('viscoelastic_analysis_L%d_p%.2f_to_p%.2f.csv', L, p_values(1), p_values(end)));
    save_viscoelastic_stats_to_csv(cluster_stats, p_values, variant_names, csv_file);
    
    fprintf('Results saved to:\n');
    fprintf('  %s\n', results_file);
    fprintf('  %s\n', csv_file);
end

% Display specialized summary statistics
display_viscoelastic_summary(cluster_stats, p_values, variant_names, p_c, p_c_prime);

fprintf('\n=== Viscoelastic Analysis Complete ===\n');
if save_results
    fprintf('All results saved to: %s\n', output_dir);
end
fprintf('Lattices ready for G'', G'''', tan(delta), tau_l, and tau_cr analysis!\n');

end

function behavior = get_expected_behavior(p, p_c, p_c_prime)
% Get expected behavior based on percolation theory
if p < p_c - 0.05
    behavior = 'Liquid-like (normal diffusion)';
elseif abs(p - p_c) < 0.05
    behavior = 'Critical percolation (anomalous diffusion)';
elseif p < p_c_prime - 0.05
    behavior = 'Viscoelastic (anomalous diffusion)';
elseif abs(p - p_c_prime) < 0.05
    behavior = 'Critical gel-point (viscoelastic transition)';
else
    behavior = 'Solid-like (arrested diffusion)';
end
end

function notes = get_analysis_notes(p, p_c, p_c_prime)
% Get analysis notes for specific p-values
if abs(p - p_c) < 0.01
    notes = 'Focus on tau_l analysis and anomalous diffusion region';
elseif abs(p - p_c_prime) < 0.01
    notes = 'Critical gel-point: analyze tau_cr and viscoelastic transition';
elseif p >= 0.61 && p <= 0.69
    notes = 'Gel-point region: high resolution analysis for tau_l and tau_cr';
elseif p < p_c
    notes = 'Liquid regime: expect normal diffusion α ≈ 1.0';
elseif p > p_c_prime
    notes = 'Solid regime: expect arrested diffusion α ≈ 0.0';
else
    notes = 'Viscoelastic regime: expect anomalous diffusion 0 < α < 1';
end
end

function create_viscoelastic_analysis_plots(cluster_stats, p_values, variant_names, L, output_dir, p_c, p_c_prime)
% Create specialized plots for viscoelastic analysis

fig = figure('Position', [100, 100, 1600, 1200], 'Name', sprintf('Viscoelastic Analysis L=%d', L));

% Subplot 1: Cluster count evolution with critical regions marked
subplot(2, 3, 1);
for variant = 1:4
    plot(p_values, squeeze(cluster_stats(:, variant, 1)), 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
% Mark critical regions
xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);
xlabel('Occupation Probability p');
ylabel('Number of Clusters');
title('Cluster Count Evolution');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 2: Largest cluster evolution
subplot(2, 3, 2);
for variant = 1:4
    plot(p_values, squeeze(cluster_stats(:, variant, 2)), 's-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);
xlabel('Occupation Probability p');
ylabel('Largest Cluster Size');
title('Largest Cluster Evolution');
legend('Location', 'best');
grid on;

% Subplot 3: Percolation ratio (largest cluster / total occupied)
subplot(2, 3, 3);
for variant = 1:4
    percolation_ratio = squeeze(cluster_stats(:, variant, 2)) ./ (squeeze(cluster_stats(:, variant, 4)) * L^3);
    plot(p_values, percolation_ratio, '^-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);
xlabel('Occupation Probability p');
ylabel('Percolation Ratio');
title('Percolation Ratio Evolution');
legend('Location', 'best');
grid on;

% Subplot 4: Density validation
subplot(2, 3, 4);
for variant = 1:4
    plot(p_values, squeeze(cluster_stats(:, variant, 4)), 'd-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
plot(p_values, p_values, 'k--', 'LineWidth', 2, 'DisplayName', 'Target');
xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);
xlabel('Target Probability p');
ylabel('Achieved Density');
title('Density Validation');
legend('Location', 'best');
grid on;

% Subplot 5: Critical region focus (around p_c)
subplot(2, 3, 5);
critical_mask = p_values >= 0.25 & p_values <= 0.4;
p_critical = p_values(critical_mask);
for variant = 1:4
    plot(p_critical, squeeze(cluster_stats(critical_mask, variant, 1)), 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xlabel('Occupation Probability p');
ylabel('Number of Clusters');
title('Critical Region Focus (p_c = 0.3116)');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 6: Gel-point region focus (around p_c_prime)
subplot(2, 3, 6);
gel_mask = p_values >= 0.61 & p_values <= 0.75;
p_gel = p_values(gel_mask);
for variant = 1:4
    plot(p_gel, squeeze(cluster_stats(gel_mask, variant, 1)), 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);
xlabel('Occupation Probability p');
ylabel('Number of Clusters');
title('Gel-Point Region Focus (p_c'' = 0.6884)');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

sgtitle(sprintf('Viscoelastic Analysis - L = %d (p_c = %.4f, p_c'' = %.4f)', L, p_c, p_c_prime), 'FontSize', 16);

% Save figure
filename = fullfile(output_dir, sprintf('viscoelastic_analysis_L%d.png', L));
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function create_critical_region_analysis(cluster_stats, p_values, variant_names, L, output_dir, p_c, p_c_prime)
% Create detailed analysis of critical regions

fig = figure('Position', [200, 200, 1400, 800], 'Name', sprintf('Critical Region Analysis L=%d', L));

% Subplot 1: Standard percolation threshold region
subplot(2, 2, 1);
critical_mask = p_values >= 0.25 & p_values <= 0.4;
p_critical = p_values(critical_mask);

for variant = 1:4
    percolation_ratio = squeeze(cluster_stats(critical_mask, variant, 2)) ./ (squeeze(cluster_stats(critical_mask, variant, 4)) * L^3);
    plot(p_critical, percolation_ratio, 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xlabel('Occupation Probability p');
ylabel('Percolation Ratio');
title('Standard Percolation Threshold (p_c = 0.3116)');
legend('Location', 'best');
grid on;

% Subplot 2: Critical gel-point region
subplot(2, 2, 2);
gel_mask = p_values >= 0.61 & p_values <= 0.75;
p_gel = p_values(gel_mask);

for variant = 1:4
    percolation_ratio = squeeze(cluster_stats(gel_mask, variant, 2)) ./ (squeeze(cluster_stats(gel_mask, variant, 4)) * L^3);
    plot(p_gel, percolation_ratio, 's-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);
xlabel('Occupation Probability p');
ylabel('Percolation Ratio');
title('Critical Gel-Point (p_c'' = 0.6884)');
legend('Location', 'best');
grid on;

% Subplot 3: Cluster size distribution comparison
subplot(2, 2, 3);
p_near_c = p_values(abs(p_values - p_c) < 0.01);
p_near_c_prime = p_values(abs(p_values - p_c_prime) < 0.01);

if ~isempty(p_near_c) && ~isempty(p_near_c_prime)
    [~, idx_c] = min(abs(p_values - p_near_c(1)));
    [~, idx_c_prime] = min(abs(p_values - p_near_c_prime(1)));
    
    for variant = 1:4
        plot([1, 2], [cluster_stats(idx_c, variant, 1), cluster_stats(idx_c_prime, variant, 1)], 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
        hold on;
    end
    
    set(gca, 'XTick', [1, 2], 'XTickLabel', {sprintf('p_c\n(%.4f)', p_c), sprintf('p_c''\n(%.4f)', p_c_prime)});
    ylabel('Number of Clusters');
    title('Cluster Count Comparison: p_c vs p_c''');
    legend('Location', 'best');
    grid on;
end

% Subplot 4: Universality class indicators
subplot(2, 2, 4);
for variant = 1:4
    % Calculate connectivity indicator (inverse of cluster count, normalized)
    connectivity_indicator = 1 ./ (squeeze(cluster_stats(:, variant, 1)) + 1); % +1 to avoid division by zero
    plot(p_values, connectivity_indicator, '^-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);
xlabel('Occupation Probability p');
ylabel('Connectivity Indicator (1/N_clusters)');
title('Universality Class Indicators');
legend('Location', 'best');
grid on;

sgtitle(sprintf('Critical Region Analysis - L = %d', L), 'FontSize', 14);

% Save figure
filename = fullfile(output_dir, sprintf('critical_region_analysis_L%d.png', L));
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function create_gel_point_transition_analysis(cluster_stats, p_values, variant_names, L, output_dir, p_c, p_c_prime)
% Create detailed analysis of gel-point transition

fig = figure('Position', [300, 300, 1400, 600], 'Name', sprintf('Gel-Point Transition Analysis L=%d', L));

% Subplot 1: Fine resolution around gel-point
subplot(1, 2, 1);
fine_mask = p_values >= 0.61 & p_values <= 0.75;
p_fine = p_values(fine_mask);

for variant = 1:4
    plot(p_fine, squeeze(cluster_stats(fine_mask, variant, 1)), 'o-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 3);
xlabel('Occupation Probability p');
ylabel('Number of Clusters');
title('Gel-Point Transition: Fine Resolution');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 2: Phase transition indicators
subplot(1, 2, 2);
for variant = 1:4
    % Calculate phase transition indicator (change in cluster count)
    cluster_counts = squeeze(cluster_stats(:, variant, 1));
    phase_indicator = abs(diff(cluster_counts)) ./ (cluster_counts(1:end-1) + 1); % +1 to avoid division by zero
    plot(p_values(1:end-1), phase_indicator, 's-', 'LineWidth', 2, 'DisplayName', variant_names{variant});
    hold on;
end
xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);
xlabel('Occupation Probability p');
ylabel('Phase Transition Indicator |dN|/N');
title('Phase Transition Indicators');
legend('Location', 'best');
grid on;

sgtitle(sprintf('Gel-Point Transition Analysis - L = %d (p_c'' = %.4f)', L, p_c_prime), 'FontSize', 14);

% Save figure
filename = fullfile(output_dir, sprintf('gel_point_transition_L%d.png', L));
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function save_viscoelastic_stats_to_csv(cluster_stats, p_values, variant_names, csv_file)
% Save viscoelastic statistics to CSV format

% Create table structure
num_p = length(p_values);
num_variants = size(cluster_stats, 2);

% Prepare data for CSV
csv_data = [];
headers = {'p_value', 'variant', 'num_clusters', 'largest_cluster', 'avg_cluster_size', 'density', 'percolation_ratio'};

for p_idx = 1:num_p
    for variant = 1:num_variants
        p = p_values(p_idx);
        num_clusters = cluster_stats(p_idx, variant, 1);
        largest_cluster = cluster_stats(p_idx, variant, 2);
        avg_cluster_size = cluster_stats(p_idx, variant, 3);
        density = cluster_stats(p_idx, variant, 4);
        
        % Calculate percolation ratio
        if density > 0
            percolation_ratio = largest_cluster / (density * 500^3);
        else
            percolation_ratio = 0;
        end
        
        row = [p, variant, num_clusters, largest_cluster, avg_cluster_size, density, percolation_ratio];
        csv_data = [csv_data; row];
    end
end

% Create table and save
T = array2table(csv_data, 'VariableNames', headers);
writetable(T, csv_file);

end

function display_viscoelastic_summary(cluster_stats, p_values, variant_names, p_c, p_c_prime)
% Display specialized summary for viscoelastic analysis

fprintf('\n=== Viscoelastic Analysis Summary ===\n');

% Find critical regions
[~, p_c_idx] = min(abs(p_values - p_c));
[~, p_c_prime_idx] = min(abs(p_values - p_c_prime));

fprintf('Standard percolation threshold (p_c = %.4f):\n', p_c);
for variant = 1:4
    num_clusters = cluster_stats(p_c_idx, variant, 1);
    largest_cluster = cluster_stats(p_c_idx, variant, 2);
    fprintf('  %s: %d clusters, largest %d\n', variant_names{variant}, num_clusters, largest_cluster);
end

fprintf('\nCritical gel-point (p_c'' = %.4f):\n', p_c_prime);
for variant = 1:4
    num_clusters = cluster_stats(p_c_prime_idx, variant, 1);
    largest_cluster = cluster_stats(p_c_prime_idx, variant, 2);
    fprintf('  %s: %d clusters, largest %d\n', variant_names{variant}, num_clusters, largest_cluster);
end

% Fine resolution analysis
fine_mask = p_values >= 0.61 & p_values <= 0.69;
fine_p = p_values(fine_mask);
fprintf('\nFine resolution around gel-point [%.2f, %.2f]:\n', min(fine_p), max(fine_p));
fprintf('  Number of p-values: %d\n', sum(fine_mask));
fprintf('  Resolution: %.3f\n', mean(diff(fine_p)));

% Universality class indicators
fprintf('\nUniversality class indicators:\n');
for variant = 1:4
    % Calculate average connectivity in critical regions
    critical_connectivity = mean(1 ./ (squeeze(cluster_stats(fine_mask, variant, 1)) + 1));
    fprintf('  %s: connectivity indicator = %.6f\n', variant_names{variant}, critical_connectivity);
end

% Density accuracy
fprintf('\nDensity accuracy summary:\n');
for variant = 1:4
    density_errors = abs(squeeze(cluster_stats(:, variant, 4)) - p_values);
    mean_error = mean(density_errors);
    max_error = max(density_errors);
    fprintf('  %s: mean error %.6f, max error %.6f\n', variant_names{variant}, mean_error, max_error);
end

fprintf('\nLattices ready for G'', G'''', tan(delta), tau_l, and tau_cr analysis!\n');
fprintf('Focus on critical regions for universality class discovery.\n');

end
