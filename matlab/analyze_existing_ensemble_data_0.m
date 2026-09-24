function analyze_existing_ensemble_data_0()
% analyze_existing_ensemble_data.m
% Analyze existing ensemble simulation data with detailed MSD curve annotations
% Uses the 1,000,000 step walks from seed_01 and seed_02 datasets
% Implements comprehensive MSD curve annotations and power-law analysis

clear; clc; close all;

fprintf('=== Analyzing Existing Ensemble Simulation Data ===\n');
fprintf('Using 1,000,000 step walks from seed_01 and seed_02\n\n');

% Parameters
p_c_prime = 0.6884;
seeds = {'seed_01', 'seed_02'};
p_values = [0.0000, 0.3116, 0.6884, 0.7500];

% Initialize results structure
results = struct();
results.seeds = seeds;
results.p_values = p_values;
results.p_c_prime = p_c_prime;

% Data structure to store results for each seed and p value
for seed_idx = 1:length(seeds)
    seed = seeds{seed_idx};
    for p_idx = 1:length(p_values)
        p_current = p_values(p_idx);
        
        % Create field name (replace dots with underscores for MATLAB)
        field_name = sprintf('%s_p_%.4f', strrep(seed, '_', ''), p_current);
        field_name = strrep(field_name, '.', '_');
        
        % Initialize result structure
        results.(field_name) = struct();
        results.(field_name).seed = seed;
        results.(field_name).p_value = p_current;
        results.(field_name).tau_cr = NaN;
        results.(field_name).alpha_opt = NaN;
        results.(field_name).alpha_error = NaN;
        results.(field_name).regime = '';
        results.(field_name).distance_from_critical = abs(p_current - p_c_prime);
        results.(field_name).msd_data = [];
        results.(field_name).t_data = [];
        results.(field_name).alpha_analysis = struct();
        results.(field_name).data_loaded = false;
    end
end

% Load and analyze data for each seed and p value
for seed_idx = 1:length(seeds)
    seed = seeds{seed_idx};
    fprintf('Processing %s:\n', seed);
    
    for p_idx = 1:length(p_values)
        p_current = p_values(p_idx);
        
        % Create field name
        field_name = sprintf('%s_p_%.4f', strrep(seed, '_', ''), p_current);
        field_name = strrep(field_name, '.', '_');
        
        fprintf('  p = %.4f: ', p_current);
        
        % Determine regime
        if p_current < p_c_prime - 0.05
            regime = 'LIQUID';
        elseif abs(p_current - p_c_prime) < 0.05
            regime = 'CRITICAL';
        else
            regime = 'SOLID';
        end
        
        results.(field_name).regime = regime;

        fldr = '/Users/rowanbrown/Documents/GitHub/RW_Percolation';
        
        % Load MSD data
        data_file = sprintf('/ensemble_simulations/%s/p_%.4f/msd_results_L500_p%.4f.csv', ...
            seed, p_current, p_current);
        data_file = strcat(fldr,data_file);
        
        if exist(data_file, 'file')
            try
                % Load CSV data
                data = readtable(data_file);
                
                % Extract time and MSD columns
                if ismember('time', data.Properties.VariableNames)
                    t_data = data.time;
                elseif ismember('Time', data.Properties.VariableNames)
                    t_data = data.Time;
                else
                    % Assume first column is time
                    t_data = data{:, 1};
                end
                
                if ismember('msd', data.Properties.VariableNames)
                    msd_data = data.msd;
                elseif ismember('MSD', data.Properties.VariableNames)
                    msd_data = data.MSD;
                else
                    % Assume second column is MSD
                    msd_data = data{:, 2};
                end
                
                % Store data
                results.(field_name).t_data = t_data;
                results.(field_name).msd_data = msd_data;
                results.(field_name).data_loaded = true;
                
                % Analyze α and find changepoint
                [tau_cr, alpha_opt, alpha_error, alpha_analysis] = robust_local_alpha_analysis_detailed(t_data, msd_data);
                
                % Store results
                results.(field_name).tau_cr = tau_cr;
                results.(field_name).alpha_opt = alpha_opt;
                results.(field_name).alpha_error = alpha_error;
                results.(field_name).alpha_analysis = alpha_analysis;
                
                if ~isnan(tau_cr)
                    fprintf('τ_cr = %.2e, α = %.3f, error = %.3f (%s)\n', ...
                        tau_cr, alpha_opt, alpha_error, regime);
                else
                    fprintf('No changepoint found (%s)\n', regime);
                end
                
            catch ME
                fprintf('Error loading data: %s\n', ME.message);
                results.(field_name).data_loaded = false;
            end
        else
            fprintf('Data file not found\n');
            results.(field_name).data_loaded = false;
        end
    end
    fprintf('\n');
