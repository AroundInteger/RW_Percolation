%% Interactive Anomalous Diffusion Region Detection
% This script allows manual selection of AD regions for robust τ_cr detection
% Author: AI Assistant
% Date: 2024

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
        p_str = col_name(5:end); % Remove 'MSD_' prefix
        p_values = [p_values, str2double(p_str)];
        msd_data = [msd_data, data.(col_name)];
    end
end

% Create time array
t = (1:height(data))';
log_t = log10(t);

fprintf('Loaded %d p-values\n', length(p_values));

%% Interactive AD Region Selection
fprintf('\n=== INTERACTIVE AD REGION DETECTION ===\n');
fprintf('Instructions:\n');
fprintf('1. For each p-value, you will see the log-log plot\n');
fprintf('2. Click to select the START of the AD region (green marker)\n');
fprintf('3. Click to select the END of the AD region (red marker)\n');
fprintf('4. Press Enter to continue to next p-value\n');
fprintf('5. Press ''q'' to quit early\n\n');

% Initialize results storage
results = struct();
results.p = [];
results.tau_cr = [];
results.tau_ad_start = [];
results.alpha = [];
results.r_squared = [];
results.ad_start_idx = [];
results.ad_end_idx = [];

% Sort p-values for systematic analysis
[sorted_p, sort_idx] = sort(p_values);

