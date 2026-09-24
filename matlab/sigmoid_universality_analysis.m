% sigmoid_universality_analysis.m
% Analytical Experiment: Sigmoid Fitting for Universality Class Analysis
% Implements sigmoid fitting to α(p) data for each universality class

clear; close all; clc;

fprintf('\n=== SIGMOID UNIVERSALITY CLASS ANALYSIS ===\n');
fprintf('Analytical experiment: Fitting sigmoid functions to α(p) data\n\n');

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
fprintf('  MSD_results: %s\n', mat2str(size(MSD_results)));
fprintf('  p_values: %d values from %.3f to %.3f\n', length(p_values), min(p_values), max(p_values));
fprintf('  variants: %s\n', strjoin(variants, ', '));

% Define critical points
p_c = 0.3116;           % Standard percolation threshold
p_c_prime = 0.6884;     % Apparent gel point

% Define universality classes
templated_variants = {'6N_Templated', '26N_Templated'};
standard_variants = {'Random_Percolation', 'Density_Increment'};

% ============================================================================
% EXTRACT UNIVERSALITY CLASS DATA
% ============================================================================

fprintf('\n=== EXTRACTING UNIVERSALITY CLASS DATA ===\n');

% Extract data for templated class
templated_data = extract_universality_class_data(alpha_results, p_values, variants, templated_variants);
fprintf('Templated class data: %d points\n', length(templated_data.p));

% Extract data for standard class
standard_data = extract_universality_class_data(alpha_results, p_values, variants, standard_variants);
fprintf('Standard class data: %d points\n', length(standard_data.p));

% ============================================================================
% SIGMOID FITTING
% ============================================================================

fprintf('\n=== SIGMOID FITTING ANALYSIS ===\n');

% Fit sigmoid to templated class
fprintf('\nFitting sigmoid to TEMPLATED class...\n');
[templated_params, templated_cov, templated_r2, templated_success] = fit_sigmoid_robust(templated_data.p, templated_data.alpha);

% Fit sigmoid to standard class
fprintf('\nFitting sigmoid to STANDARD class...\n');
[standard_params, standard_cov, standard_r2, standard_success] = fit_sigmoid_robust(standard_data.p, standard_data.alpha);

% ============================================================================
% UNIVERSALITY CLASS COMPARISON
% ============================================================================

fprintf('\n=== UNIVERSALITY CLASS COMPARISON ===\n');

if templated_success && standard_success
    % Calculate universality class differences
    universality_differences = calculate_sigmoid_universality_differences(templated_params, standard_params, templated_cov, standard_cov);
    
    % Display comparison results
    display_sigmoid_comparison(templated_params, standard_params, templated_r2, standard_r2, universality_differences);
    
    % ============================================================================
    % CONTINUOUS VISCOELASTIC ANALYSIS
    % ============================================================================
    
    fprintf('\n=== CONTINUOUS VISCOELASTIC ANALYSIS ===\n');
    
    % Generate continuous parameters
    continuous_params = generate_continuous_viscoelastic_parameters(templated_params, standard_params, p_values);
    
    % ============================================================================
    % VISUALIZATION
    % ============================================================================
    
    fprintf('\n=== GENERATING SIGMOID ANALYSIS PLOTS ===\n');
    create_sigmoid_universality_plots(templated_data, standard_data, templated_params, standard_params, ...
                                     templated_r2, standard_r2, continuous_params, p_c, p_c_prime, 'Clusters1/output');
    
    % ============================================================================
    % SAVE RESULTS
    % ============================================================================
    
    fprintf('\n=== SAVING SIGMOID ANALYSIS RESULTS ===\n');
    save_sigmoid_analysis_results(templated_params, standard_params, templated_cov, standard_cov, ...
                                 templated_r2, standard_r2, universality_differences, continuous_params, 'Clusters1/output');
    
else
    fprintf('Sigmoid fitting failed for one or both universality classes\n');
end

fprintf('\n=== SIGMOID UNIVERSALITY CLASS ANALYSIS COMPLETE ===\n');

% ============================================================================
% HELPER FUNCTIONS
% ============================================================================

function class_data = extract_universality_class_data(alpha_results, p_values, variants, class_variants)
% Extract data for a specific universality class

% Find variant indices
variant_indices = [];
for i = 1:length(class_variants)
    idx = find(strcmp(variants, class_variants{i}));
    if ~isempty(idx)
        variant_indices = [variant_indices, idx];
    end
end

