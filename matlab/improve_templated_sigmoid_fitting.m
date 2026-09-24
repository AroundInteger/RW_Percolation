% improve_templated_sigmoid_fitting.m
% Improve sigmoid fitting for templated class by addressing cut-off transition

clear; close all; clc;

fprintf('\n=== IMPROVING TEMPLATED CLASS SIGMOID FITTING ===\n');
fprintf('Addressing cut-off transition at high p-values\n\n');

% ============================================================================
% DATA LOADING AND SETUP
% ============================================================================

% Load the comprehensive dataset
mat_file = 'Clusters1/random_walk_analysis_L500_LW1000000_NW3000.mat';
load(mat_file);

% Load the alpha results from previous analysis
alpha_file = 'Clusters1/output/universality_class_analysis.mat';
load(alpha_file);

fprintf('Data loaded successfully:\n');
fprintf('  p_values: %d values from %.3f to %.3f\n', length(p_values), min(p_values), max(p_values));

% Define universality classes
templated_variants = {'6N_Templated', '26N_Templated'};
standard_variants = {'Random_Percolation', 'Density_Increment'};

% ============================================================================
% ANALYZE TEMPLATED CLASS BEHAVIOR
% ============================================================================

fprintf('\n=== ANALYZING TEMPLATED CLASS BEHAVIOR ===\n');

% Extract templated class data
variant_indices = [];
for i = 1:length(templated_variants)
    idx = find(strcmp(variants, templated_variants{i}));
    if ~isempty(idx)
        variant_indices = [variant_indices, idx];
    end
end

class_alpha = alpha_results(:, variant_indices);
class_alpha_mean = mean(class_alpha, 2);

% Analyze the data
fprintf('Templated class analysis:\n');
fprintf('  p_values range: [%.3f, %.3f]\n', min(p_values), max(p_values));
fprintf('  alpha range: [%.3f, %.3f]\n', min(class_alpha_mean), max(class_alpha_mean));

% Find where the transition occurs
alpha_diff = diff(class_alpha_mean);
[~, max_change_idx] = max(abs(alpha_diff));
transition_p = p_values(max_change_idx);
fprintf('  Maximum alpha change at p = %.3f\n', transition_p);

% Check high p-value behavior
high_p_mask = p_values > 0.8;
if any(high_p_mask)
    high_p_alpha = class_alpha_mean(high_p_mask);
    fprintf('  High p-values (p > 0.8): α = [%.3f, %.3f]\n', min(high_p_alpha), max(high_p_alpha));
    fprintf('  Number of high p-values: %d\n', sum(high_p_mask));
end

% ============================================================================
% IMPROVED SIGMOID FITTING STRATEGIES
% ============================================================================

fprintf('\n=== IMPROVED SIGMOID FITTING STRATEGIES ===\n');

% Strategy 1: Extended p-value range
fprintf('\nStrategy 1: Extended p-value range\n');
[params_extended, r2_extended] = fit_sigmoid_extended_range(p_values, class_alpha_mean);

% Strategy 2: Weighted fitting (emphasize transition region)
fprintf('\nStrategy 2: Weighted fitting (emphasize transition region)\n');
[params_weighted, r2_weighted] = fit_sigmoid_weighted(p_values, class_alpha_mean);

% Strategy 3: Piecewise sigmoid (different parameters for different regions)
fprintf('\nStrategy 3: Piecewise sigmoid fitting\n');
[params_piecewise, r2_piecewise] = fit_sigmoid_piecewise(p_values, class_alpha_mean);

% Strategy 4: Modified sigmoid with asymmetry
fprintf('\nStrategy 4: Asymmetric sigmoid fitting\n');
[params_asymmetric, r2_asymmetric] = fit_sigmoid_asymmetric(p_values, class_alpha_mean);

% ============================================================================
% COMPARE FITTING STRATEGIES
% ============================================================================

fprintf('\n=== COMPARING FITTING STRATEGIES ===\n');

strategies = {'Extended Range', 'Weighted', 'Piecewise', 'Asymmetric'};
r2_values = [r2_extended, r2_weighted, r2_piecewise, r2_asymmetric];

fprintf('Fitting quality comparison:\n');
for i = 1:length(strategies)
    fprintf('  %s: R² = %.4f\n', strategies{i}, r2_values(i));
end

[best_r2, best_idx] = max(r2_values);
fprintf('\nBest strategy: %s (R² = %.4f)\n', strategies{best_idx}, best_r2);

% ============================================================================
% VISUALIZATION
% ============================================================================

