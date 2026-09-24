% analyze_mat_results.m
% Analyze the comprehensive CSV results from RUN_RANDOM_WALK_ANALYSIS.m
% Uses datastore for efficient reading of large CSV files

clear; close all; clc;
mat_file = 'Clusters/random_walk_analysis_L500_LW1000000_NW3000.mat';


load(mat_file)
%%



% Display basic data information
fprintf('\n=== DATA OVERVIEW ===\n');
fprintf('MSD_results size: %s\n', mat2str(size(MSD_results)));
fprintf('p_values: %s\n', mat2str(p_values));
fprintf('variants: %s\n', strjoin(variants, ', '));
fprintf('LW (time steps): %d\n', LW);

% Extract alpha exponents and create comprehensive analysis
fprintf('\n=== EXTRACTING ALPHA EXPONENTS ===\n');
alpha_results = extract_alpha_exponents(MSD_results, p_values, variants);
delta_results = alpha_results * pi / 2 * 180 / pi;  % Convert to degrees

% Create results table
fprintf('\n=== CREATING RESULTS TABLE ===\n');
results_table = create_analysis_table(p_values, variants, alpha_results, delta_results, p_c, p_c_prime);

% Save results to files
fprintf('\n=== SAVING RESULTS ===\n');
save_analysis_results(results_table, alpha_results, delta_results, p_values, variants, 'Clusters');

% Create comprehensive analysis plots
fprintf('\n=== CREATING ANALYSIS PLOTS ===\n');
create_msd_analysis_plots(MSD_results, MSD_tau_results, p_values, variants, 500, LW, 3000, 'Clusters');
create_universality_class_analysis(MSD_results, p_values, variants, 500, p_c, p_c_prime, 'Clusters');
create_critical_region_msd_analysis(MSD_results, p_values, variants, 500, p_c, p_c_prime, 'Clusters');

% Calculate and display summary statistics
fprintf('\n=== SUMMARY STATISTICS ===\n');
display_rw_summary(MSD_results, [], [], p_values, variants, p_c, p_c_prime);

% Save reconstructed data
fprintf('\n=== SAVING RECONSTRUCTED DATA ===\n');
results_file = 'Clusters/reconstructed_msd_analysis_L500_LW1000000_NW3000.mat';
%save(results_file, 'MSD_results', 'MSD_tau_results', 'p_values', 'variants', 'LW', 'p_c', 'p_c_prime');
fprintf('Reconstructed data saved to: %s\n', results_file);

fprintf('\n=== ANALYSIS COMPLETE ===\n');

% ============================================================================
% PLOTTING FUNCTIONS (copied from analyze_lattice_random_walks_modified.m)
% ============================================================================
%%
function create_msd_analysis_plots(MSD_results, MSD_tau_results, p_values, variants, L, LW, NW, output_dir)
% Create comprehensive MSD analysis plots

fig = figure('Position', [100, 100, 1600, 1200], 'Name', sprintf('MSD Analysis L=%d, LW=%d, NW=%d', L, LW, NW));

% Subplot 1: MSD evolution for different variants at key p-values
subplot(2, 3, 1);
key_p_indices = [1, round(length(p_values)/4), round(length(p_values)/2), round(3*length(p_values)/4), length(p_values)];
key_p_values = p_values(key_p_indices);
colors = lines(length(variants));

for v = 1:length(variants)
    for p_idx = key_p_indices
        if p_idx <= size(MSD_results, 2) && ~any(isnan(MSD_results(:, p_idx, v)))
            plot(MSD_results(:, p_idx, v), 'Color', colors(v, :), 'LineWidth', 1.5, ...
                 'DisplayName', sprintf('%s, p=%.3f', variants{v}, p_values(p_idx)));
            hold on;
        end
    end
end
xlabel('Time Step');
ylabel('MSD');
title('MSD Evolution: Key P-values');
legend('Location', 'northwest', 'NumColumns', 2);
grid on;
set(gca, 'YScale', 'log', 'XScale', 'log');

