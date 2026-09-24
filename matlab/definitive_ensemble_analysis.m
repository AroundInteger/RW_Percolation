function definitive_ensemble_analysis()
% DEFINITIVE ENSEMBLE ANALYSIS
% Accurately determines α and τ_cr for 1,000,000 step ensemble simulation data
% This script performs real calculations on the actual data, not hardcoded values

clear; clc; close all;

fprintf('=== DEFINITIVE ENSEMBLE ANALYSIS (MATLAB) ===\n');
fprintf('Accurately determining α and τ_cr for 1,000,000 step data\n');
fprintf('This script performs REAL calculations on actual data\n\n');

% Parameters
p_c_prime = 0.6884;
p_values = [0.0000, 0.3116, 0.6884, 0.7500];
seeds = [1, 2];  % seed_01, seed_02

% Initialize results structure
results = struct();
results.p_c_prime = p_c_prime;
results.p_values = p_values;
results.seeds = seeds;
results.analysis_date = datestr(now);

% Data structure to store results for each p value and seed
for p_idx = 1:length(p_values)
    p_current = p_values(p_idx);
    for seed_idx = 1:length(seeds)
        seed = seeds(seed_idx);
        
        % Create field name
        field_name = sprintf('p_%.4f_seed_%02d', p_current, seed);
        field_name = strrep(field_name, '.', '_');
        
        % Initialize result structure
        results.(field_name) = struct();
        results.(field_name).p = p_current;
        results.(field_name).seed = seed;
        results.(field_name).regime = '';
        results.(field_name).expected_alpha = NaN;
        results.(field_name).tau_cr = NaN;
        results.(field_name).alpha_opt = NaN;
        results.(field_name).alpha_error = NaN;
        results.(field_name).distance_from_critical = abs(p_current - p_c_prime);
        results.(field_name).data_points = 0;
        results.(field_name).success = false;
        results.(field_name).error_message = '';
    end
end

% Run analysis for each p value and seed
fprintf('Starting complete ensemble analysis...\n\n');

successful_count = 0;
total_count = 0;

for p_idx = 1:length(p_values)
    p_current = p_values(p_idx);
    
    % Determine regime
    if p_current < p_c_prime - 0.05
        regime = 'LIQUID';
        expected_alpha = 1.0;
    elseif abs(p_current - p_c_prime) < 0.05
        regime = 'CRITICAL';
        expected_alpha = 0.5;
    else
        regime = 'SOLID';
        expected_alpha = 0.0;
    end
    
    fprintf('Processing p = %.4f (%s regime):\n', p_current, regime);
    
    for seed_idx = 1:length(seeds)
        seed = seeds(seed_idx);
        total_count = total_count + 1;
        
        % Create field name
        field_name = sprintf('p_%.4f_seed_%02d', p_current, seed);
        field_name = strrep(field_name, '.', '_');
        
        fprintf('  Seed %02d: ', seed);
        
        try
            % Load data
            data_path = sprintf('../ensemble_simulations/seed_%02d/p_%.4f/msd_results_L500_p%.4f.csv', ...
                seed, p_current, p_current);
            
            if ~exist(data_path, 'file')
                error('Data file not found');
            end
            
            fprintf('Loading data... ');
            data = readtable(data_path);
            
            % Extract time and MSD columns
            if ismember('tau', data.Properties.VariableNames)
                t = data.tau;
            elseif ismember('time', data.Properties.VariableNames)
                t = data.time;
            else
                t = data{:, 1};
            end
            
            if ismember('msd', data.Properties.VariableNames)
                msd = data.msd;
            elseif ismember('MSD', data.Properties.VariableNames)
                msd = data.MSD;
            else
                msd = data{:, 2};
            end
            
            % Ensure positive values
            t = max(t, 1e-3);
            msd = max(msd, 1e-6);
            
            % Perform robust α analysis
            [tau_cr, alpha_opt, alpha_error, analysis_details] = robust_alpha_analysis_matlab(t, msd);
            
            % Store results
            results.(field_name).regime = regime;
            results.(field_name).expected_alpha = expected_alpha;
            results.(field_name).tau_cr = tau_cr;
            results.(field_name).alpha_opt = alpha_opt;
            results.(field_name).alpha_error = alpha_error;
            results.(field_name).data_points = length(t);
            results.(field_name).success = ~isnan(tau_cr);
            results.(field_name).analysis_details = analysis_details;
            
            if results.(field_name).success
                fprintf('τ_cr = %.2e, α = %.3f, error = %.3f ✓\n', ...
                    tau_cr, alpha_opt, alpha_error);
                successful_count = successful_count + 1;
            else
                fprintf('No changepoint found ✗\n');
            end
            
        catch ME
            fprintf('Error: %s ✗\n', ME.message);
            results.(field_name).error_message = ME.message;
            results.(field_name).success = false;
        end
    end
    fprintf('\n');
end

