%% Robust Alpha Detector - Find Longest Linear Region with α ≈ 1
% This script finds the longest linear region with α ≈ 1 working backwards
% from the end of the data, identifying the crossover point where significant
% deviation occurs.

clear; clc; close all;

%% Load data
fprintf('Loading MSD data...\n');
data = readtable('p_output.csv');
p_values = [];
msd_data = [];

% Extract p-values and MSD data
for i = 1:width(data)
    col_name = data.Properties.VariableNames{i};
    if startsWith(col_name, 'MSD_')
        p_str_id = max(findstr(col_name,'_'));

        p_str = str2double(strcat('0.',col_name(p_str_id+1:end)));

        p_values = [p_values, p_str];
        msd_data = [msd_data, data.(col_name)];
    end
end

% Create time array
t = (1:height(data))';

fprintf('Loaded %d p-values\n', length(p_values));



%% Analyze all p-values
fprintf('\n=== ROBUST ALPHA DETECTION ===\n');
fprintf('Target: α ≈ 1 (longest linear region working backwards)\n\n');

% Parameters
target_alpha = 1.0;  % Target alpha for liquid regime
window_sizes = [100, 150, 200, 250, 300];  % Different window sizes to try
r2_threshold = 0.95;  % Minimum R² for good fit

% Initialize results
results = struct();
results.p = [];
results.regime = {};
results.tau_cr = [];
results.alpha = [];
results.r_squared = [];
results.window_size = [];
results.start_idx = [];
results.end_idx = [];

% Sort p-values for systematic analysis
[sorted_p, sort_idx] = sort(p_values);

for i = 1:length(sorted_p)
    p = sorted_p(i);
    p_idx = sort_idx(i);
    
    % Get MSD data for this p-value
    msd = msd_data(:, p_idx);
    
    % Determine regime
    p_c_prime = 0.6884;
    if p < p_c_prime - 0.05
        regime = 'LIQUID';
    elseif abs(p - p_c_prime) < 0.05
        regime = 'CRITICAL';
    else
        regime = 'SOLID';
    end
    
    fprintf('Analyzing p = %.4f (%s)...\n', p, regime);
    
    % Detect robust alpha
    [tau_cr, alpha, r_squared, start_idx, end_idx] = detect_robust_alpha(t, msd, p, target_alpha, window_sizes, r2_threshold);
    
    if ~isnan(tau_cr)
        % Calculate actual window size used
        window_size_used = end_idx - start_idx + 1;
        
        % Store results
        results.p = [results.p, p];
        results.regime{end+1} = regime;
        results.tau_cr = [results.tau_cr, tau_cr];
        results.alpha = [results.alpha, alpha];
        results.r_squared = [results.r_squared, r_squared];
        results.window_size = [results.window_size, window_size_used];
        results.start_idx = [results.start_idx, start_idx];
        results.end_idx = [results.end_idx, end_idx];
        
        fprintf('  τ_cr = %.0f, α = %.3f, R² = %.3f, window = %d\n', tau_cr, alpha, r_squared, window_size_used);
    else
        fprintf('  No robust linear region found\n');
    end
end

%% Create detailed visualization for selected p-values
fprintf('\n=== CREATING DETAILED VISUALIZATIONS ===\n');

% Select key p-values for detailed analysis
p_c_prime = 0.6884;
key_p_values = [p_c_prime - 0.05, p_c_prime, p_c_prime + 0.05];

% Find closest available p-values
available_p_values = [];
for target_p = key_p_values
    [~, closest_idx] = min(abs(sorted_p - target_p));
    available_p_values = [available_p_values, sorted_p(closest_idx)];
end