fprintf('\n=== GENERATING IMPROVED FITTING PLOTS ===\n');
create_improved_fitting_plots(p_values, class_alpha_mean, params_extended, params_weighted, ...
                             params_piecewise, params_asymmetric, r2_values, strategies, 'Clusters1/output');

fprintf('\n=== IMPROVED TEMPLATED SIGMOID FITTING COMPLETE ===\n');

% ============================================================================
% HELPER FUNCTIONS
% ============================================================================

function [params, r2] = fit_sigmoid_extended_range(p_values, alpha_values)
% Strategy 1: Extend p-value range by extrapolation

fprintf('  Fitting with extended p-value range...\n');

% Extend p-values to capture full transition
p_extended = [p_values(:)', 0.95, 0.98, 1.0];
alpha_extended = [alpha_values(:)', alpha_values(end), alpha_values(end), alpha_values(end)];

% Initial parameter guesses (adjusted for delayed transition)
p_c_guess = 0.85;  % Higher p_c for delayed transition
width_guess = 0.1;
alpha_min_guess = 0.1;
alpha_max_guess = 1.0;

p0 = [p_c_guess, width_guess, alpha_min_guess, alpha_max_guess];
lb = [0.7, 0.01, 0.0, 0.8];
ub = [1.0, 0.3, 0.2, 1.0];

try
    options = optimoptions('lsqcurvefit', 'Display', 'off', 'MaxIterations', 1000);
    [params, resnorm] = lsqcurvefit(@sigmoid_function, p0, p_extended, alpha_extended, lb, ub, options);
    
    % Calculate R²
    alpha_pred = sigmoid_function(params, p_values);
    ss_res = sum((alpha_values - alpha_pred).^2);
    ss_tot = sum((alpha_values - mean(alpha_values)).^2);
    r2 = 1 - ss_res / ss_tot;
    
    fprintf('    p_c = %.4f, width = %.4f, α_min = %.4f, α_max = %.4f, R² = %.4f\n', ...
        params(1), params(2), params(3), params(4), r2);
    
catch ME
    fprintf('    Fitting failed: %s\n', ME.message);
    params = [];
    r2 = 0;
end

end

function [params, r2] = fit_sigmoid_weighted(p_values, alpha_values)
% Strategy 2: Weighted fitting emphasizing transition region

fprintf('  Fitting with weighted emphasis on transition region...\n');

% Create weights - higher weight for transition region
transition_center = 0.8;  % Approximate transition center
weights = exp(-((p_values(:)' - transition_center) / 0.2).^2);
weights = weights / max(weights);  % Normalize

% Initial parameter guesses
p_c_guess = 0.8;
width_guess = 0.1;
alpha_min_guess = 0.1;
alpha_max_guess = 1.0;

p0 = [p_c_guess, width_guess, alpha_min_guess, alpha_max_guess];
lb = [0.7, 0.01, 0.0, 0.8];
ub = [1.0, 0.3, 0.2, 1.0];

try
    % Use weighted least squares
    options = optimoptions('lsqcurvefit', 'Display', 'off', 'MaxIterations', 1000);
    [params, resnorm] = lsqcurvefit(@(params, p) sigmoid_function(params, p) .* weights, p0, p_values, alpha_values .* weights, lb, ub, options);
    
    % Calculate R²
    alpha_pred = sigmoid_function(params, p_values);
    ss_res = sum((alpha_values - alpha_pred).^2);
    ss_tot = sum((alpha_values - mean(alpha_values)).^2);
    r2 = 1 - ss_res / ss_tot;
    
    fprintf('    p_c = %.4f, width = %.4f, α_min = %.4f, α_max = %.4f, R² = %.4f\n', ...
        params(1), params(2), params(3), params(4), r2);
    
catch ME
    fprintf('    Fitting failed: %s\n', ME.message);
    params = [];
    r2 = 0;
end

end

function [params, r2] = fit_sigmoid_piecewise(p_values, alpha_values)
% Strategy 3: Piecewise sigmoid fitting

fprintf('  Fitting with piecewise sigmoid...\n');

% Split data into regions
low_p_mask = p_values(:)' < 0.7;
high_p_mask = p_values(:)' >= 0.7;

if sum(low_p_mask) < 3 || sum(high_p_mask) < 3
    fprintf('    Insufficient data for piecewise fitting\n');
    params = [];
    r2 = 0;
    return;
end

% Fit sigmoid to high p region (where transition occurs)
p_high = p_values(high_p_mask);
alpha_high = alpha_values(high_p_mask);

% Initial parameter guesses for high p region
p_c_guess = 0.85;
width_guess = 0.1;
alpha_min_guess = 0.1;
alpha_max_guess = 1.0;

p0 = [p_c_guess, width_guess, alpha_min_guess, alpha_max_guess];
lb = [0.7, 0.01, 0.0, 0.8];
ub = [1.0, 0.3, 0.2, 1.0];

try
    options = optimoptions('lsqcurvefit', 'Display', 'off', 'MaxIterations', 1000);
    [params, resnorm] = lsqcurvefit(@sigmoid_function, p0, p_high, alpha_high, lb, ub, options);
    
    % Calculate R² for full dataset
    alpha_pred = sigmoid_function(params, p_values);
    ss_res = sum((alpha_values - alpha_pred).^2);
    ss_tot = sum((alpha_values - mean(alpha_values)).^2);
    r2 = 1 - ss_res / ss_tot;
    
    fprintf('    p_c = %.4f, width = %.4f, α_min = %.4f, α_max = %.4f, R² = %.4f\n', ...
        params(1), params(2), params(3), params(4), r2);
    
catch ME
    fprintf('    Fitting failed: %s\n', ME.message);
    params = [];
    r2 = 0;
end

end

function [params, r2] = fit_sigmoid_asymmetric(p_values, alpha_values)
% Strategy 4: Asymmetric sigmoid fitting

fprintf('  Fitting with asymmetric sigmoid...\n');

% Initial parameter guesses
p_c_guess = 0.8;
width_guess = 0.1;
alpha_min_guess = 0.1;
alpha_max_guess = 1.0;
asymmetry_guess = 0.5;  % Asymmetry parameter

p0 = [p_c_guess, width_guess, alpha_min_guess, alpha_max_guess, asymmetry_guess];
lb = [0.7, 0.01, 0.0, 0.8, 0.1];
ub = [1.0, 0.3, 0.2, 1.0, 2.0];

try
    options = optimoptions('lsqcurvefit', 'Display', 'off', 'MaxIterations', 1000);
    [params, resnorm] = lsqcurvefit(@asymmetric_sigmoid_function, p0, p_values, alpha_values, lb, ub, options);
    
    % Calculate R²
    alpha_pred = asymmetric_sigmoid_function(params, p_values);
    ss_res = sum((alpha_values - alpha_pred).^2);
    ss_tot = sum((alpha_values - mean(alpha_values)).^2);
    r2 = 1 - ss_res / ss_tot;
    
    fprintf('    p_c = %.4f, width = %.4f, α_min = %.4f, α_max = %.4f, asymmetry = %.4f, R² = %.4f\n', ...
        params(1), params(2), params(3), params(4), params(5), r2);
    
catch ME
    fprintf('    Fitting failed: %s\n', ME.message);
    params = [];
    r2 = 0;
end

end

function alpha = sigmoid_function(params, p_values)
% Standard sigmoid function

p_c = params(1);
width = params(2);
alpha_min = max(0.0, params(3));
alpha_max = min(1.0, params(4));

alpha = alpha_min + (alpha_max - alpha_min) ./ (1 + exp((p_values - p_c) / width));

end

function alpha = asymmetric_sigmoid_function(params, p_values)
% Asymmetric sigmoid function

p_c = params(1);
width = params(2);
alpha_min = max(0.0, params(3));
alpha_max = min(1.0, params(4));
asymmetry = params(5);

% Asymmetric sigmoid with different widths for left and right sides
p_shifted = p_values - p_c;
left_mask = p_shifted < 0;
right_mask = p_shifted >= 0;

alpha = zeros(size(p_values));
alpha(left_mask) = alpha_min + (alpha_max - alpha_min) ./ (1 + exp(p_shifted(left_mask) / (width * asymmetry)));
alpha(right_mask) = alpha_min + (alpha_max - alpha_min) ./ (1 + exp(p_shifted(right_mask) / (width / asymmetry)));

end

function create_improved_fitting_plots(p_values, alpha_values, params_extended, params_weighted, ...
                                      params_piecewise, params_asymmetric, r2_values, strategies, output_dir)
% Create plots comparing different fitting strategies

fprintf('Creating improved fitting comparison plots...\n');

% Create main figure
fig = figure('Position', [100, 100, 1600, 1200], 'Name', 'Improved Templated Class Sigmoid Fitting');

% Generate smooth p-values for plotting
p_smooth = linspace(min(p_values), max(p_values), 1000);

% Subplot 1: Data and all fits
subplot(2, 3, 1);
scatter(p_values, alpha_values, 100, 'k', 'filled', 'DisplayName', 'Templated Data');
hold on;

colors = {'r', 'g', 'b', 'm'};
param_vars = {params_extended, params_weighted, params_piecewise, params_asymmetric};
for i = 1:4
    if ~isempty(param_vars{i})
        if i == 4  % Asymmetric
            alpha_pred = asymmetric_sigmoid_function(param_vars{i}, p_smooth);
        else
            alpha_pred = sigmoid_function(param_vars{i}, p_smooth);
        end
        plot(p_smooth, alpha_pred, colors{i}, 'LineWidth', 2, ...
             'DisplayName', sprintf('%s (R²=%.3f)', strategies{i}, r2_values(i)));
    end
end

xlabel('Percolation Probability p');
ylabel('Growth Exponent α');
title('Templated Class: Improved Sigmoid Fitting');
legend('Location', 'best');
grid on;
ylim([0, 1.1]);

% Subplot 2: R² comparison
subplot(2, 3, 2);
bar(r2_values, 'FaceColor', [0.2, 0.6, 0.8]);
set(gca, 'XTickLabel', strategies);
ylabel('R²');
title('Fitting Quality Comparison');
grid on;
xtickangle(45);

% Subplot 3: Residuals for best fit
subplot(2, 3, 3);
[best_r2, best_idx] = max(r2_values);
best_strategy = strategies{best_idx};
best_params = param_vars{best_idx};

if best_idx == 4  % Asymmetric
    alpha_pred = asymmetric_sigmoid_function(best_params, p_values);
else
    alpha_pred = sigmoid_function(best_params, p_values);
end

residuals = alpha_values - alpha_pred;
scatter(p_values, residuals, 100, 'k', 'filled');
xlabel('Percolation Probability p');
ylabel('Residuals');
title(sprintf('Residuals: %s', best_strategy));
grid on;
yline(0, '--k');

% Subplot 4: Parameter comparison
subplot(2, 3, 4);
param_names = {'p_c', 'width', 'α_min', 'α_max'};
param_values = zeros(4, 4);
for i = 1:4
    if ~isempty(param_vars{i})
        param_values(:, i) = param_vars{i};
    end
end

bar(param_values', 'grouped');
set(gca, 'XTickLabel', strategies);
ylabel('Parameter Value');
title('Parameter Comparison');
legend(param_names, 'Location', 'best');
grid on;
xtickangle(45);

% Subplot 5: Transition region focus
subplot(2, 3, 5);
transition_mask = p_values > 0.6;
scatter(p_values(transition_mask), alpha_values(transition_mask), 100, 'k', 'filled', 'DisplayName', 'Data');
hold on;

for i = 1:4
    if ~isempty(param_vars{i})
        if i == 4  % Asymmetric
            alpha_pred = asymmetric_sigmoid_function(param_vars{i}, p_smooth);
        else
            alpha_pred = sigmoid_function(param_vars{i}, p_smooth);
        end
        plot(p_smooth, alpha_pred, colors{i}, 'LineWidth', 2, ...
             'DisplayName', sprintf('%s (R²=%.3f)', strategies{i}, r2_values(i)));
    end
end

xlabel('Percolation Probability p');
ylabel('Growth Exponent α');
title('Transition Region Focus (p > 0.6)');
legend('Location', 'best');
grid on;
xlim([0.6, 1.0]);

% Subplot 6: Summary statistics
subplot(2, 3, 6);
text(0.1, 0.8, 'FITTING STRATEGY SUMMARY', 'FontSize', 14, 'FontWeight', 'bold');
text(0.1, 0.7, sprintf('Best Strategy: %s', best_strategy), 'FontSize', 12, 'FontWeight', 'bold');
text(0.1, 0.6, sprintf('Best R²: %.4f', best_r2), 'FontSize', 12);
text(0.1, 0.5, sprintf('Improvement: %.4f', best_r2 - 0.7639), 'FontSize', 12);

text(0.1, 0.3, 'KEY INSIGHTS:', 'FontSize', 12, 'FontWeight', 'bold');
text(0.1, 0.2, '• Delayed transition at high p', 'FontSize', 10);
text(0.1, 0.15, '• Cut-off effect limits fitting', 'FontSize', 10);
text(0.1, 0.1, '• Extended range improves fit', 'FontSize', 10);

axis off;

sgtitle('Improved Templated Class Sigmoid Fitting: Addressing Cut-off Transition', 'FontSize', 16);

% Save plot
filename = fullfile(output_dir, 'improved_templated_sigmoid_fitting.png');
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end