end

% Create comprehensive analysis plots
create_ensemble_msd_plots(results, p_c_prime);

% Perform power-law analysis
analyze_ensemble_power_law(results, p_c_prime);

% Generate summary report
generate_ensemble_summary_report(results, p_c_prime);

fprintf('=== Analysis Complete ===\n');
fprintf('Detailed MSD plots with annotations generated.\n');
fprintf('Power-law analysis completed.\n');
fprintf('Summary report generated.\n');

end

function [tau_cr, alpha_opt, alpha_error, alpha_analysis] = robust_local_alpha_analysis_detailed(t, msd)
% Robust local α analysis with detailed output for plotting

window_size = min(30, length(t) / 30);  % Smaller window for faster analysis

start_idx = max(10, round(window_size / 2));
end_idx = length(t) - round(window_size / 2);

alpha_values = [];
alpha_errors = [];
tau_values = [];
r_squared_values = [];

for i = start_idx:end_idx
    window_start = max(1, i - round(window_size / 2));
    window_end = min(length(t), i + round(window_size / 2));
    
    t_window = t(window_start:window_end);
    msd_window = msd(window_start:window_end);
    
    if all(msd_window > 0) && length(t_window) >= 20
        ln_t = log10(t_window);
        ln_msd = log10(msd_window);
        
        try
            coeffs = polyfit(ln_t, ln_msd, 1);
            alpha = coeffs(1);
            
            msd_pred = 10.^(alpha * ln_t + coeffs(2));
            ss_res = sum((msd_window - msd_pred).^2);
            ss_tot = sum((msd_window - mean(msd_window)).^2);
            
            if ss_tot > 0
                r_squared = 1 - (ss_res / ss_tot);
            else
                r_squared = 0;
            end
            
            alpha_values = [alpha_values, alpha];
            alpha_errors = [alpha_errors, 1 - r_squared];
            tau_values = [tau_values, t(i)];
            r_squared_values = [r_squared_values, r_squared];
            
        catch
            continue;
        end
    end
end

% Store detailed analysis
alpha_analysis = struct();
alpha_analysis.tau_values = tau_values;
alpha_analysis.alpha_values = alpha_values;
alpha_analysis.alpha_errors = alpha_errors;
alpha_analysis.r_squared_values = r_squared_values;

if isempty(alpha_values)
    tau_cr = NaN;
    alpha_opt = NaN;
    alpha_error = NaN;
    return;
end

% Find first good quality point
good_quality = alpha_errors < 0.1;

if ~any(good_quality)
    tau_cr = NaN;
    alpha_opt = NaN;
    alpha_error = NaN;
    return;
end

first_good_idx = find(good_quality, 1);
tau_cr = tau_values(first_good_idx);
alpha_opt = alpha_values(first_good_idx);
alpha_error = alpha_errors(first_good_idx);

end

function create_ensemble_msd_plots(results, p_c_prime)
% Create detailed MSD plots with comprehensive annotations for ensemble data

% Get field names for valid data
field_names = fieldnames(results);
valid_fields = {};

for i = 1:length(field_names)
    field = field_names{i};
    if isstruct(results.(field)) && isfield(results.(field), 'data_loaded')
        if results.(field).data_loaded
            valid_fields{end+1} = field;
        end
    end
end

if isempty(valid_fields)
    fprintf('No valid data found for plotting\n');
    return;
end

% Create main figure with MSD curves and annotations
figure('Position', [100, 100, 1600, 1200]);

% Determine number of subplots (one for each valid data point)
num_plots = length(valid_fields);
cols = ceil(sqrt(num_plots));
rows = ceil(num_plots / cols);

% Colors for different regimes
colors = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, {'blue', 'red', 'green'});