if isempty(variant_indices)
    fprintf('  Warning: No variants found for this class\n');
    class_data = struct('p', [], 'alpha', []);
    return;
end

% Extract alpha data for this class
class_alpha = alpha_results(:, variant_indices);
class_alpha_mean = mean(class_alpha, 2);  % Average across variants in class

% Create data structure
class_data = struct();
class_data.p = p_values(:)';  % Ensure row vector
class_data.alpha = class_alpha_mean(:)';  % Ensure row vector
class_data.variants = class_variants;

end

function [params, cov, r2, success] = fit_sigmoid_robust(p_values, alpha_values)
% Fit sigmoid function to α(p) data with robust error handling

% Initial parameter guesses
p_c_guess = 0.6884;
width_guess = 0.05;
alpha_min_guess = 0.0;
alpha_max_guess = 1.0;

% Initial parameter vector
p0 = [p_c_guess, width_guess, alpha_min_guess, alpha_max_guess];

% Lower and upper bounds
lb = [0.6, 0.01, 0.0, 0.8];
ub = [0.8, 0.2, 0.1, 1.0];

try
    % Fit sigmoid function using lsqcurvefit
    options = optimoptions('lsqcurvefit', 'Display', 'off', 'MaxIterations', 1000);
    [params, resnorm] = lsqcurvefit(@sigmoid_function, p0, p_values, alpha_values, lb, ub, options);
    
    % Calculate covariance matrix (simplified)
    cov = eye(4) * resnorm / length(p_values);
    
    % Calculate R²
    alpha_pred = sigmoid_function(params, p_values);
    ss_res = sum((alpha_values - alpha_pred).^2);
    ss_tot = sum((alpha_values - mean(alpha_values)).^2);
    r2 = 1 - ss_res / ss_tot;
    
    % Display results
    fprintf('  ✓ Sigmoid fit successful!\n');
    fprintf('    p_c = %.4f ± %.4f\n', params(1), sqrt(cov(1,1)));
    fprintf('    width = %.4f ± %.4f\n', params(2), sqrt(cov(2,2)));
    fprintf('    α_min = %.4f ± %.4f\n', params(3), sqrt(cov(3,3)));
    fprintf('    α_max = %.4f ± %.4f\n', params(4), sqrt(cov(4,4)));
    fprintf('    R² = %.4f\n', r2);
    
    success = true;
    
catch ME
    fprintf('  ✗ Sigmoid fitting failed: %s\n', ME.message);
    params = [];
    cov = [];
    r2 = [];
    success = false;
end

end

function alpha = sigmoid_function(params, p_values)
% Sigmoid function for α(p) relationship

p_c = params(1);
width = params(2);
alpha_min = max(0.0, params(3));
alpha_max = min(1.0, params(4));

alpha = alpha_min + (alpha_max - alpha_min) ./ (1 + exp((p_values - p_c) / width));

end

function differences = calculate_sigmoid_universality_differences(templated_params, standard_params, templated_cov, standard_cov)
% Calculate differences between universality classes from sigmoid parameters

differences = struct();

% Compare sigmoid parameters
differences.p_c = templated_params(1) - standard_params(1);
differences.width = templated_params(2) - standard_params(2);
differences.alpha_min = templated_params(3) - standard_params(3);
differences.alpha_max = templated_params(4) - standard_params(4);

% Calculate uncertainties
differences.p_c_uncertainty = sqrt(templated_cov(1,1) + standard_cov(1,1));
differences.width_uncertainty = sqrt(templated_cov(2,2) + standard_cov(2,2));
differences.alpha_min_uncertainty = sqrt(templated_cov(3,3) + standard_cov(3,3));
differences.alpha_max_uncertainty = sqrt(templated_cov(4,4) + standard_cov(4,4));

% Calculate significance (t-test)
differences.p_c_significance = abs(differences.p_c) / differences.p_c_uncertainty;
differences.width_significance = abs(differences.width) / differences.width_uncertainty;
differences.alpha_min_significance = abs(differences.alpha_min) / differences.alpha_min_uncertainty;
differences.alpha_max_significance = abs(differences.alpha_max) / differences.alpha_max_uncertainty;

end

function display_sigmoid_comparison(templated_params, standard_params, templated_r2, standard_r2, differences)
% Display comparison of sigmoid fits between universality classes

fprintf('\nSIGMOID PARAMETER COMPARISON:\n');
fprintf('================================\n');