for i = 15:length(sorted_p)
    p = sorted_p(i);
    p_idx = sort_idx(i);
    
    % Get MSD data for this p-value
    msd = msd_data(:, p_idx);
    
    % Filter valid data
    valid_mask = isfinite(msd) & (msd > 0) & (t <= 1e4);
    t_valid = t(valid_mask);
    msd_valid = msd(valid_mask);
    log_t_valid = log10(t_valid);
    log_msd_valid = log10(msd_valid);
    
    if sum(valid_mask) < 50
        fprintf('Skipping p = %.4f (insufficient data)\n', p);
        continue;
    end
    
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
    
    % Create interactive plot
    figure('Position', [100, 100, 1200, 800]);
    
    % Main log-log plot
    subplot(2, 2, [1, 3]);
    plot(log_t_valid, log_msd_valid, 'b-', 'LineWidth', 2);
    hold on;
    
    % Add expected behavior lines
    if strcmp(regime, 'LIQUID')
        expected_alpha = 1.0;
        expected_line = log_t_valid + (log_msd_valid(1) - log_t_valid(1));
        plot(log_t_valid, expected_line, 'k--', 'LineWidth', 1);alpha(0.5)
    elseif strcmp(regime, 'CRITICAL')
        expected_alpha = 0.53;
        expected_line = expected_alpha * log_t_valid + (log_msd_valid(1) - expected_alpha * log_t_valid(1));
        plot(log_t_valid, expected_line, 'k--', 'LineWidth', 1);alpha(0.5)
    else % SOLID
        expected_alpha = 0.0;
        expected_line = log_msd_valid(1) * ones(size(log_t_valid));
        plot(log_t_valid, expected_line, 'k--', 'LineWidth', 1);alpha(0.5)
    end
    
    % Add boundary lines from direct method
    y1 = log_t_valid - 0.87;
    y2 = 0.4 * log_t_valid + 0.16;
    plot(log_t_valid, y1, 'r:', 'LineWidth', 1);alpha(0.7)
    plot(log_t_valid, y2, 'g:', 'LineWidth', 1);alpha(0.7)
    
    xlabel('log_{10}(t)');
    ylabel('log_{10}(MSD)');
    title(sprintf('p = %.4f (%s) - Click to select AD region', p, regime));
    grid on;
    
    % Add legend
    legend('MSD', 'Expected α', 'y1 boundary', 'y2 boundary', 'Location', 'best');
    
    % Time domain plot
    subplot(2, 2, 2);
    loglog(t_valid, msd_valid, 'b-', 'LineWidth', 2);
    xlabel('Time t');
    ylabel('MSD');
    title('Time Domain');
    grid on;
    
    % Instructions
    subplot(2, 2, 4);
    text(0.1, 0.8, 'Instructions:', 'FontSize', 12, 'FontWeight', 'bold');
    text(0.1, 0.7, '1. Click to select AD START (green)', 'FontSize', 10);
    text(0.1, 0.6, '2. Click to select AD END (red)', 'FontSize', 10);
    text(0.1, 0.5, '3. Press Enter to continue', 'FontSize', 10);
    text(0.1, 0.4, '4. Press ''q'' to quit', 'FontSize', 10);
    text(0.1, 0.3, '5. Press ''r'' to reset', 'FontSize', 10);
    axis off;
    
    % Interactive point selection
    ad_start_idx = [];
    ad_end_idx = [];
    selection_complete = false;
    
    while ~selection_complete
        try
            [x_click, y_click, button] = ginput(1);
            
            if isempty(x_click)
                % User pressed Enter
                if ~isempty(ad_start_idx) && ~isempty(ad_end_idx)
                    selection_complete = true;
                else
                    fprintf('Please select both start and end points\n');
                end
                continue;
            end
            
            % Find closest point in data
            [~, closest_idx] = min(abs(log_t_valid - x_click));
            
            if isempty(ad_start_idx)
                % Select AD start point
                ad_start_idx = closest_idx;
                subplot(2, 2, [1, 3]);
                plot(log_t_valid(closest_idx), log_msd_valid(closest_idx), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
                fprintf('AD start selected: t = %.0f, log(t) = %.3f\n', t_valid(closest_idx), log_t_valid(closest_idx));
                
            elseif isempty(ad_end_idx)
                % Select AD end point
                if closest_idx <= ad_start_idx
                    fprintf('End point must be after start point. Try again.\n');
                    continue;
                end
                ad_end_idx = closest_idx;
                subplot(2, 2, [1, 3]);
                plot(log_t_valid(closest_idx), log_msd_valid(closest_idx), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
                fprintf('AD end selected: t = %.0f, log(t) = %.3f\n', t_valid(closest_idx), log_t_valid(closest_idx));
                
                % Fit line through AD region
                t_ad = log_t_valid(ad_start_idx:ad_end_idx);
                msd_ad = log_msd_valid(ad_start_idx:ad_end_idx);
                
                if length(t_ad) >= 3
                    p_fit = polyfit(t_ad, msd_ad, 1);
                    alpha = p_fit(1);
                    y_fit = polyval(p_fit, t_ad);
                    r_squared = 1 - sum((msd_ad - y_fit).^2) / sum((msd_ad - mean(msd_ad)).^2);
                    
                    % Plot fitted line
                    plot(t_ad, y_fit, 'y-', 'LineWidth', 2);
                    legend('MSD', 'Expected α', 'y1 boundary', 'y2 boundary', 'AD start', 'AD end', sprintf('Fit: α = %.3f', alpha), 'Location', 'best');
                    
                    % Mark τ_cr in time domain
                    subplot(2, 2, 2);
                    hold on;
                    tau_cr = t_valid(ad_end_idx);
                    tau_ad_start = t_valid(ad_start_idx);
                    xline(tau_cr, 'r--', 'LineWidth', 2, 'Label', sprintf('τ_cr = %.0f', tau_cr));
                    xline(tau_ad_start, 'g--', 'LineWidth', 2, 'Label', sprintf('AD start = %.0f', tau_ad_start));
                    
                    fprintf('AD region fitted: α = %.3f, R² = %.3f\n', alpha, r_squared);
                    fprintf('τ_cr = %.0f, AD start = %.0f\n', tau_cr, tau_ad_start);
                end
            end
            
        catch ME
            if strcmp(ME.message, 'User terminated ginput')
                fprintf('Analysis terminated by user\n');
                return;
            else
                fprintf('Error: %s\n', ME.message);
            end
        end
    end
    
    % Store results
    if ~isempty(ad_start_idx) && ~isempty(ad_end_idx)
        results.p = [results.p, p];
        results.tau_cr = [results.tau_cr, t_valid(ad_end_idx)];
        results.tau_ad_start = [results.tau_ad_start, t_valid(ad_start_idx)];
        results.ad_start_idx = [results.ad_start_idx, ad_start_idx];
        results.ad_end_idx = [results.ad_end_idx, ad_end_idx];
        
        if length(t_ad) >= 3
            results.alpha = [results.alpha, alpha];
            results.r_squared = [results.r_squared, r_squared];
        else
            results.alpha = [results.alpha, NaN];
            results.r_squared = [results.r_squared, NaN];
        end
        
        fprintf('Results saved for p = %.4f\n', p);
    end
    
    % Ask user if they want to continue
    fprintf('\nPress Enter to continue to next p-value, or ''q'' to quit...\n');
    input_str = input('', 's');
    if strcmpi(input_str, 'q')
        break;
    end
    
    close(gcf);
end

%% Save results
fprintf('\n=== SAVING RESULTS ===\n');

% Create results table
results_table = table(results.p', results.tau_cr', results.tau_ad_start', ...
                     results.alpha', results.r_squared', results.ad_start_idx', results.ad_end_idx', ...
                     'VariableNames', {'p', 'tau_cr', 'tau_ad_start', 'alpha', 'r_squared', 'ad_start_idx', 'ad_end_idx'});

% Add regime information
regime_labels = cell(height(results_table), 1);
for i = 1:height(results_table)
    p = results_table.p(i);
    if p < p_c_prime - 0.05
        regime_labels{i} = 'LIQUID';
    elseif abs(p - p_c_prime) < 0.05
        regime_labels{i} = 'CRITICAL';
    else
        regime_labels{i} = 'SOLID';
    end
end
results_table.regime = regime_labels;

% Save to file
writetable(results_table, 'interactive_ad_results.csv');
fprintf('Results saved to: interactive_ad_results.csv\n');

%% Display summary
fprintf('\n=== SUMMARY ===\n');
fprintf('Total p-values analyzed: %d\n', height(results_table));
fprintf('Successful detections: %d\n', sum(~isnan(results_table.alpha)));

if ~isempty(results_table)
    fprintf('\nτ_cr statistics:\n');
    fprintf('  Mean: %.0f\n', mean(results_table.tau_cr));
    fprintf('  Median: %.0f\n', median(results_table.tau_cr));
    fprintf('  Range: %.0f - %.0f\n', min(results_table.tau_cr), max(results_table.tau_cr));
    
    valid_alpha = results_table.alpha(~isnan(results_table.alpha));
    if ~isempty(valid_alpha)
        fprintf('\nα statistics:\n');
        fprintf('  Mean: %.3f\n', mean(valid_alpha));
        fprintf('  Median: %.3f\n', median(valid_alpha));
        fprintf('  Range: %.3f - %.3f\n', min(valid_alpha), max(valid_alpha));
    end
end

%% Create summary plot
if ~isempty(results_table)
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
        mask = strcmp(results_table.regime, regime) & ~isnan(results_table.alpha);
        if any(mask)
            scatter(results_table.p(mask), results_table.alpha(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
            hold on;
        end
    end
    xlabel('p');
    ylabel('α');
    title('α vs p');
    legend('Location', 'best');
    grid on;
    
    % R² vs p
    subplot(1, 3, 3);
    for regime = unique(results_table.regime)
        mask = strcmp(results_table.regime, regime) & ~isnan(results_table.r_squared);
        if any(mask)
            scatter(results_table.p(mask), results_table.r_squared(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
            hold on;
        end
    end
    xlabel('p');
    ylabel('R²');
    title('R² vs p');
    legend('Location', 'best');
    grid on;
    
    sgtitle('Interactive AD Region Detection Results');
    
    % Save summary plot
    saveas(gcf, 'interactive_ad_summary.png');
    fprintf('Summary plot saved to: interactive_ad_summary.png\n');
end

fprintf('\nAnalysis complete!\n'); 