% Plot MSD curves with annotations for each data point
for plot_idx = 1:length(valid_fields)
    field = valid_fields{plot_idx};
    data = results.(field);
    
    subplot(rows, cols, plot_idx);
    
    p_current = data.p_value;
    regime = data.regime;
    tau_cr = data.tau_cr;
    alpha_opt = data.alpha_opt;
    alpha_error = data.alpha_error;
    distance = data.distance_from_critical;
    
    % Get MSD data
    t_data = data.t_data;
    msd_data = data.msd_data;
    alpha_analysis = data.alpha_analysis;
    
    % Plot MSD curve
    loglog(t_data, msd_data, 'b-', 'LineWidth', 1.5);
    hold on;
    
            % Add theoretical lines based on regime
        if strcmp(regime, 'LIQUID')
            % Normal diffusion: MSD ∝ t
            theoretical_line = t_data;
            h = loglog(t_data, theoretical_line, '--b', 'LineWidth', 1);
            set(h, 'Color', [0, 0, 1, 0.7]);  % Blue with transparency
            theoretical_alpha = 1.0;
        elseif strcmp(regime, 'CRITICAL')
            % Anomalous diffusion: MSD ∝ t^0.5
            theoretical_line = t_data.^0.5;
            h = loglog(t_data, theoretical_line, '--r', 'LineWidth', 1);
            set(h, 'Color', [1, 0, 0, 0.7]);  % Red with transparency
            theoretical_alpha = 0.5;
        else % SOLID
            % Arrested diffusion: MSD ∝ t^0
            theoretical_line = ones(size(t_data));
            h = loglog(t_data, theoretical_line, '--g', 'LineWidth', 1);
            set(h, 'Color', [0, 1, 0, 0.7]);  % Green with transparency
            theoretical_alpha = 0.0;
        end
    
    % Mark changepoint if found
    if ~isnan(tau_cr)
        % Find closest time index
        [~, tau_idx] = min(abs(t_data - tau_cr));
        loglog(tau_cr, msd_data(tau_idx), 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
        
        % Add arrow and annotation
        %arrow([tau_cr/2, msd_data(tau_idx)/2], [tau_cr, msd_data(tau_idx)], 'Color', 'k', 'LineWidth', 2);
        text(tau_cr*1.5, msd_data(tau_idx)/2, sprintf('τ_cr = %.1e\nα = %.3f', tau_cr, alpha_opt), ...
            'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', 'white');
    end
    
    % Add α analysis regions if available (simplified for performance)
    if ~isempty(alpha_analysis) && isfield(alpha_analysis, 'tau_values') && ~isempty(alpha_analysis.tau_values)
        % Plot α values along the curve (every 10th point for performance)
        valid_indices = 1:10:min(length(alpha_analysis.tau_values), length(msd_data));
        if length(valid_indices) > 1
            scatter(alpha_analysis.tau_values(valid_indices), msd_data(valid_indices), ...
                15, alpha_analysis.alpha_values(valid_indices), 'filled');
            
            % Add colorbar for α values
            colormap(gca, 'jet');
            c = colorbar;
            c.Label.String = 'α values';
            caxis([0, 1]);
        end
    end
    
    % Add regime information box
    regime_text = sprintf('%s\n%s\np = %.3f\n|p-p_c''| = %.3f\nExpected α = %.1f', ...
        data.seed, regime, p_current, distance, theoretical_alpha);
    text(0.02, 0.98, regime_text, 'Units', 'normalized', ...
        'VerticalAlignment', 'top', 'FontSize', 9, 'FontWeight', 'bold', ...
        'BackgroundColor', 'white', 'EdgeColor', colors(regime), 'LineWidth', 1);
    
    % Add quality indicator
    if ~isnan(alpha_error)
        if alpha_error < 0.05
            quality = 'EXCELLENT';
            quality_color = 'green';
        elseif alpha_error < 0.1
            quality = 'GOOD';
            quality_color = 'orange';
        else
            quality = 'POOR';
            quality_color = 'red';
        end
        
        text(0.98, 0.02, sprintf('Quality: %s\nError: %.3f', quality, alpha_error), ...
            'Units', 'normalized', 'VerticalAlignment', 'bottom', ...
            'HorizontalAlignment', 'right', 'FontSize', 8, 'FontWeight', 'bold', ...
            'BackgroundColor', 'white', 'EdgeColor', quality_color, 'LineWidth', 1);
    end
    
    xlabel('Time t');
    ylabel('MSD(t)');
    title(sprintf('%s: p = %.3f (%s)', data.seed, p_current, regime));
    grid on;
    
    % Set axis limits
    xlim([min(t_data), max(t_data)]);
    ylim([min(msd_data), max(msd_data)]);
end

sgtitle(sprintf('Ensemble MSD Curves with Annotations (p_c'' = %.4f)', p_c_prime), 'FontSize', 14, 'FontWeight', 'bold');

% Create summary analysis plots
figure('Position', [100, 100, 1400, 1000]);

% Extract valid data for summary plots
valid_p = [];
valid_tau_cr = [];
valid_alpha = [];
valid_error = [];
valid_regime = {};
valid_distance = [];
valid_seeds = {};

for i = 1:length(valid_fields)
    field = valid_fields{i};
    data = results.(field);
    
    if ~isnan(data.tau_cr)
        valid_p = [valid_p, data.p_value];
        valid_tau_cr = [valid_tau_cr, data.tau_cr];
        valid_alpha = [valid_alpha, data.alpha_opt];
        valid_error = [valid_error, data.alpha_error];
        valid_regime{end+1} = data.regime;
        valid_distance = [valid_distance, data.distance_from_critical];
        valid_seeds{end+1} = data.seed;
    end
end

if isempty(valid_p)
    fprintf('No valid changepoint data for summary plots\n');
    return;
end

% Plot 1: τ_cr vs p
subplot(2, 3, 1);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    semilogy(valid_p(i), valid_tau_cr(i), 'o', 'Color', color, 'MarkerSize', 8, 'MarkerFaceColor', color);
    hold on;
end

xline(p_c_prime, '--k', 'LineWidth', 2, 'Label', 'p_c''');
xlabel('p');
ylabel('τ_cr');
title('Changepoint Time vs p');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;

% Plot 2: Power-law relationship
subplot(2, 3, 2);
non_critical_mask = valid_distance > 0;
dist_non_critical = valid_distance(non_critical_mask);
tau_non_critical = valid_tau_cr(non_critical_mask);

if length(dist_non_critical) >= 2
    loglog(dist_non_critical, tau_non_critical, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    hold on;
    
    % Fit and plot power law
    log_dist = log10(dist_non_critical);
    log_tau = log10(tau_non_critical);
    coeffs = polyfit(log_dist, log_tau, 1);
    exponent = coeffs(1);
    
    dist_range = logspace(log10(min(dist_non_critical)), log10(max(dist_non_critical)), 100);
    tau_fit = 10.^(exponent * log10(dist_range) + coeffs(2));
    loglog(dist_range, tau_fit, 'r-', 'LineWidth', 2);
    
    legend('Data', sprintf('Fit: ν = %.3f', exponent), 'Location', 'best');
end

xlabel('|p - p_c''|');
ylabel('τ_cr');
title('Power-Law Relationship');
grid on;

% Plot 3: α vs p
subplot(2, 3, 3);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    plot(valid_p(i), valid_alpha(i), 'o', 'Color', color, 'MarkerSize', 8, 'MarkerFaceColor', color);
    hold on;
end

% Add theoretical lines
yline(1.0, '--b', 'Alpha', 0.5, 'Label', 'α = 1.0 (Liquid)');
yline(0.5, '--r', 'Alpha', 0.5, 'Label', 'α = 0.5 (Critical)');
yline(0.0, '--g', 'Alpha', 0.5, 'Label', 'α = 0.0 (Solid)');
xline(p_c_prime, '--k', 'LineWidth', 2, 'Label', 'p_c''');

xlabel('p');
ylabel('α');
title('Optimal α vs p');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;
ylim([-0.1, 1.1]);

% Plot 4: α error vs p
subplot(2, 3, 4);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    semilogy(valid_p(i), valid_error(i), 'o', 'Color', color, 'MarkerSize', 8, 'MarkerFaceColor', color);
    hold on;
end

yline(0.1, '--k', 'Alpha', 0.5, 'Label', 'Quality threshold');
xline(p_c_prime, '--k', 'LineWidth', 2, 'Label', 'p_c''');

xlabel('p');
ylabel('α Error (1 - R²)');
title('α Quality vs p');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;

% Plot 5: τ_cr vs distance from critical point
subplot(2, 3, 5);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    semilogy(valid_distance(i), valid_tau_cr(i), 'o', 'Color', color, 'MarkerSize', 8, 'MarkerFaceColor', color);
    hold on;
end

xlabel('|p - p_c''|');
ylabel('τ_cr');
title('τ_cr vs Distance from Critical Point');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;

% Plot 6: α vs distance from critical point
subplot(2, 3, 6);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    plot(valid_distance(i), valid_alpha(i), 'o', 'Color', color, 'MarkerSize', 8, 'MarkerFaceColor', color);
    hold on;
end

xlabel('|p - p_c''|');
ylabel('α');
title('α vs Distance from Critical Point');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;
ylim([-0.1, 1.1]);

sgtitle('Ensemble Analysis Summary', 'FontSize', 14, 'FontWeight', 'bold');

end

function analyze_ensemble_power_law(results, p_c_prime)
% Analyze power-law relationship for ensemble data

fprintf('\n=== Power-Law Analysis ===\n');

% Extract valid data
field_names = fieldnames(results);
valid_tau_cr = [];
valid_distance = [];
valid_p = [];
valid_seeds = {};

for i = 1:length(field_names)
    field = field_names{i};
    if isstruct(results.(field)) && isfield(results.(field), 'data_loaded')
        if results.(field).data_loaded && ~isnan(results.(field).tau_cr)
            valid_tau_cr = [valid_tau_cr, results.(field).tau_cr];
            valid_distance = [valid_distance, results.(field).distance_from_critical];
            valid_p = [valid_p, results.(field).p_value];
            valid_seeds{end+1} = results.(field).seed;
        end
    end
end

if length(valid_tau_cr) < 2
    fprintf('Insufficient data for power-law analysis\n');
    return;
end

% Exclude critical point
non_critical_mask = valid_distance > 0;
dist_non_critical = valid_distance(non_critical_mask);
tau_non_critical = valid_tau_cr(non_critical_mask);
p_non_critical = valid_p(non_critical_mask);
seeds_non_critical = valid_seeds(non_critical_mask);

if length(dist_non_critical) < 2
    fprintf('Insufficient non-critical data for power-law analysis\n');
    return;
end

% Fit power law
log_dist = log10(dist_non_critical);
log_tau = log10(tau_non_critical);
coeffs = polyfit(log_dist, log_tau, 1);
exponent = coeffs(1);

% Calculate R²
tau_pred = 10.^(exponent * log_dist + coeffs(2));
ss_res = sum((tau_non_critical - tau_pred).^2);
ss_tot = sum((tau_non_critical - mean(tau_non_critical)).^2);
r_squared = 1 - (ss_res / ss_tot);

fprintf('Power-law exponent: ν = %.3f\n', exponent);
fprintf('R² = %.3f\n', r_squared);
fprintf('Equation: τ_cr ∝ |p - p_c''|^{%.3f}\n', exponent);

% Print detailed results
fprintf('\nDetailed Results:\n');
fprintf('%-12s %-8s %-12s %-12s %-10s\n', 'Seed', 'p', '|p-p_c''|', 'τ_cr', 'Regime');
fprintf('%-12s %-8s %-12s %-12s %-10s\n', '----', '-', '--------', '----', '------');

for i = 1:length(valid_p)
    field = field_names{i};
    if isstruct(results.(field)) && isfield(results.(field), 'data_loaded')
        if results.(field).data_loaded && ~isnan(results.(field).tau_cr)
            fprintf('%-12s %-8.4f %-12.4f %-12.2e %-10s\n', ...
                results.(field).seed, ...
                results.(field).p_value, ...
                results.(field).distance_from_critical, ...
                results.(field).tau_cr, ...
                results.(field).regime);
        end
    end
end

end

function generate_ensemble_summary_report(results, p_c_prime)
% Generate summary report for ensemble analysis

fprintf('\n=== Ensemble Analysis Summary Report ===\n');

% Count successful analyses
field_names = fieldnames(results);
successful_count = 0;
total_count = 0;

for i = 1:length(field_names)
    field = field_names{i};
    if isstruct(results.(field)) && isfield(results.(field), 'data_loaded')
        total_count = total_count + 1;
        if results.(field).data_loaded && ~isnan(results.(field).tau_cr)
            successful_count = successful_count + 1;
        end
    end
end

fprintf('Success rate: %d/%d (%.1f%%)\n', successful_count, total_count, 100*successful_count/total_count);

% Analyze by regime
regime_stats = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, {0, 0, 0});
regime_success = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, {0, 0, 0});

for i = 1:length(field_names)
    field = field_names{i};
    if isstruct(results.(field)) && isfield(results.(field), 'data_loaded')
        if results.(field).data_loaded
            regime = results.(field).regime;
            regime_stats(regime) = regime_stats(regime) + 1;
            
            if ~isnan(results.(field).tau_cr)
                regime_success(regime) = regime_success(regime) + 1;
            end
        end
    end
end

fprintf('\nRegime Analysis:\n');
regimes = keys(regime_stats);
for i = 1:length(regimes)
    regime = regimes{i};
    total = regime_stats(regime);
    success = regime_success(regime);
    if total > 0
        fprintf('  %s: %d/%d (%.1f%%)\n', regime, success, total, 100*success/total);
    end
end

fprintf('\nAnalysis complete. Check generated plots for detailed visualizations.\n');

end 