fprintf('\nTemplated Class:\n');
fprintf('  p_c = %.4f, width = %.4f, α_min = %.4f, α_max = %.4f, R² = %.4f\n', ...
    templated_params(1), templated_params(2), templated_params(3), templated_params(4), templated_r2);

fprintf('\nStandard Class:\n');
fprintf('  p_c = %.4f, width = %.4f, α_min = %.4f, α_max = %.4f, R² = %.4f\n', ...
    standard_params(1), standard_params(2), standard_params(3), standard_params(4), standard_r2);

fprintf('\nUniversality Class Differences:\n');
fprintf('  Δp_c = %.4f ± %.4f (significance: %.2f)\n', differences.p_c, differences.p_c_uncertainty, differences.p_c_significance);
fprintf('  Δwidth = %.4f ± %.4f (significance: %.2f)\n', differences.width, differences.width_uncertainty, differences.width_significance);
fprintf('  Δα_min = %.4f ± %.4f (significance: %.2f)\n', differences.alpha_min, differences.alpha_min_uncertainty, differences.alpha_min_significance);
fprintf('  Δα_max = %.4f ± %.4f (significance: %.2f)\n', differences.alpha_max, differences.alpha_max_uncertainty, differences.alpha_max_significance);

% Determine significance
significant_differences = 0;
if differences.p_c_significance > 2, significant_differences = significant_differences + 1; end
if differences.width_significance > 2, significant_differences = significant_differences + 1; end
if differences.alpha_min_significance > 2, significant_differences = significant_differences + 1; end
if differences.alpha_max_significance > 2, significant_differences = significant_differences + 1; end

fprintf('\nSignificance Summary: %d/4 parameters show significant differences (|t| > 2)\n', significant_differences);

end

function continuous_params = generate_continuous_viscoelastic_parameters(templated_params, standard_params, p_values)
% Generate continuous viscoelastic parameters using sigmoid α(p)

fprintf('Generating continuous viscoelastic parameters...\n');

% Generate smooth p-values for continuous curves
p_smooth = linspace(min(p_values), max(p_values), 1000);

% Calculate sigmoid α(p) for both classes
alpha_templated = sigmoid_function(templated_params, p_smooth);
alpha_standard = sigmoid_function(standard_params, p_smooth);

% Calculate viscoelastic parameters
continuous_params = struct();
continuous_params.p = p_smooth;
continuous_params.alpha_templated = alpha_templated;
continuous_params.alpha_standard = alpha_standard;

% Phase angles
continuous_params.delta_templated = pi * alpha_templated / 2;
continuous_params.delta_standard = pi * alpha_standard / 2;

% Loss tangents
continuous_params.tan_delta_templated = tan(continuous_params.delta_templated);
continuous_params.tan_delta_standard = tan(continuous_params.delta_standard);

% Storage and loss moduli (normalized)
continuous_params.G_prime_templated = cos(continuous_params.delta_templated);
continuous_params.G_double_prime_templated = sin(continuous_params.delta_templated);
continuous_params.G_prime_standard = cos(continuous_params.delta_standard);
continuous_params.G_double_prime_standard = sin(continuous_params.delta_standard);

fprintf('  ✓ Continuous parameters generated for %d p-values\n', length(p_smooth));

end

function create_sigmoid_universality_plots(templated_data, standard_data, templated_params, standard_params, ...
                                          templated_r2, standard_r2, continuous_params, p_c, p_c_prime, output_dir)
% Create comprehensive plots for sigmoid universality analysis

fprintf('Creating sigmoid universality analysis plots...\n');

% Create main figure
fig = figure('Position', [100, 100, 1600, 1200], 'Name', 'Sigmoid Universality Class Analysis');

% Subplot 1: Sigmoid fits comparison
subplot(2, 3, 1);
plot_sigmoid_fits_comparison(templated_data, standard_data, templated_params, standard_params, templated_r2, standard_r2, p_c, p_c_prime);

% Subplot 2: Continuous α(p) evolution
subplot(2, 3, 2);
plot_continuous_alpha_evolution(continuous_params, p_c, p_c_prime);

% Subplot 3: Phase angle evolution
subplot(2, 3, 3);
plot_phase_angle_evolution(continuous_params, p_c, p_c_prime);

% Subplot 4: Loss tangent evolution
subplot(2, 3, 4);
plot_loss_tangent_evolution(continuous_params, p_c, p_c_prime);

% Subplot 5: Storage modulus evolution
subplot(2, 3, 5);
plot_storage_modulus_evolution(continuous_params, p_c, p_c_prime);

