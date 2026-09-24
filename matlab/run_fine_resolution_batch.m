% run_fine_resolution_batch.m
% Batch script to run multiple realizations of fine resolution analysis
% This provides statistical robustness and error estimation

clear; clc; close all;

% Configuration
num_realizations = 5;  % Number of realizations to run
save_individual_files = false;  % Set to true if you want individual MSD files (large storage)

fprintf('=== Fine Resolution Batch Analysis ===\n');
fprintf('Number of realizations: %d\n', num_realizations);
fprintf('Save individual files: %s\n', string(save_individual_files));
fprintf('Starting batch run...\n\n');

% Run realizations
for realization_id = 1:num_realizations
    fprintf('\n=== Starting Realization %d/%d ===\n', realization_id, num_realizations);
    
    try
        % Run the fine resolution analysis
        RW3D_fine_resolution_full_spectrum(realization_id, save_individual_files);
        
        fprintf('Realization %d completed successfully!\n', realization_id);
        
    catch ME
        fprintf('ERROR in Realization %d: %s\n', realization_id, ME.message);
        fprintf('Continuing with next realization...\n');
        continue;
    end
end

fprintf('\n=== Batch Analysis Complete ===\n');
fprintf('All realizations finished.\n');

% Optional: Run ensemble analysis if multiple realizations completed
if num_realizations > 1
    fprintf('\nRunning ensemble analysis...\n');
    analyze_ensemble_results(num_realizations);
end

end

function analyze_ensemble_results(num_realizations)
% Analyze results across multiple realizations

fprintf('=== Ensemble Analysis ===\n');

% Load all realizations
all_results = [];
valid_realizations = 0;

for realization_id = 1:num_realizations
    results_filename = sprintf('fine_resolution_realization_%d/fine_resolution_results_realization_%d.mat', ...
        realization_id, realization_id);
    
    if exist(results_filename, 'file')
        load(results_filename);
        all_results = [all_results, results];
        valid_realizations = valid_realizations + 1;
        fprintf('Loaded realization %d\n', realization_id);
    else
        fprintf('Warning: Results file not found for realization %d\n', realization_id);
    end
end

if valid_realizations < 2
    fprintf('Insufficient realizations for ensemble analysis (need at least 2)\n');
    return;
end

fprintf('Valid realizations: %d\n', valid_realizations);

% Extract power-law exponents
exponents = [];
r_squared_values = [];

for i = 1:valid_realizations
    results = all_results(i);
    
    % Filter out NaN values
    valid_mask = ~isnan(results.tau_cr);
    valid_distance = results.distance_from_critical(valid_mask);
    valid_tau_cr = results.tau_cr(valid_mask);
    
    % Exclude critical point
    non_critical_mask = valid_distance > 0;
    dist_non_critical = valid_distance(non_critical_mask);
    tau_non_critical = valid_tau_cr(non_critical_mask);
    
    if length(dist_non_critical) >= 2
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
        
        exponents = [exponents, exponent];
        r_squared_values = [r_squared_values, r_squared];
    end
end

% Statistical analysis
if length(exponents) > 0
    fprintf('\nPower-law exponent statistics:\n');
    fprintf('Mean ν = %.3f ± %.3f\n', mean(exponents), std(exponents));
    fprintf('Range: [%.3f, %.3f]\n', min(exponents), max(exponents));
    fprintf('Median ν = %.3f\n', median(exponents));
    
    fprintf('\nR² statistics:\n');
    fprintf('Mean R² = %.3f ± %.3f\n', mean(r_squared_values), std(r_squared_values));
    fprintf('Range: [%.3f, %.3f]\n', min(r_squared_values), max(r_squared_values));
    
    % Create ensemble plot
    figure('Position', [100, 100, 800, 600]);
    
    % Plot exponent distribution
    subplot(2, 2, 1);
    histogram(exponents, 'FaceAlpha', 0.7);
    xlabel('Power-law exponent ν');
    ylabel('Frequency');
    title('Distribution of Power-law Exponents');
    grid on;
    
    % Plot R² distribution
    subplot(2, 2, 2);
    histogram(r_squared_values, 'FaceAlpha', 0.7);
    xlabel('R²');
    ylabel('Frequency');
    title('Distribution of R² Values');
    grid on;
    
    % Plot exponent vs R²
    subplot(2, 2, 3);
    scatter(r_squared_values, exponents, 'filled');
    xlabel('R²');
    ylabel('Power-law exponent ν');
    title('Exponent vs R²');
    grid on;
    
    % Box plot of exponents
    subplot(2, 2, 4);
    boxplot(exponents);
    ylabel('Power-law exponent ν');
    title('Box Plot of Exponents');
    grid on;
    
    sgtitle(sprintf('Ensemble Analysis (%d Realizations)', valid_realizations));
    
    % Save ensemble plot
    saveas(gcf, 'ensemble_analysis.png', 'png');
    fprintf('Ensemble plot saved to: ensemble_analysis.png\n');
    
    % Save ensemble statistics
    ensemble_stats = struct();
    ensemble_stats.num_realizations = valid_realizations;
    ensemble_stats.exponents = exponents;
    ensemble_stats.r_squared_values = r_squared_values;
    ensemble_stats.mean_exponent = mean(exponents);
    ensemble_stats.std_exponent = std(exponents);
    ensemble_stats.mean_r_squared = mean(r_squared_values);
    ensemble_stats.std_r_squared = std(r_squared_values);
    ensemble_stats.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
    save('ensemble_statistics.mat', 'ensemble_stats');
    fprintf('Ensemble statistics saved to: ensemble_statistics.mat\n');
    
else
    fprintf('No valid power-law fits found across realizations\n');
end

end 