function analyze_lattice_random_walks(p_values, variants, L, LW, NW, output_dir)
% ANALYZE_LATTICE_RANDOM_WALKS Comprehensive RW analysis on generated lattices
%
% This function conducts random walks on the generated lattices to analyze
% universality classes through MSD behavior across percolation and variants.
%
% Inputs:
%   p_values - Array of percolation values to analyze
%   variants - Cell array of variant names to analyze
%   L - Lattice size
%   LW - Number of walk steps (default: 1e6)
%   NW - Number of walkers (default: 3e3)
%   output_dir - Output directory (default: 'Clusters')

if nargin < 4, LW = 1e6; end
if nargin < 5, NW = 3e3; end
if nargin < 6, output_dir = 'Clusters'; end

fprintf('=== Lattice Random Walk Analysis ===\n');
fprintf('Universality Class Discovery through MSD Analysis\n\n');
fprintf('Parameters:\n');
fprintf('  Lattice size: %dx%dx%d\n', L, L, L);
fprintf('  Walk length: %d steps\n', LW);
fprintf('  Number of walkers: %d\n', NW);
fprintf('  P-values: %d values from %.4f to %.4f\n', length(p_values), p_values(1), p_values(end));
fprintf('  Variants: %s\n', strjoin(variants, ', '));
fprintf('  Output directory: %s\n\n', output_dir);

% Critical regions for analysis
p_c = 0.3116;           % Standard percolation threshold
p_c_prime = 0.6884;     % Critical gel-point

% Initialize results storage
num_p = length(p_values);
num_variants = length(variants);

% MSD storage: [time_steps, p_values, variants]
MSD_results = zeros(LW, num_p, num_variants);
MSD_tau_results = zeros(LW, num_p, num_variants);  % Moving average
runtime_results = zeros(num_p, num_variants);
walker_stats = zeros(num_p, num_variants, 3);  % [successful_walks, total_sites, free_sites]

% Progress tracking
total_analyses = num_p * num_variants;
fprintf('Starting random walk analysis on %d lattice configurations...\n', total_analyses);
fprintf('Progress: [');
progress_bar_length = 50;

analysis_count = 0;

% Analyze each p-value and variant combination
for p_idx = 1:num_p
    p = p_values(p_idx);
    
    for variant_idx = 1:num_variants
        variant = variants{variant_idx};
        analysis_count = analysis_count + 1;
        
        % Update progress bar
        progress = analysis_count / total_analyses;
        filled_length = round(progress * progress_bar_length);
        fprintf(repmat('█', 1, filled_length));
        fprintf(repmat('░', 1, progress_bar_length - filled_length));
        fprintf('] %.1f%%\r', progress * 100);
        
        try
            % Load the lattice
            [lattice, metadata] = load_lattice_for_microrheology(variant, p, L, output_dir);
            
            % Prepare for random walk analysis
            occupied_sites = logical(lattice);
            free_sites = ~occupied_sites;
            
            % Count sites
            total_sites = numel(lattice);
            num_occupied = sum(occupied_sites(:));
            num_free = sum(free_sites(:));
            
            % Check if we have enough free sites
            if num_free < NW
                fprintf('\nWarning: Not enough free sites for %d walkers at p=%.4f, variant=%s\n', NW, p, variant);
                fprintf('  Free sites: %d, Required: %d\n', num_free, NW);
                continue;
            end
            
            % Find free positions for walkers
            [px, py, pz] = ind2sub([L, L, L], find(free_sites));
            N_rsp = numel(px);
            
            % Randomly select starting positions for walkers
            rp = ceil(rand(NW, 1) * N_rsp);
            rsp = [px(rp), py(rp), pz(rp)];
            
            fprintf('\nRunning %d walkers for %d steps on %s, p=%.4f...\n', NW, LW, variant, p);
            tic;
            
            % Initialize walker positions
            x = zeros(LW, NW); y = x; z = x;
            
            % Run random walks in parallel
            parfor i_rw = 1:NW
                [xyz, ~] = RW3D_P_SP(occupied_sites, LW, L, rsp(i_rw,:), [20, 5]);
                x(:, i_rw) = xyz(:, 1);
                y(:, i_rw) = xyz(:, 2);
                z(:, i_rw) = xyz(:, 3);
            end
            
            runtime = toc;
            fprintf('  Simulation completed in %.2f seconds\n', runtime);
            
            % Calculate MSD
            dx = x - x(1, :);
            dy = y - y(1, :);
            dz = z - z(1, :);
            sd = dx.^2 + dy.^2 + dz.^2;
            msd = mean(sd, 2);
            tau_msd = movmean(msd, 10);
            
            % Store results
            MSD_results(:, p_idx, variant_idx) = msd;
            MSD_tau_results(:, p_idx, variant_idx) = tau_msd;
            runtime_results(p_idx, variant_idx) = runtime;
            walker_stats(p_idx, variant_idx, :) = [NW, total_sites, num_free];
            
            % SEQUENTIAL SAVING: Save MSD data immediately after each lattice
            individual_filename = sprintf('MSD_%s_p%.4f_L%d_LW%d_NW%d.mat', variant, p, L, LW, NW);
            individual_filepath = fullfile(output_dir, individual_filename);
            
            % Save individual MSD data
            individual_data = struct();
            individual_data.msd = msd;
            individual_data.tau_msd = tau_msd;
            individual_data.variant = variant;
            individual_data.p_value = p;
            individual_data.L = L;
            individual_data.LW = LW;
            individual_data.NW = NW;
            individual_data.runtime = runtime;
            individual_data.walker_stats = [NW, total_sites, num_free];
            individual_data.timestamp = datetime('now');
            
            save(individual_filepath, '-struct', 'individual_data');
            fprintf('  MSD calculated, final MSD: %.2e\n', msd(end));
            fprintf('  Saved: %s\n', individual_filename);
            
        catch ME
            fprintf('\nError analyzing %s at p=%.4f: %s\n', variant, p, ME.message);
            % Set error values
            MSD_results(:, p_idx, variant_idx) = NaN;
            MSD_tau_results(:, p_idx, variant_idx) = NaN;
            runtime_results(p_idx, variant_idx) = NaN;
            walker_stats(p_idx, variant_idx, :) = [NaN, NaN, NaN];
        end
    end