% Subplot 6: Loss modulus evolution
subplot(2, 3, 6);
plot_loss_modulus_evolution(continuous_params, p_c, p_c_prime);

sgtitle('Sigmoid Universality Class Analysis: Continuous Viscoelastic Parameter Evolution', 'FontSize', 16);

% Save plot
filename = fullfile(output_dir, 'sigmoid_universality_analysis.png');
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function plot_sigmoid_fits_comparison(templated_data, standard_data, templated_params, standard_params, templated_r2, standard_r2, p_c, p_c_prime)
% Plot sigmoid fits comparison

% Generate smooth curves
p_smooth = linspace(min([templated_data.p, standard_data.p]), max([templated_data.p, standard_data.p]), 1000);
alpha_templated_smooth = sigmoid_function(templated_params, p_smooth);
alpha_standard_smooth = sigmoid_function(standard_params, p_smooth);

% Plot data points
scatter(templated_data.p, templated_data.alpha, 100, 'r', 'filled', 'DisplayName', 'Templated Data');
hold on;
scatter(standard_data.p, standard_data.alpha, 100, 'b', 'filled', 'DisplayName', 'Standard Data');

% Plot sigmoid fits
plot(p_smooth, alpha_templated_smooth, 'r-', 'LineWidth', 2, ...
     'DisplayName', sprintf('Templated Fit (R²=%.3f)', templated_r2));
plot(p_smooth, alpha_standard_smooth, 'b-', 'LineWidth', 2, ...
     'DisplayName', sprintf('Standard Fit (R²=%.3f)', standard_r2));

% Add critical points
xline(p_c, '--k', 'p_c', 'LineWidth', 1);
xline(p_c_prime, '--k', 'p_c''', 'LineWidth', 1);

xlabel('Percolation Probability p');
ylabel('Growth Exponent α');
title('Sigmoid Fits Comparison');
legend('Location', 'best');
grid on;
ylim([0, 1.1]);

end

function plot_continuous_alpha_evolution(continuous_params, p_c, p_c_prime)
% Plot continuous α(p) evolution

plot(continuous_params.p, continuous_params.alpha_templated, 'r-', 'LineWidth', 2, 'DisplayName', 'Templated');
hold on;
plot(continuous_params.p, continuous_params.alpha_standard, 'b-', 'LineWidth', 2, 'DisplayName', 'Standard');

xline(p_c, '--k', 'p_c', 'LineWidth', 1);
xline(p_c_prime, '--k', 'p_c''', 'LineWidth', 1);

xlabel('Percolation Probability p');
ylabel('Growth Exponent α');
title('Continuous α(p) Evolution');
legend('Location', 'best');
grid on;
ylim([0, 1.1]);

end

function plot_phase_angle_evolution(continuous_params, p_c, p_c_prime)
% Plot phase angle evolution

plot(continuous_params.p, continuous_params.delta_templated * 180/pi, 'r-', 'LineWidth', 2, 'DisplayName', 'Templated');
hold on;
plot(continuous_params.p, continuous_params.delta_standard * 180/pi, 'b-', 'LineWidth', 2, 'DisplayName', 'Standard');

xline(p_c, '--k', 'p_c', 'LineWidth', 1);
xline(p_c_prime, '--k', 'p_c''', 'LineWidth', 1);

xlabel('Percolation Probability p');
ylabel('Phase Angle δ (degrees)');
title('Phase Angle Evolution');
legend('Location', 'best');
grid on;
ylim([0, 90]);

end

function plot_loss_tangent_evolution(continuous_params, p_c, p_c_prime)
% Plot loss tangent evolution

semilogy(continuous_params.p, continuous_params.tan_delta_templated, 'r-', 'LineWidth', 2, 'DisplayName', 'Templated');
hold on;
semilogy(continuous_params.p, continuous_params.tan_delta_standard, 'b-', 'LineWidth', 2, 'DisplayName', 'Standard');

xline(p_c, '--k', 'p_c', 'LineWidth', 1);
xline(p_c_prime, '--k', 'p_c''', 'LineWidth', 1);

xlabel('Percolation Probability p');
ylabel('Loss Tangent tan δ');
title('Loss Tangent Evolution');
legend('Location', 'best');
grid on;

end

function plot_storage_modulus_evolution(continuous_params, p_c, p_c_prime)
% Plot storage modulus evolution