% Calculate success rate
success_rate = successful_count / total_count;
fprintf('Analysis complete: %d/%d successful (%.1f%%)\n\n', ...
    successful_count, total_count, 100*success_rate);

% Analyze power-law relationship
fprintf('=== Power-Law Analysis ===\n');
power_law = analyze_power_law_matlab(results, p_c_prime);

% Generate summary report
fprintf('=== Summary Report ===\n');
generate_summary_report_matlab(results, power_law, p_c_prime);

% Save results
save_results_matlab(results, power_law);

fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('Check the generated files for detailed results.\n');

end

function [tau_cr, alpha_opt, alpha_error, analysis_details] = robust_alpha_analysis_matlab(t, msd)
% Robust α analysis with sliding window approach (MATLAB version)

% Use larger window for better stability with 1M step data
window_size = min(50, length(t) / 20);

start_idx = max(10, round(window_size / 2));
end_idx = length(t) - round(window_size / 2);

alpha_values = [];
alpha_errors = [];
tau_values = [];
r_squared_values = [];

fprintf('Performing α analysis: window_size=%d, range=%d-%d\n', ...
    window_size, start_idx, end_idx);

% Sample every 1% for speed
step_size = max(1, round((end_idx - start_idx) / 100));

for i = start_idx:step_size:end_idx
    window_start = max(1, i - round(window_size / 2));
    window_end = min(length(t), i + round(window_size / 2));
    
    t_window = t(window_start:window_end);
    msd_window = msd(window_start:window_end);
    
    if length(t_window) >= 20 && all(msd_window > 0)
        try
            % Log-log analysis
            log_t = log10(t_window);
            log_msd = log10(msd_window);
            
            % Linear fit
            coeffs = polyfit(log_t, log_msd, 1);
            alpha = coeffs(1);
            
            % Calculate R²
            msd_pred = 10.^(alpha * log_t + coeffs(2));
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

if isempty(alpha_values)
    tau_cr = NaN;
    alpha_opt = NaN;
    alpha_error = NaN;
    analysis_details = struct();
    return;
end

% Find first good quality point
good_quality = alpha_errors < 0.1;

if ~any(good_quality)
    % If no good quality points, use best available
    [~, best_idx] = min(alpha_errors);
    tau_cr = tau_values(best_idx);
    alpha_opt = alpha_values(best_idx);
    alpha_error = alpha_errors(best_idx);
else
    first_good_idx = find(good_quality, 1);
    tau_cr = tau_values(first_good_idx);
    alpha_opt = alpha_values(first_good_idx);
    alpha_error = alpha_errors(first_good_idx);
end

% Store detailed analysis
analysis_details = struct();
analysis_details.tau_values = tau_values;
analysis_details.alpha_values = alpha_values;
analysis_details.alpha_errors = alpha_errors;
analysis_details.r_squared_values = r_squared_values;
analysis_details.window_size = window_size;
analysis_details.total_points_analyzed = length(alpha_values);

end

function power_law = analyze_power_law_matlab(results, p_c_prime)
% Analyze power-law relationship between τ_cr and distance from critical point

fprintf('Analyzing power-law relationship...\n');

% Extract valid data
valid_data = [];
field_names = fieldnames(results);

for i = 1:length(field_names)
    field = field_names{i};
    if isstruct(results.(field)) && isfield(results.(field), 'success')
        if results.(field).success && results.(field).distance_from_critical > 0
            valid_data = [valid_data; results.(field)];
        end
    end
end

if length(valid_data) < 2
    fprintf('Insufficient data for power-law analysis\n');
    power_law = struct('success', false, 'error', 'Insufficient data');
    return;
end

% Prepare for analysis
distances = [valid_data.distance_from_critical];
tau_cr_values = [valid_data.tau_cr];

% Log-log transformation
log_dist = log10(distances);
log_tau = log10(tau_cr_values);

% Linear fit
coeffs = polyfit(log_dist, log_tau, 1);
exponent = coeffs(1);
intercept = coeffs(2);

% Calculate R²
tau_pred = 10.^(exponent * log_dist + intercept);
ss_res = sum((tau_cr_values - tau_pred).^2);
ss_tot = sum((tau_cr_values - mean(tau_cr_values)).^2);
if ss_tot > 0
    r_squared = 1 - (ss_res / ss_tot);
else
    r_squared = 0;
end

% Calculate RMSE
residuals = log_tau - (exponent * log_dist + intercept);
rmse = sqrt(mean(residuals.^2));

power_law = struct();
power_law.success = true;
power_law.exponent = exponent;
power_law.intercept = intercept;
power_law.r_squared = r_squared;
power_law.rmse = rmse;
power_law.equation = sprintf('τ_cr ∝ |p - p_c''|^{%.3f}', exponent);
power_law.data_points = length(valid_data);
power_law.valid_data = valid_data;

fprintf('Power-law result: %s\n', power_law.equation);
fprintf('R² = %.3f, RMSE = %.3f\n', r_squared, rmse);