end

fprintf('\n\nRandom walk analysis complete!\n\n');

% Count saved individual MSD files
saved_files = dir(fullfile(output_dir, sprintf('MSD_*_L%d_LW%d_NW%d.mat', L, LW, NW)));
fprintf('Individual MSD files saved: %d/%d\n', length(saved_files), length(p_values) * length(variants));
fprintf('Files saved to: %s\n', output_dir);
fprintf('Individual file format: MSD_{variant}_p{value}_L{L}_LW{LW}_NW{NW}.mat\n\n');

% Create comprehensive analysis plots
fprintf('Creating analysis plots...\n');
create_msd_analysis_plots(MSD_results, MSD_tau_results, p_values, variants, L, LW, NW, output_dir, runtime_results, walker_stats);
create_universality_class_analysis(MSD_results, p_values, variants, L, p_c, p_c_prime, output_dir);
create_critical_region_msd_analysis(MSD_results, p_values, variants, L, p_c, p_c_prime, output_dir);

% Save numerical results
fprintf('Saving numerical results...\n');
results_file = fullfile(output_dir, sprintf('random_walk_analysis_L%d_LW%d_NW%d.mat', L, LW, NW));
save(results_file, 'MSD_results', 'MSD_tau_results', 'p_values', 'variants', 'L', 'LW', 'NW', ...
     'runtime_results', 'walker_stats', 'p_c', 'p_c_prime');

% Save CSV for external analysis
csv_file = fullfile(output_dir, sprintf('random_walk_analysis_L%d_LW%d_NW%d.csv', L, LW, NW));
save_msd_results_to_csv(MSD_results, MSD_tau_results, p_values, variants, L, LW, NW, csv_file);

fprintf('Results saved to:\n');
fprintf('  %s\n', results_file);
fprintf('  %s\n', csv_file);

% Display summary statistics
display_rw_summary(MSD_results, runtime_results, walker_stats, p_values, variants, p_c, p_c_prime);

fprintf('\n=== Random Walk Analysis Complete ===\n');
fprintf('MSD data ready for universality class analysis!\n');
fprintf('Next: Extract alpha exponents and analyze tau_l, tau_cr behavior.\n');

end

function create_msd_analysis_plots(MSD_results, MSD_tau_results, p_values, variants, L, LW, NW, output_dir, runtime_results, walker_stats)
% Create comprehensive MSD analysis plots