plot(continuous_params.p, continuous_params.G_prime_templated, 'r-', 'LineWidth', 2, 'DisplayName', 'Templated');
hold on;
plot(continuous_params.p, continuous_params.G_prime_standard, 'b-', 'LineWidth', 2, 'DisplayName', 'Standard');

xline(p_c, '--k', 'p_c', 'LineWidth', 1);
xline(p_c_prime, '--k', 'p_c''', 'LineWidth', 1);

xlabel('Percolation Probability p');
ylabel('Storage Modulus G'' (normalized)');
title('Storage Modulus Evolution');
legend('Location', 'best');
grid on;
ylim([0, 1.1]);

end

function plot_loss_modulus_evolution(continuous_params, p_c, p_c_prime)
% Plot loss modulus evolution

plot(continuous_params.p, continuous_params.G_double_prime_templated, 'r-', 'LineWidth', 2, 'DisplayName', 'Templated');
hold on;
plot(continuous_params.p, continuous_params.G_double_prime_standard, 'b-', 'LineWidth', 2, 'DisplayName', 'Standard');

xline(p_c, '--k', 'p_c', 'LineWidth', 1);
xline(p_c_prime, '--k', 'p_c''', 'LineWidth', 1);

xlabel('Percolation Probability p');
ylabel('Loss Modulus G'''' (normalized)');
title('Loss Modulus Evolution');
legend('Location', 'best');
grid on;
ylim([0, 1.1]);

end

function save_sigmoid_analysis_results(templated_params, standard_params, templated_cov, standard_cov, ...
                                      templated_r2, standard_r2, universality_differences, continuous_params, output_dir)
% Save sigmoid analysis results to files

% Save main analysis
mat_file = fullfile(output_dir, 'sigmoid_universality_analysis.mat');
save(mat_file, 'templated_params', 'standard_params', 'templated_cov', 'standard_cov', ...
     'templated_r2', 'standard_r2', 'universality_differences', 'continuous_params');
fprintf('  Saved: %s\n', mat_file);

% Create summary text file
summary_file = fullfile(output_dir, 'sigmoid_universality_summary.txt');
fid = fopen(summary_file, 'w');

fprintf(fid, 'SIGMOID UNIVERSALITY CLASS ANALYSIS SUMMARY\n');
fprintf(fid, '==========================================\n\n');

fprintf(fid, 'TEMPLATED CLASS SIGMOID FIT:\n');
fprintf(fid, '  p_c = %.4f ± %.4f\n', templated_params(1), sqrt(templated_cov(1,1)));
fprintf(fid, '  width = %.4f ± %.4f\n', templated_params(2), sqrt(templated_cov(2,2)));
fprintf(fid, '  α_min = %.4f ± %.4f\n', templated_params(3), sqrt(templated_cov(3,3)));
fprintf(fid, '  α_max = %.4f ± %.4f\n', templated_params(4), sqrt(templated_cov(4,4)));
fprintf(fid, '  R² = %.4f\n', templated_r2);

fprintf(fid, '\nSTANDARD CLASS SIGMOID FIT:\n');
fprintf(fid, '  p_c = %.4f ± %.4f\n', standard_params(1), sqrt(standard_cov(1,1)));
fprintf(fid, '  width = %.4f ± %.4f\n', standard_params(2), sqrt(standard_cov(2,2)));
fprintf(fid, '  α_min = %.4f ± %.4f\n', standard_params(3), sqrt(standard_cov(3,3)));
fprintf(fid, '  α_max = %.4f ± %.4f\n', standard_params(4), sqrt(standard_cov(4,4)));
fprintf(fid, '  R² = %.4f\n', standard_r2);

fprintf(fid, '\nUNIVERSALITY CLASS DIFFERENCES:\n');
fprintf(fid, '  Δp_c = %.4f ± %.4f (significance: %.2f)\n', universality_differences.p_c, universality_differences.p_c_uncertainty, universality_differences.p_c_significance);
fprintf(fid, '  Δwidth = %.4f ± %.4f (significance: %.2f)\n', universality_differences.width, universality_differences.width_uncertainty, universality_differences.width_significance);
fprintf(fid, '  Δα_min = %.4f ± %.4f (significance: %.2f)\n', universality_differences.alpha_min, universality_differences.alpha_min_uncertainty, universality_differences.alpha_min_significance);
fprintf(fid, '  Δα_max = %.4f ± %.4f (significance: %.2f)\n', universality_differences.alpha_max, universality_differences.alpha_max_uncertainty, universality_differences.alpha_max_significance);

fclose(fid);
fprintf('  Saved: %s\n', summary_file);

end