% Subplot 2: Final MSD vs p for all variants
subplot(2, 3, 2);
for v = 1:length(variants)
    final_msd = squeeze(MSD_results(end, :, v));
    valid_indices = ~isnan(final_msd);
    if any(valid_indices)
        plot(p_values(valid_indices), final_msd(valid_indices), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Final MSD');
title('Final MSD vs P');
legend('Location', 'southwest');
grid on;
set(gca, 'YScale', 'log');

% Subplot 3: MSD at specific time points vs p
subplot(2, 3, 3);
time_points = [1, round(LW/100), round(LW/10), round(LW/2), LW];
time_labels = {'t=1', 't/100', 't/10', 't/2', 't'};

for t_idx = 1:length(time_points)
    t = time_points(t_idx);
    if t <= size(MSD_results, 1)
        for v = 1:length(variants)
            msd_at_t = squeeze(MSD_results(t, :, v));
            valid_indices = ~isnan(msd_at_t);
            if any(valid_indices)
                plot(p_values(valid_indices), msd_at_t(valid_indices), 'o-', 'LineWidth', 1.5, ...
                     'DisplayName', sprintf('%s, %s', variants{v}, time_labels{t_idx}));
                hold on;
            end
        end
    end
end
xlabel('Percolation Probability p');
ylabel('MSD at Different Times');
title('MSD vs P at Multiple Time Points');
legend('Location', 'southwest', 'NumColumns', 1);
grid on;
set(gca, 'YScale', 'log');

% Subplot 4: Moving average MSD comparison
subplot(2, 3, 4);
p_compare = 0.5;  % Compare at p=0.5
[~, p_idx] = min(abs(p_values - p_compare));

for v = 1:length(variants)
    if p_idx <= size(MSD_tau_results, 2) && ~any(isnan(MSD_tau_results(:, p_idx, v)))
        plot(MSD_tau_results(:, p_idx, v), 'LineWidth', 2, 'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Time Step');
ylabel('Moving Average MSD');
title(sprintf('Moving Average MSD at p=%.3f', p_compare));
legend('Location', 'northwest');
grid on;
set(gca, 'YScale', 'log', 'XScale', 'log');

% Subplot 5: MSD comparison across variants
subplot(2, 3, 5);
for v = 1:length(variants)
    final_msd = squeeze(MSD_results(end, :, v));
    valid_indices = ~isnan(final_msd);
    if any(valid_indices)
        semilogy(p_values(valid_indices), final_msd(valid_indices), 'o-', 'LineWidth', 2);
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Final MSD (log scale)');
title('MSD Comparison Across Variants');
legend('Location', 'southwest');
grid on;

% Subplot 6: MSD growth rates (alpha exponents)
subplot(2, 3, 6);
alpha_results = zeros(length(p_values), length(variants));

% Calculate alpha exponents from MSD slopes
time_window = round(size(MSD_results, 1) * 0.1):size(MSD_results, 1);  % Last 10% of data
time_steps = (1:size(MSD_results, 1))';

for p_idx = 1:length(p_values)
    for v = 1:length(variants)
        msd_data = MSD_results(:, p_idx, v);
        if ~any(isnan(msd_data)) && length(time_window) > 10
            % Fit power law: MSD ∝ t^alpha
            log_t = log(time_steps(time_window));
            log_msd = log(msd_data(time_window));
            
            % Linear fit to extract alpha
            valid_data = ~isnan(log_msd) & ~isinf(log_msd);
            if sum(valid_data) > 5
                p_fit = polyfit(log_t(valid_data), log_msd(valid_data), 1);
                alpha_results(p_idx, v) = p_fit(1);
            else
                alpha_results(p_idx, v) = NaN;
            end
        else
            alpha_results(p_idx, v) = NaN;
        end
    end
end

% Plot alpha vs p for all variants
for v = 1:length(variants)
    valid_indices = ~isnan(alpha_results(:, v));
    if any(valid_indices)
        plot(p_values(valid_indices), alpha_results(valid_indices, v), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Alpha Exponent (MSD ∝ t^alpha)');
title('Growth Exponent vs P');
legend('Location', 'southwest');
grid on;

sgtitle(sprintf('MSD Analysis - L=%d, LW=%d, NW=%d', L, LW, NW), 'FontSize', 16);

% Save figure
filename = fullfile(output_dir, sprintf('csv_msd_analysis_L%d_LW%d_NW%d.png', L, LW, NW));
%saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function create_universality_class_analysis(MSD_results, p_values, variants, L, p_c, p_c_prime, output_dir)
% Create universality class analysis plots

fig = figure('Position', [200, 200, 1400, 800], 'Name', sprintf('Universality Class Analysis L=%d', L));

% Subplot 1: alpha exponent extraction (slope of log-log MSD)
subplot(2, 2, 1);
alpha_results = zeros(length(p_values), length(variants));

% Calculate alpha exponents from MSD slopes
time_window = round(size(MSD_results, 1) * 0.1):size(MSD_results, 1);  % Last 10% of data
time_steps = (1:size(MSD_results, 1))';

for p_idx = 1:length(p_values)
    for v = 1:length(variants)
        msd_data = MSD_results(:, p_idx, v);
        if ~any(isnan(msd_data)) && length(time_window) > 10
            % Fit power law: MSD ∝ t^alpha
            log_t = log(time_steps(time_window));
            log_msd = log(msd_data(time_window));
            
            % Linear fit to extract alpha
            valid_data = ~isnan(log_msd) & ~isinf(log_msd);
            if sum(valid_data) > 5
                p_fit = polyfit(log_t(valid_data), log_msd(valid_data), 1);
                alpha_results(p_idx, v) = p_fit(1);
            else
                alpha_results(p_idx, v) = NaN;
            end
        else
            alpha_results(p_idx, v) = NaN;
        end
    end
end

% Plot alpha vs p for all variants
for v = 1:length(variants)
    valid_indices = ~isnan(alpha_results(:, v));
    if any(valid_indices)
        plot(p_values(valid_indices), alpha_results(valid_indices, v), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end

% Mark critical regions
xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);

xlabel('Percolation Probability p');
ylabel('Alpha Exponent (MSD ∝ t^alpha)');
title('Universality Class: Alpha Exponent vs P');
legend('Location', 'southwest');
grid on;

% Subplot 2: Phase angle delta = pi*alpha/2
subplot(2, 2, 2);
delta_results = alpha_results * pi / 2 * 180 / pi;  % Convert to degrees

for v = 1:length(variants)
    valid_indices = ~isnan(delta_results(:, v));
    if any(valid_indices)
        plot(p_values(valid_indices), delta_results(valid_indices, v), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end

% Mark theoretical expectations
xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);
yline(45, '--k', 'delta = 45° (viscoelastic)', 'LineWidth', 1);
yline(90, '--k', 'delta = 90° (liquid)', 'LineWidth', 1);
yline(0, '--k', 'delta = 0° (solid)', 'LineWidth', 1);

xlabel('Percolation Probability p');
ylabel('Phase Angle delta (degrees)');
title('Universality Class: Phase Angle delta vs P');
legend('Location', 'southwest');
grid on;

% Subplot 3: Critical region focus
subplot(2, 2, 3);
critical_mask = p_values >= 0.25 & p_values <= 0.75;
p_critical = p_values(critical_mask);

for v = 1:length(variants)
    alpha_critical = alpha_results(critical_mask, v);
    valid_indices = ~isnan(alpha_critical);
    if any(valid_indices)
        plot(p_critical(valid_indices), alpha_critical(valid_indices), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end

xline(p_c, '--r', 'p_c = 0.3116', 'LineWidth', 2);
xline(p_c_prime, '--g', 'p_c'' = 0.6884', 'LineWidth', 2);

xlabel('Percolation Probability p');
ylabel('Alpha Exponent');
title('Critical Region: Alpha vs P');
legend('Location', 'southwest');
grid on;

% Subplot 4: Variant comparison at key p-values
subplot(2, 2, 4);
key_p_values = [0.2, 0.3116, 0.5, 0.6884, 0.8];

for p_key = key_p_values
    [~, p_idx] = min(abs(p_values - p_key));
    if p_idx <= size(alpha_results, 1)
        alpha_at_p = alpha_results(p_idx, :);
        
        if any(~isnan(alpha_at_p))
            bar(1:length(variants), alpha_at_p, 'DisplayName', sprintf('p=%.3f', p_key));
            hold on;
        end
    end
end

set(gca, 'XTickLabel', variants);
xlabel('Lattice Variant');
ylabel('Alpha Exponent');
title('Alpha Exponent Comparison Across Variants');
legend('Location', 'eastoutside');
grid on;

sgtitle(sprintf('Universality Class Analysis - L=%d', L), 'FontSize', 14);

% Save figure
filename = fullfile(output_dir, sprintf('csv_universality_class_analysis_L%d.png', L));
%saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function create_critical_region_msd_analysis(MSD_results, p_values, variants, L, p_c, p_c_prime, output_dir)
% Create detailed MSD analysis in critical regions

fig = figure('Position', [300, 300, 1400, 600], 'Name', sprintf('Critical Region MSD Analysis L=%d', L));

% Subplot 1: Standard percolation threshold region (p_c)
subplot(1, 2, 1);
p_c_mask = abs(p_values - p_c) < 0.05;
p_c_values = p_values(p_c_mask);

for v = 1:length(variants)
    for p_idx = find(p_c_mask)
        if p_idx <= size(MSD_results, 2) && ~any(isnan(MSD_results(:, p_idx, v)))
            plot(MSD_results(:, p_idx, v), 'LineWidth', 1.5, ...
                 'DisplayName', sprintf('%s, p=%.4f', variants{v}, p_values(p_idx)));
            hold on;
        end
    end
end

xlabel('Time Step');
ylabel('MSD');
title(sprintf('Critical Region: p_c = %.4f ± 0.05', p_c));
%legend('Location', 'westoutside', 'NumColumns', 2);
grid on;
set(gca, 'YScale', 'log', 'XScale', 'log');

% Subplot 2: Critical gel-point region (p_c_prime)
subplot(1, 2, 2);
p_c_prime_mask = abs(p_values - p_c_prime) < 0.05;
p_c_prime_values = p_values(p_c_prime_mask);

for v = 1:length(variants)
    for p_idx = find(p_c_prime_mask)
        if p_idx <= size(MSD_results, 2) && ~any(isnan(MSD_results(:, p_idx, v)))
            plot(MSD_results(:, p_idx, v), 'LineWidth', 1.5, ...
                 'DisplayName', sprintf('%s, p=%.4f', variants{v}, p_values(p_idx)));
            hold on;
        end
    end
end

xlabel('Time Step');
ylabel('MSD');
title(sprintf('Critical Region: p_c'' = %.4f ± 0.05', p_c_prime));
legend('Location', 'westoutside', 'NumColumns', 2);
grid on;
set(gca, 'YScale', 'log', 'XScale', 'log');

sgtitle(sprintf('Critical Region MSD Analysis - L=%d', L), 'FontSize', 14);

% Save figure
filename = fullfile(output_dir, sprintf('csv_critical_region_msd_L%d.png', L));
%saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function display_rw_summary(MSD_results, runtime_results, walker_stats, p_values, variants, p_c, p_c_prime)
% Display summary statistics for random walk analysis

fprintf('\n=== RANDOM WALK ANALYSIS SUMMARY ===\n');

% MSD statistics
fprintf('MSD Statistics:\n');
for v = 1:length(variants)
    final_msd = squeeze(MSD_results(end, :, v));
    valid_msd = final_msd(~isnan(final_msd));
    if ~isempty(valid_msd)
        fprintf('  %s: final MSD range [%.2e, %.2e]\n', variants{v}, min(valid_msd), max(valid_msd));
    end
end

% Critical region analysis
fprintf('\nCritical Region Analysis:\n');
[~, p_c_idx] = min(abs(p_values - p_c));
[~, p_c_prime_idx] = min(abs(p_values - p_c_prime));

fprintf('  Standard percolation (p_c = %.4f):\n', p_c);
for v = 1:length(variants)
    if p_c_idx <= size(MSD_results, 2) && ~isnan(MSD_results(end, p_c_idx, v))
        fprintf('    %s: final MSD = %.2e\n', variants{v}, MSD_results(end, p_c_idx, v));
    end
end

fprintf('  Critical gel-point (p_c'' = %.4f):\n', p_c_prime);
for v = 1:length(variants)
    if p_c_prime_idx <= size(MSD_results, 2) && ~isnan(MSD_results(end, p_c_prime_idx, v))
        fprintf('    %s: final MSD = %.2e\n', variants{v}, MSD_results(end, p_c_prime_idx, v));
    end
end

fprintf('\nMSD data ready for universality class analysis!\n');
fprintf('Next steps:\n');
fprintf('1. Extract alpha exponents from MSD slopes\n');
fprintf('2. Calculate phase angles delta = pi*alpha/2\n');
fprintf('3. Identify tau_l and tau_cr time scales\n');
fprintf('4. Compare universality classes across variants\n');

end

% ============================================================================
% HELPER FUNCTIONS FOR ANALYSIS
% ============================================================================

function alpha_results = extract_alpha_exponents(MSD_results, p_values, variants)
% Extract alpha exponents from MSD slopes for all p_values and variants

fprintf('Extracting alpha exponents from MSD data...\n');
alpha_results = zeros(length(p_values), length(variants));

% Calculate alpha exponents from MSD slopes
time_window = round(size(MSD_results, 1) * 0.1):size(MSD_results, 1);  % Last 10% of data
time_steps = (1:size(MSD_results, 1))';

for p_idx = 1:length(p_values)
    for v = 1:length(variants)
        msd_data = MSD_results(:, p_idx, v);
        if ~any(isnan(msd_data)) && length(time_window) > 10
            % Fit power law: MSD ∝ t^alpha
            log_t = log(time_steps(time_window));
            log_msd = log(msd_data(time_window));
            
            % Linear fit to extract alpha
            valid_data = ~isnan(log_msd) & ~isinf(log_msd);
            if sum(valid_data) > 5
                p_fit = polyfit(log_t(valid_data), log_msd(valid_data), 1);
                alpha_results(p_idx, v) = p_fit(1);
                fprintf('  %s, p=%.3f: alpha = %.3f\n', variants{v}, p_values(p_idx), p_fit(1));
            else
                alpha_results(p_idx, v) = NaN;
                fprintf('  %s, p=%.3f: insufficient data\n', variants{v}, p_values(p_idx));
            end
        else
            alpha_results(p_idx, v) = NaN;
            fprintf('  %s, p=%.3f: no valid data\n', variants{v}, p_values(p_idx));
        end
    end
end

fprintf('Alpha extraction complete.\n');
end

function results_table = create_analysis_table(p_values, variants, alpha_results, delta_results, p_c, p_c_prime)
% Create comprehensive analysis table

fprintf('Creating analysis table...\n');

% Initialize table
num_entries = length(p_values) * length(variants);
p_col = zeros(num_entries, 1);
variant_col = cell(num_entries, 1);
alpha_col = zeros(num_entries, 1);
delta_col = zeros(num_entries, 1);
regime_col = cell(num_entries, 1);
quality_col = cell(num_entries, 1);

idx = 1;
for p_idx = 1:length(p_values)
    for v = 1:length(variants)
        p_col(idx) = p_values(p_idx);
        variant_col{idx} = variants{v};
        alpha_col(idx) = alpha_results(p_idx, v);
        delta_col(idx) = delta_results(p_idx, v);
        
        % Determine regime
        if p_values(p_idx) < p_c
            regime_col{idx} = 'Below p_c';
        elseif p_values(p_idx) < p_c_prime
            regime_col{idx} = 'Between p_c and p_c_prime';
        else
            regime_col{idx} = 'Above p_c_prime';
        end
        
        % Determine quality
        if isnan(alpha_results(p_idx, v))
            quality_col{idx} = 'No Data';
        elseif alpha_results(p_idx, v) < 0.1
            quality_col{idx} = 'Poor';
        elseif alpha_results(p_idx, v) < 0.5
            quality_col{idx} = 'Fair';
        elseif alpha_results(p_idx, v) < 1.0
            quality_col{idx} = 'Good';
        else
            quality_col{idx} = 'Excellent';
        end
        
        idx = idx + 1;
    end
end

% Create table
results_table = table(p_col, variant_col, alpha_col, delta_col, regime_col, quality_col, ...
    'VariableNames', {'p_value', 'variant', 'alpha', 'delta_degrees', 'regime', 'quality'});

fprintf('Analysis table created with %d entries.\n', height(results_table));
end

function save_analysis_results(results_table, alpha_results, delta_results, p_values, variants, output_dir)
% Save analysis results to files

% Save table as CSV
csv_file = fullfile(output_dir, 'universality_class_analysis.csv');
writetable(results_table, csv_file);
fprintf('  Saved: %s\n', csv_file);

% Save detailed results as MAT
mat_file = fullfile(output_dir, 'universality_class_analysis.mat');
save(mat_file, 'results_table', 'alpha_results', 'delta_results', 'p_values', 'variants');
fprintf('  Saved: %s\n', mat_file);

% Create summary statistics file
summary_file = fullfile(output_dir, 'analysis_summary.txt');
fid = fopen(summary_file, 'w');
fprintf(fid, 'UNIVERSALITY CLASS ANALYSIS SUMMARY\n');
fprintf(fid, '====================================\n\n');
fprintf(fid, 'Data Overview:\n');
fprintf(fid, '  Number of p_values: %d\n', length(p_values));
fprintf(fid, '  Number of variants: %d\n', length(variants));
fprintf(fid, '  Variants: %s\n', strjoin(variants, ', '));
fprintf(fid, '\nAlpha Exponent Summary:\n');

for v = 1:length(variants)
    valid_alphas = alpha_results(~isnan(alpha_results(:, v)), v);
    if ~isempty(valid_alphas)
        fprintf(fid, '  %s: mean=%.3f, std=%.3f, range=[%.3f, %.3f]\n', ...
            variants{v}, mean(valid_alphas), std(valid_alphas), min(valid_alphas), max(valid_alphas));
    else
        fprintf(fid, '  %s: no valid data\n', variants{v});
    end
end

fprintf(fid, '\nPhase Angle Summary:\n');
for v = 1:length(variants)
    valid_deltas = delta_results(~isnan(delta_results(:, v)), v);
    if ~isempty(valid_deltas)
        fprintf(fid, '  %s: mean=%.1f°, std=%.1f°, range=[%.1f°, %.1f°]\n', ...
            variants{v}, mean(valid_deltas), std(valid_deltas), min(valid_deltas), max(valid_deltas));
    else
        fprintf(fid, '  %s: no valid data\n', variants{v});
    end
end

fclose(fid);
fprintf('  Saved: %s\n', summary_file);
end