fig = figure('Position', [100, 100, 1600, 1200], 'Name', sprintf('MSD Analysis L=%d, LW=%d, NW=%d', L, LW, NW));

% Subplot 1: MSD evolution for different variants at key p-values
subplot(2, 3, 1);
key_p_indices = [1, round(length(p_values)/4), round(length(p_values)/2), round(3*length(p_values)/4), length(p_values)];
key_p_values = p_values(key_p_indices);
colors = lines(length(variants));

for v = 1:length(variants)
    for p_idx = key_p_indices
        if ~any(isnan(MSD_results(:, p_idx, v)))
            plot(MSD_results(:, p_idx, v), 'Color', colors(v, :), 'LineWidth', 1.5, ...
                 'DisplayName', sprintf('%s, p=%.3f', variants{v}, p_values(p_idx)));
            hold on;
        end
    end
end
xlabel('Time Step');
ylabel('MSD');
title('MSD Evolution: Key P-values');
legend('Location', 'best', 'NumColumns', 2);
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
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 3: MSD at specific time points vs p
subplot(2, 3, 3);
time_points = [1, round(LW/100), round(LW/10), round(LW/2), LW];
time_labels = {'t=1', 't/100', 't/10', 't/2', 't'};

for t_idx = 1:length(time_points)
    t = time_points(t_idx);
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
xlabel('Percolation Probability p');
ylabel('MSD at Different Times');
title('MSD vs P at Multiple Time Points');
legend('Location', 'best', 'NumColumns', 2);
grid on;
set(gca, 'YScale', 'log');

% Subplot 4: Moving average MSD comparison
subplot(2, 3, 4);
p_compare = 0.5;  % Compare at p=0.5
[~, p_idx] = min(abs(p_values - p_compare));

for v = 1:length(variants)
    if ~any(isnan(MSD_tau_results(:, p_idx, v)))
        plot(MSD_tau_results(:, p_idx, v), 'LineWidth', 2, 'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Time Step');
ylabel('Moving Average MSD');
title(sprintf('Moving Average MSD at p=%.3f', p_compare));
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log', 'XScale', 'log');

