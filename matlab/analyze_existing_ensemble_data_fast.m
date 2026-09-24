function analyze_existing_ensemble_data_fast()
% analyze_existing_ensemble_data_fast.m
% Fast version of ensemble analysis with minimal plotting for performance comparison
% Uses the 1,000,000 step walks from seed_01 and seed_02 datasets

clear; clc; close all;

fprintf('=== Fast Ensemble Analysis (MATLAB) ===\n');
fprintf('Using 1,000,000 step walks from seed_01 and seed_02\n\n');

% Parameters
p_c_prime = 0.6884;
seeds = {'seed_01', 'seed_02'};
p_values = [0.0000, 0.3116, 0.6884, 0.7500];

% Initialize results
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
        
        % Load MSD data
        fldr = '/Users/rowanbrown/Documents/GitHub/RW_Percolation';
        data_file = sprintf('/ensemble_simulations/%s/p_%.4f/msd_results_L500_p%.4f.csv', ...
            seed, p_current, p_current);
        data_file = strcat(fldr, data_file);
        
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
                
                results.(field_name).data_loaded = true;
                
                % Fast α analysis (simplified)
                [tau_cr, alpha_opt, alpha_error] = fast_alpha_analysis(t_data, msd_data);
                
                % Store results
                results.(field_name).tau_cr = tau_cr;
                results.(field_name).alpha_opt = alpha_opt;
                results.(field_name).alpha_error = alpha_error;
                
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

% Fast power-law analysis
analyze_fast_power_law(results, p_c_prime);

% Generate summary report
generate_fast_summary_report(results, p_c_prime);

fprintf('=== Fast Analysis Complete ===\n');

end

function [tau_cr, alpha_opt, alpha_error] = fast_alpha_analysis(t, msd)
% Fast α analysis with minimal computation

% Use smaller window for speed
window_size = min(20, length(t) / 50);

start_idx = max(10, round(window_size / 2));
end_idx = min(length(t), start_idx + 50);  % Limit analysis range

alpha_values = [];
alpha_errors = [];
tau_values = [];

for i = start_idx:end_idx
    window_start = max(1, i - round(window_size / 2));
    window_end = min(length(t), i + round(window_size / 2));
    
    t_window = t(window_start:window_end);
    msd_window = msd(window_start:window_end);
    
    if all(msd_window > 0) && length(t_window) >= 10
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
            
        catch
            continue;
        end
    end
end

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

function analyze_fast_power_law(results, p_c_prime)
% Fast power-law analysis

fprintf('\n=== Fast Power-Law Analysis ===\n');

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

function generate_fast_summary_report(results, p_c_prime)
% Generate fast summary report

fprintf('\n=== Fast Summary Report ===\n');

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

fprintf('\nFast analysis complete.\n');

end 