end

function generate_summary_report_matlab(results, power_law, p_c_prime)
% Generate comprehensive summary report

fprintf('\n=== DEFINITIVE ENSEMBLE ANALYSIS SUMMARY REPORT ===\n');
fprintf('Critical point: p_c'' = %.4f\n', p_c_prime);
fprintf('Analysis date: %s\n\n', datestr(now));

% Overall statistics
total_count = 0;
successful_count = 0;
regime_stats = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, {0, 0, 0});
regime_success = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, {0, 0, 0});

field_names = fieldnames(results);
for i = 1:length(field_names)
    field = field_names{i};
    if isstruct(results.(field)) && isfield(results.(field), 'success')
        total_count = total_count + 1;
        regime = results.(field).regime;
        
        if ~isempty(regime)
            if isKey(regime_stats, regime)
                regime_stats(regime) = regime_stats(regime) + 1;
            else
                regime_stats(regime) = 1;
            end
            
            if results.(field).success
                successful_count = successful_count + 1;
                if isKey(regime_success, regime)
                    regime_success(regime) = regime_success(regime) + 1;
                else
                    regime_success(regime) = 1;
                end
            end
        end
    end
end

if total_count > 0
    success_rate = successful_count / total_count;
else
    success_rate = 0;
end
fprintf('Overall Success Rate: %d/%d (%.1f%%)\n\n', ...
    successful_count, total_count, 100*success_rate);

% Regime analysis
fprintf('REGIME ANALYSIS:\n');
regimes = keys(regime_stats);
for i = 1:length(regimes)
    regime = regimes{i};
    total = regime_stats(regime);
    success = regime_success(regime);
    if total > 0
        rate = success / total;
        fprintf('  %s: %d/%d (%.1f%%)\n', regime, success, total, 100*rate);
    end
end
fprintf('\n');

% Detailed results
fprintf('DETAILED RESULTS:\n');
fprintf('%-8s %-6s %-10s %-12s %-8s %-8s %-8s\n', 'p', 'Seed', 'Regime', 'τ_cr', 'α', 'Error', 'Success');
fprintf('%-70s\n', repmat('-', 1, 70));

for i = 1:length(field_names)
    field = field_names{i};
    if isstruct(results.(field)) && isfield(results.(field), 'success')
        data = results.(field);
        p = data.p;
        seed = data.seed;
        regime = data.regime;
        tau_cr = data.tau_cr;
        alpha = data.alpha_opt;
        error_val = data.alpha_error;
        if data.success
    success = '✓';
else
    success = '✗';
end
        
        if isnan(tau_cr)
            tau_str = 'N/A';
            alpha_str = 'N/A';
            error_str = 'N/A';
        else
            tau_str = sprintf('%.2e', tau_cr);
            alpha_str = sprintf('%.3f', alpha);
            error_str = sprintf('%.3f', error_val);
        end
        
        fprintf('%-8.4f %-6d %-10s %-12s %-8s %-8s %-8s\n', ...
            p, seed, regime, tau_str, alpha_str, error_str, success);
    end
end
fprintf('\n');

% Power-law analysis
if power_law.success
    fprintf('POWER-LAW ANALYSIS:\n');
    fprintf('  Equation: %s\n', power_law.equation);
    fprintf('  Exponent (ν): %.3f\n', power_law.exponent);
    fprintf('  R²: %.3f\n', power_law.r_squared);
    fprintf('  RMSE: %.3f\n', power_law.rmse);
    fprintf('  Data points: %d\n', power_law.data_points);
else
    fprintf('POWER-LAW ANALYSIS: Failed\n');
    fprintf('  Error: %s\n', power_law.error);
end

fprintf('\n');
fprintf('%s\n', repmat('=', 1, 60));
fprintf('\n');

end

function save_results_matlab(results, power_law)
% Save results to files

% Save detailed results
results_table = [];
field_names = fieldnames(results);

for i = 1:length(field_names)
    field = field_names{i};
    if isstruct(results.(field)) && isfield(results.(field), 'success')
        data = results.(field);
        % Remove analysis_details field for table conversion
        if isfield(data, 'analysis_details')
            data = rmfield(data, 'analysis_details');
        end
        results_table = [results_table; struct2table(data, 'AsArray', true)];
    end
end

if ~isempty(results_table)
    writetable(results_table, 'definitive_ensemble_results_matlab.csv');
end

% Save power-law data
if power_law.success
    power_law_table = struct2table(power_law.valid_data, 'AsArray', true);
    writetable(power_law_table, 'definitive_power_law_data_matlab.csv');
end

% Save full results structure
save('definitive_ensemble_results_matlab.mat', 'results', 'power_law');

fprintf('Results saved to:\n');
fprintf('  - definitive_ensemble_results_matlab.csv\n');
if power_law.success
    fprintf('  - definitive_power_law_data_matlab.csv\n');
end
fprintf('  - definitive_ensemble_results_matlab.mat\n');

end 