% Subplot 5: Runtime comparison
subplot(2, 3, 5);
for v = 1:length(variants)
    valid_indices = ~isnan(runtime_results(:, v));
    if any(valid_indices)
        plot(p_values(valid_indices), runtime_results(valid_indices, v), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Runtime (seconds)');
title('Runtime vs P');
legend('Location', 'best');
grid on;

% Subplot 6: Walker success rate
subplot(2, 3, 6);
for v = 1:length(variants)
    success_rate = squeeze(walker_stats(:, v, 1)) ./ squeeze(walker_stats(:, v, 2)) * 100;
    valid_indices = ~isnan(success_rate);
    if any(valid_indices)
        plot(p_values(valid_indices), success_rate(valid_indices), 'o-', 'LineWidth', 2, ...
             'DisplayName', variants{v});
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Walker Success Rate (%)');
title('Walker Success Rate vs P');
legend('Location', 'best');
grid on;

sgtitle(sprintf('MSD Analysis - L=%d, LW=%d, NW=%d', L, LW, NW), 'FontSize', 16);

% Save figure
filename = fullfile(output_dir, sprintf('msd_analysis_L%d_LW%d_NW%d.png', L, LW, NW));
saveas(fig, filename, 'png');
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
legend('Location', 'best');
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
legend('Location', 'best');
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
legend('Location', 'best');
grid on;

% Subplot 4: Variant comparison at key p-values
subplot(2, 2, 4);
key_p_values = [0.2, 0.3116, 0.5, 0.6884, 0.8];

for p_key = key_p_values
    [~, p_idx] = min(abs(p_values - p_key));
    alpha_at_p = alpha_results(p_idx, :);
    
    if any(~isnan(alpha_at_p))
        bar(1:length(variants), alpha_at_p, 'DisplayName', sprintf('p=%.3f', p_key));
        hold on;
    end
end

set(gca, 'XTickLabel', variants);
xlabel('Lattice Variant');
ylabel('Alpha Exponent');
title('Alpha Exponent Comparison Across Variants');
legend('Location', 'best');
grid on;

sgtitle(sprintf('Universality Class Analysis - L=%d', L), 'FontSize', 14);

% Save figure
filename = fullfile(output_dir, sprintf('universality_class_analysis_L%d.png', L));
saveas(fig, filename, 'png');
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
        if ~any(isnan(MSD_results(:, p_idx, v)))
            plot(MSD_results(:, p_idx, v), 'LineWidth', 1.5, ...
                 'DisplayName', sprintf('%s, p=%.4f', variants{v}, p_values(p_idx)));
            hold on;
        end
    end
end

xlabel('Time Step');
ylabel('MSD');
title(sprintf('Critical Region: p_c = %.4f ± 0.05', p_c));
legend('Location', 'best', 'NumColumns', 2);
grid on;
set(gca, 'YScale', 'log', 'XScale', 'log');

% Subplot 2: Critical gel-point region (p_c_prime)
subplot(1, 2, 2);
p_c_prime_mask = abs(p_values - p_c_prime) < 0.05;
p_c_prime_values = p_values(p_c_prime_mask);

for v = 1:length(variants)
    for p_idx = find(p_c_prime_mask)
        if ~any(isnan(MSD_results(:, p_idx, v)))
            plot(MSD_results(:, p_idx, v), 'LineWidth', 1.5, ...
                 'DisplayName', sprintf('%s, p=%.4f', variants{v}, p_values(p_idx)));
            hold on;
        end
    end
end

xlabel('Time Step');
ylabel('MSD');
title(sprintf('Critical Region: p_c'' = %.4f ± 0.05', p_c_prime));
legend('Location', 'best', 'NumColumns', 2);
grid on;
set(gca, 'YScale', 'log', 'XScale', 'log');

sgtitle(sprintf('Critical Region MSD Analysis - L=%d', L), 'FontSize', 14);

% Save figure
filename = fullfile(output_dir, sprintf('critical_region_msd_L%d.png', L));
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function save_msd_results_to_csv(MSD_results, MSD_tau_results, p_values, variants, L, LW, NW, csv_file)
% Save MSD results to CSV format

% Create table structure
num_p = length(p_values);
num_variants = length(variants);
num_time_steps = size(MSD_results, 1);

% Prepare data for CSV
csv_data = [];
headers = {'time_step', 'p_value', 'variant', 'msd', 'msd_tau'};

for t = 1:min(1000, num_time_steps)  % Sample every 1000th step to keep file manageable
    for p_idx = 1:num_p
        for v = 1:num_variants
            p = p_values(p_idx);
            variant = variants{v};
            msd_val = MSD_results(t, p_idx, v);
            msd_tau_val = MSD_tau_results(t, p_idx, v);
            
            if ~isnan(msd_val)
                row = [t, p, v, msd_val, msd_tau_val];
                csv_data = [csv_data; row];
            end
        end
    end
end

% Create table and save
T = array2table(csv_data, 'VariableNames', headers);
writetable(T, csv_file);

end

function display_rw_summary(MSD_results, runtime_results, walker_stats, p_values, variants, p_c, p_c_prime)
% Display summary statistics for random walk analysis

fprintf('\n=== Random Walk Analysis Summary ===\n');

% Runtime statistics
fprintf('Runtime Statistics:\n');
for v = 1:length(variants)
    valid_times = runtime_results(:, v);
    valid_times = valid_times(~isnan(valid_times));
    if ~isempty(valid_times)
        fprintf('  %s: mean=%.2fs, total=%.2fs\n', variants{v}, mean(valid_times), sum(valid_times));
    end
end

% Walker statistics
fprintf('\nWalker Statistics:\n');
for v = 1:length(variants)
    success_rates = squeeze(walker_stats(:, v, 1)) ./ squeeze(walker_stats(:, v, 2)) * 100;
    valid_rates = success_rates(~isnan(success_rates));
    if ~isempty(valid_rates)
        fprintf('  %s: success rate %.1f%% ± %.1f%%\n', variants{v}, mean(valid_rates), std(valid_rates));
    end
end

% MSD statistics
fprintf('\nMSD Statistics:\n');
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
    if ~isnan(MSD_results(end, p_c_idx, v))
        fprintf('    %s: final MSD = %.2e\n', variants{v}, MSD_results(end, p_c_idx, v));
    end
end

fprintf('  Critical gel-point (p_c'' = %.4f):\n', p_c_prime);
for v = 1:length(variants)
    if ~isnan(MSD_results(end, p_c_prime_idx, v))
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