% Create detailed plots
for p = available_p_values
    p_idx = find(sorted_p == p);
    if isempty(p_idx)
        continue;
    end
    
    % Get MSD data
    msd = msd_data(:, sort_idx(p_idx));
    
    % Filter valid data
    valid_mask = isfinite(msd) & (msd > 0) & (t <= 1e5);
    t_valid = t(valid_mask);
    msd_valid = msd(valid_mask);
    log_t = log10(t_valid);
    log_msd = log10(msd_valid);
    
    % Determine regime
    if p < p_c_prime - 0.05
        regime = 'LIQUID';
    elseif abs(p - p_c_prime) < 0.05
        regime = 'CRITICAL';
    else
        regime = 'SOLID';
    end
    
    % Detect robust alpha
    [tau_cr, alpha, r_squared, start_idx, end_idx] = detect_robust_alpha(t, msd, p, target_alpha, window_sizes, r2_threshold);
    
    % Create figure
    figure('Position', [100, 100, 1400, 600]);
    
    % Main log-log plot
    subplot(1, 3, 1);
    plot(log_t, log_msd, 'w-', 'LineWidth', 2);
    hold on;
    
    if ~isnan(tau_cr)
        % Highlight the detected linear region
        t_linear = log_t(start_idx:end_idx);
        msd_linear = log_msd(start_idx:end_idx);
        plot(t_linear, msd_linear, 'g-', 'LineWidth', 3);
        
        % Plot fitted line
        p_fit = polyfit(t_linear, msd_linear, 1);
        y_fit = polyval(p_fit, t_linear);
        plot(t_linear, y_fit, 'y--', 'LineWidth', 2);
        
        % Mark crossover point
        plot(log_t(end_idx), log_msd(end_idx), 'wo', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        
        % Add expected α = 1 line
        expected_line = log_t + (log_msd(1) - log_t(1));
        plot(log_t, expected_line, 'k:', 'LineWidth', 1);%alpha(0.5)
        
        legend('MSD', 'Linear region', 'Fit', 'Crossover point', 'Expected α=1', 'Location', 'best');
    end
    
    xlabel('log_{10}(t)');
    ylabel('log_{10}(MSD)');
    title(sprintf('p = %.4f (%s) - Robust α Detection', p, regime));
    grid on;
    
    % Time domain plot
    subplot(1, 3, 2);
    loglog(t_valid, msd_valid, 'b-', 'LineWidth', 2);
    hold on;
    
    if ~isnan(tau_cr)
        xline(tau_cr, 'r--', 'LineWidth', 2, 'Label', sprintf('τ_cr = %.0f', tau_cr));
        xline(t_valid(start_idx), 'g--', 'LineWidth', 2, 'Label', sprintf('Start = %.0f', t_valid(start_idx)));
    end
    
    xlabel('Time t');
    ylabel('MSD');
    title('Time Domain');
    grid on;
    
    % Alpha vs window position
    subplot(1, 3, 3);
    if ~isnan(tau_cr)
        % Calculate alpha for different window positions
        window_size = end_idx - start_idx + 1;
        alphas = [];
        r2s = [];
        positions = [];
        
        for pos = window_size:length(log_t)
            t_window = log_t(pos-window_size+1:pos);
            msd_window = log_msd(pos-window_size+1:pos);
            
            p_fit = polyfit(t_window, msd_window, 1);
            alpha_fit = p_fit(1);
            y_fit = polyval(p_fit, t_window);
            
            ss_res = sum((msd_window - y_fit).^2);
            ss_tot = sum((msd_window - mean(msd_window)).^2);
            r2 = 1 - ss_res/ss_tot;
            
            alphas = [alphas, alpha_fit];
            r2s = [r2s, r2];
            positions = [positions, pos];
        end
        
        yyaxis left;
        plot(positions, alphas, 'b-', 'LineWidth', 2);
        ylabel('α');
        yline(double(target_alpha), 'k--');%alpha(0.5)
        
        yyaxis right;
        plot(positions, r2s, 'r-', 'LineWidth', 2);
        ylabel('R²');
        yline(r2_threshold, 'r--');%alpha(0.5)
        
        xlabel('Window end position');
        title(sprintf('α and R² vs Window Position (size = %d)', window_size));
        grid on;
        
        % Mark the selected position
        xline(end_idx, 'g--', 'LineWidth', 2);
    end
    
    sgtitle(sprintf('Robust Alpha Detection: p = %.4f (%s)', p, regime));
    
    % % Save figure
    % filename = sprintf('robust_alpha_p%.4f.png', p);
    % saveas(gcf, filename);
    % fprintf('Saved: %s\n', filename);

    pause(1)
    
    close(gcf);
end

%% Save results
fprintf('\n=== SAVING RESULTS ===\n');

% Create results table
if ~isempty(results.p)
    results_table = table(results.p', results.regime', results.tau_cr', results.alpha', ...
                         results.r_squared', results.window_size', results.start_idx', results.end_idx', ...
                         'VariableNames', {'p', 'regime', 'tau_cr', 'alpha', 'r_squared', 'window_size', 'start_idx', 'end_idx'});
    
    % Save to file
    writetable(results_table, 'robust_alpha_results.csv');
    fprintf('Results saved to: robust_alpha_results.csv\n');
    
    %% Display summary
    fprintf('\n=== SUMMARY ===\n');
    fprintf('Total p-values analyzed: %d\n', length(sorted_p));
    fprintf('Successful detections: %d\n', height(results_table));
    
    fprintf('\nτ_cr statistics:\n');
    fprintf('  Mean: %.0f\n', mean(results_table.tau_cr));
    fprintf('  Median: %.0f\n', median(results_table.tau_cr));
    fprintf('  Range: %.0f - %.0f\n', min(results_table.tau_cr), max(results_table.tau_cr));
    
    fprintf('\nα statistics:\n');
    fprintf('  Mean: %.3f\n', mean(results_table.alpha));
    fprintf('  Median: %.3f\n', median(results_table.alpha));
    fprintf('  Range: %.3f - %.3f\n', min(results_table.alpha), max(results_table.alpha));
    
    fprintf('\nR² statistics:\n');
    fprintf('  Mean: %.3f\n', mean(results_table.r_squared));
    fprintf('  Median: %.3f\n', median(results_table.r_squared));
    fprintf('  Range: %.3f - %.3f\n', min(results_table.r_squared), max(results_table.r_squared));
    
    %% Create summary plot
    figure('Position', [200, 200, 1200, 400]);
    
    % τ_cr vs p
    subplot(1, 3, 1);
    colors = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, {'blue', 'red', 'green'});
    for regime = unique(results_table.regime)
        mask = strcmp(results_table.regime, regime);
        scatter(results_table.p(mask), results_table.tau_cr(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('τ_cr');
    title('τ_cr vs p');
    legend('Location', 'best');
    set(gca, 'YScale', 'log');
    grid on;
    
    % α vs p
    subplot(1, 3, 2);
    for regime = unique(results_table.regime)
        mask = strcmp(results_table.regime, regime);
        scatter(results_table.p(mask), results_table.alpha(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('α');
    title('α vs p');
    legend('Location', 'best');
    yline(target_alpha, 'k--', 'Alpha', 0.5);
    grid on;
    
    % R² vs p
    subplot(1, 3, 3);
    for regime = unique(results_table.regime)
        mask = strcmp(results_table.regime, regime);
        scatter(results_table.p(mask), results_table.r_squared(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('R²');
    title('R² vs p');
    legend('Location', 'best');
    yline(r2_threshold, 'r--', 'Alpha', 0.5);
    grid on;
    
    sgtitle('Robust Alpha Detection Results');
    
    % Save summary plot
    saveas(gcf, 'robust_alpha_summary.png');
    fprintf('Summary plot saved to: robust_alpha_summary.png\n');
else
    fprintf('No successful detections found.\n');
end

fprintf('\nAnalysis complete!\n'); 


%% Robust Alpha Detection Function
function [tau_cr, alpha, r_squared, best_start_idx, best_end_idx] = detect_robust_alpha(t, msd, p_value, target_alpha, window_sizes, r2_threshold)
    % Filter valid data
    valid_mask = isfinite(msd) & (msd > 0) & (t <= 1e4);
    t_valid = t(valid_mask);
    msd_valid = msd(valid_mask);
    
    if length(t_valid) < max(window_sizes)
        tau_cr = NaN;
        alpha = NaN;
        r_squared = NaN;
        best_start_idx = NaN;
        best_end_idx = NaN;
        return;
    end
    
    log_t = log10(t_valid);
    log_msd = log10(msd_valid);
    
    best_r2 = 0;
    best_alpha = NaN;
    best_start_idx = NaN;
    best_end_idx = NaN;
    
    % Try different window sizes
    for window_size = window_sizes
        if length(log_t) < window_size
            continue;
        end
        
        % Work backwards from the end
        for end_idx = length(log_t):-1:window_size
            start_idx = end_idx - window_size + 1;
            
            % Extract window
            t_window = log_t(start_idx:end_idx);
            msd_window = log_msd(start_idx:end_idx);
            
            % Fit linear relationship
            p_fit = polyfit(t_window, msd_window, 1);
            alpha_fit = p_fit(1);
            y_fit = polyval(p_fit, t_window);
            
            % Calculate R²
            ss_res = sum((msd_window - y_fit).^2);
            ss_tot = sum((msd_window - mean(msd_window)).^2);
            r2 = 1 - ss_res/ss_tot;
            
            % Check if this is a good fit for target alpha
            alpha_deviation = abs(alpha_fit - target_alpha);
            
            % Criteria: good R² and alpha close to target
            if r2 > r2_threshold && alpha_deviation < 0.2 && r2 > best_r2
                best_r2 = r2;
                best_alpha = alpha_fit;
                best_start_idx = start_idx;
                best_end_idx = end_idx;
            end
        end
    end
    
    if ~isnan(best_start_idx)
        tau_cr = t_valid(best_end_idx);
        alpha = best_alpha;
        r_squared = best_r2;
    else
        tau_cr = NaN;
        alpha = NaN;
        r_squared = NaN;
    end
end