%% Optimized Alpha Detector - Maximize Linear Region, Minimize α Deviation
% This script finds the longest linear region working backwards while
% minimizing the deviation from theoretical α values for each regime.

clear; clc; close all;

%% Load data
fprintf('Loading MSD data...\n');
%data = readtable('p_output.csv');
data = readtable('p_output_NEW34.csv');
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

%% Get Theoretical Alpha Function
function theoretical_alpha = get_theoretical_alpha(p_value)
    p_c_prime = 0.6884;
    
    if p_value < p_c_prime - 0.05
        theoretical_alpha = 1.0;  % Liquid regime
    elseif abs(p_value - p_c_prime) < 0.05
        theoretical_alpha = 0.53; % Critical regime
    else
        theoretical_alpha = 0.0;  % Solid regime
    end
end



%% Analyze all p-values
fprintf('\n=== OPTIMIZED ALPHA DETECTION ===\n');
fprintf('Strategy: Maximize linear region length, minimize α deviation from theory\n\n');

% Parameters
window_sizes = [100, 150, 200, 250, 300, 400, 500];  % Extended window sizes
r2_threshold = 0.90;  % Slightly lower threshold for more flexibility
alpha_weight = 1.0;   % Weight for α deviation in loss function
length_weight = 0.5;  % Weight for region length in loss function

% Initialize results
results = struct();
results.p = [];
results.regime = {};
results.tau_cr = [];
results.alpha = [];
results.theoretical_alpha = [];
results.alpha_deviation = [];
results.r_squared = [];
results.window_size = [];
results.start_idx = [];
results.end_idx = [];
results.loss_value = [];

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
    elseif abs(p - p_c_prime) <= 0.05
        regime = 'CRITICAL';
    else
        regime = 'SOLID';
    end
    
    fprintf('Analyzing p = %.4f (%s)...\n', p, regime);
    
    % Detect optimized alpha
    [tau_cr, alpha, r_squared, start_idx, end_idx, loss_value] = detect_optimized_alpha(t, msd, p, window_sizes, r2_threshold, alpha_weight, length_weight);
    
    if ~isnan(tau_cr)
        % Calculate additional metrics
        theoretical_alpha = get_theoretical_alpha(p);
        alpha_deviation = abs(alpha - theoretical_alpha);
        window_size_used = end_idx - start_idx + 1;
        
        % Store results
        results.p = [results.p, p];
        results.regime{end+1} = regime;
        results.tau_cr = [results.tau_cr, tau_cr];
        results.alpha = [results.alpha, alpha];
        results.theoretical_alpha = [results.theoretical_alpha, theoretical_alpha];
        results.alpha_deviation = [results.alpha_deviation, alpha_deviation];
        results.r_squared = [results.r_squared, r_squared];
        results.window_size = [results.window_size, window_size_used];
        results.start_idx = [results.start_idx, start_idx];
        results.end_idx = [results.end_idx, end_idx];
        results.loss_value = [results.loss_value, loss_value];
        
        fprintf('  τ_cr = %.0f, α = %.3f (theoretical: %.2f), R² = %.3f, window = %d, loss = %.3f\n', ...
                tau_cr, alpha, theoretical_alpha, r_squared, window_size_used, loss_value);
    else
        fprintf('  No suitable linear region found\n');
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
    valid_mask = isfinite(msd) & (msd > 0) & (t <= 1e6);
    t_valid = t(valid_mask);
    msd_valid = msd(valid_mask);
    log_t = log10(t_valid);
    log_msd = log10(msd_valid);
    
    % Determine regime
    if p < p_c_prime - 0.05
        regime = 'LIQUID';
    elseif abs(p - p_c_prime) <= 0.05
        regime = 'CRITICAL';
    else
        regime = 'SOLID';
    end
    
    % Detect optimized alpha
    [tau_cr, alpha, r_squared, start_idx, end_idx, loss_value] = detect_optimized_alpha(t, msd, p, window_sizes, r2_threshold, alpha_weight, length_weight);
    
    % Create figure
    figure('Position', [100, 100, 1400, 600]);
    
    % Main log-log plot
    subplot(1, 3, 1);
    plot(log_t, log_msd, 'b-', 'LineWidth', 2);
    hold on;
    
    if ~isnan(tau_cr)
        % Highlight the detected linear region
        t_linear = log_t(start_idx:end_idx);
        msd_linear = log_msd(start_idx:end_idx);
        plot(t_linear, msd_linear, 'r-', 'LineWidth', 3);
        
        % Plot fitted line
        p_fit = polyfit(t_linear, msd_linear, 1);
        y_fit = polyval(p_fit, t_linear);
        plot(t_linear, y_fit, 'g--', 'LineWidth', 2);
        
        % Mark crossover point
        plot(log_t(end_idx), log_msd(end_idx), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        
        % Add theoretical α line
        theoretical_alpha = get_theoretical_alpha(p);
        expected_line = theoretical_alpha * log_t + (log_msd(1) - theoretical_alpha * log_t(1));
        plot(log_t, expected_line, 'k:', 'LineWidth', 1);
        
        legend('MSD', 'Linear region', 'Fit', 'Crossover point', sprintf('Theoretical α=%.2f', theoretical_alpha), 'Location', 'best');
    end
    
    xlabel('log_{10}(t)');
    ylabel('log_{10}(MSD)');
    title(sprintf('p = %.4f (%s) - Optimized α Detection', p, regime));
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
    
    % Loss function analysis
    subplot(1, 3, 3);
    if ~isnan(tau_cr)
        % Calculate loss for different window positions
        window_size = end_idx - start_idx + 1;
        losses = [];
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
            
            if r2 > r2_threshold
                alpha_deviation = abs(alpha_fit - theoretical_alpha);
                length_loss = 1 / window_size;
                loss = alpha_weight * alpha_deviation + length_weight * length_loss;
                
                losses = [losses, loss];
                alphas = [alphas, alpha_fit];
                r2s = [r2s, r2];
                positions = [positions, pos];
            end
        end
        
        yyaxis left;
        plot(positions, losses, 'b-', 'LineWidth', 2);
        ylabel('Loss');
        
        yyaxis right;
        plot(positions, alphas, 'r-', 'LineWidth', 2);
        ylabel('α');
        yline(theoretical_alpha, 'r--');
        
        xlabel('Window end position');
        title(sprintf('Loss and α vs Position (size = %d)', window_size));
        grid on;
        
        % Mark the selected position
        xline(end_idx, 'g--', 'LineWidth', 2);
    end
    
    sgtitle(sprintf('Optimized Alpha Detection: p = %.4f (%s)', p, regime));
    
    % Save figure
    filename = sprintf('optimized_alpha_p%.4f.png', p);
    saveas(gcf, filename);
    fprintf('Saved: %s\n', filename);
    
    close(gcf);
end

%% Save results
fprintf('\n=== SAVING RESULTS ===\n');

% Create results table
if ~isempty(results.p)
    results_table = table(results.p', results.regime', results.tau_cr', results.alpha', ...
                         results.theoretical_alpha', results.alpha_deviation', results.r_squared', ...
                         results.window_size', results.start_idx', results.end_idx', results.loss_value', ...
                         'VariableNames', {'p', 'regime', 'tau_cr', 'alpha', 'theoretical_alpha', ...
                         'alpha_deviation', 'r_squared', 'window_size', 'start_idx', 'end_idx', 'loss_value'});
    
    % Save to file
    %writetable(results_table, 'optimized_alpha_results.csv');
    fprintf('Results saved to: optimized_alpha_results.csv\n');
    
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
    
    fprintf('\nα deviation from theory:\n');
    fprintf('  Mean: %.3f\n', mean(results_table.alpha_deviation));
    fprintf('  Median: %.3f\n', median(results_table.alpha_deviation));
    fprintf('  Range: %.3f - %.3f\n', min(results_table.alpha_deviation), max(results_table.alpha_deviation));
    
    fprintf('\nR² statistics:\n');
    fprintf('  Mean: %.3f\n', mean(results_table.r_squared));
    fprintf('  Median: %.3f\n', median(results_table.r_squared));
    fprintf('  Range: %.3f - %.3f\n', min(results_table.r_squared), max(results_table.r_squared));
    
    %% Create summary plot
    figure('Position', [200, 200, 1200, 800]);
    
    % Ensure regime data is in cell array format
    regime_data = results_table.regime;
    
    % Convert to cell array if needed
    if ~iscell(regime_data)
        regime_data = cellstr(regime_data);
    end
    
    % τ_cr vs p
    subplot(2, 3, 1);
    colors = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, {'blue', 'red', 'green'});
    unique_regimes = unique(regime_data);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
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
    subplot(2, 3, 2);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        scatter(results_table.p(mask), results_table.alpha(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('α');
    title('α vs p');
    legend('Location', 'best');
    grid on;
    
    % α deviation vs p
    subplot(2, 3, 3);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        scatter(results_table.p(mask), results_table.alpha_deviation(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('|α - α_theoretical|');
    title('α Deviation vs p');
    legend('Location', 'best');
    grid on;
    
    % R² vs p
    subplot(2, 3, 4);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        scatter(results_table.p(mask), results_table.r_squared(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('R²');
    title('R² vs p');
    legend('Location', 'best');
    grid on;
    
    % Window size vs p
    subplot(2, 3, 5);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        scatter(results_table.p(mask), results_table.window_size(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('Window Size');
    title('Window Size vs p');
    legend('Location', 'best');
    grid on;
    
    % Loss vs p
    subplot(2, 3, 6);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        scatter(results_table.p(mask), results_table.loss_value(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('Loss Value');
    title('Loss vs p');
    legend('Location', 'best');
    grid on;
    
    sgtitle('Optimized Alpha Detection Results');
    
    % Save summary plot
    %saveas(gcf, 'optimized_alpha_summary.png');
    fprintf('Summary plot saved to: optimized_alpha_summary.png\n');
else
    fprintf('No successful detections found.\n');
end

fprintf('\nAnalysis complete!\n'); 

%% Optimized Alpha Detection Function
function [tau_cr, alpha, r_squared, best_start_idx, best_end_idx, loss_value] = detect_optimized_alpha(t, msd, p_value, window_sizes, r2_threshold, alpha_weight, length_weight)
    % Filter valid data - use full range
    valid_mask = isfinite(msd) & (msd > 0) & (t <= 1e6);
    t_valid = t(valid_mask);
    msd_valid = msd(valid_mask);
    
    if length(t_valid) < max(window_sizes)
        tau_cr = NaN;
        alpha = NaN;
        r_squared = NaN;
        best_start_idx = NaN;
        best_end_idx = NaN;
        loss_value = NaN;
        return;
    end
    
    log_t = log10(t_valid);
    log_msd = log10(msd_valid);
    
    % Get theoretical alpha for this p-value
    theoretical_alpha = get_theoretical_alpha(p_value);
    
    best_loss = inf;
    best_alpha = NaN;
    best_r2 = 0;
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
            
            % Only consider high-quality fits
            if r2 > r2_threshold
                % Calculate loss function components
                alpha_deviation = abs(alpha_fit - theoretical_alpha);
                region_length = end_idx - start_idx + 1;
                
                % Normalize components
                alpha_loss = alpha_deviation;  % Already normalized (0 to ~2 range)
                length_loss = 1 / region_length;  % Normalize to 0-1 range
                
                % Combined loss function
                loss = alpha_weight * alpha_loss + length_weight * length_loss;
                
                % Update best if loss is lower
                if loss < best_loss
                    best_loss = loss;
                    best_alpha = alpha_fit;
                    best_r2 = r2;
                    best_start_idx = start_idx;
                    best_end_idx = end_idx;
                end
            end
        end
    end
    
    if ~isnan(best_start_idx)
        tau_cr = t_valid(best_end_idx);
        alpha = best_alpha;
        r_squared = best_r2;
        loss_value = best_loss;
    else
        tau_cr = NaN;
        alpha = NaN;
        r_squared = NaN;
        loss_value = NaN;
    end
end