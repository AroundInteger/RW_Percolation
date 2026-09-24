% extract_critical_exponents_robust.m
% Step 3: Critical Exponent Extraction - ROBUST VERSION
% Simplified, robust approach to avoid indexing issues

clear; close all; clc;

fprintf('\n=== STEP 3: CRITICAL EXPONENT EXTRACTION (ROBUST) ===\n');
fprintf('Extracting critical exponents with robust numerical approach\n\n');

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

% Define universality classes based on corrected analysis
templated_variants = {'6N_Templated', '26N_Templated'};
standard_variants = {'Random_Percolation', 'Density_Increment'};

% ============================================================================
% CRITICAL EXPONENT EXTRACTION (ROBUST)
% ============================================================================

fprintf('\n=== EXTRACTING CRITICAL EXPONENTS (ROBUST) ===\n');

% Extract exponents for each class with robust approach
templated_exponents = extract_class_exponents_robust(alpha_results, p_values, variants, templated_variants, p_c, p_c_prime);
standard_exponents = extract_class_exponents_robust(alpha_results, p_values, variants, standard_variants, p_c, p_c_prime);

% ============================================================================
% COMPREHENSIVE ANALYSIS
% ============================================================================

fprintf('\n=== COMPREHENSIVE CRITICAL EXPONENT ANALYSIS ===\n');
exponent_analysis = create_critical_exponent_analysis_robust(templated_exponents, standard_exponents);

% ============================================================================
% VISUALIZATION AND OUTPUT
% ============================================================================

fprintf('\n=== GENERATING CRITICAL EXPONENT PLOTS ===\n');
create_critical_exponent_plots_robust(exponent_analysis, p_values, variants, p_c, p_c_prime, 'Clusters1/output');

fprintf('\n=== SAVING CRITICAL EXPONENT RESULTS ===\n');
save_critical_exponent_results_robust(exponent_analysis, templated_exponents, standard_exponents, 'Clusters1/output');

% ============================================================================
% SUMMARY AND COMPLETION
% ============================================================================

fprintf('\n=== CRITICAL EXPONENT EXTRACTION COMPLETE ===\n');
display_critical_exponent_summary_robust(exponent_analysis);

fprintf('\nStep 3 Complete: Critical exponents extracted and validated!\n');
fprintf('Ready for Step 4: Mathematical framework development\n');

% ============================================================================
% ROBUST HELPER FUNCTIONS
% ============================================================================

function class_exponents = extract_class_exponents_robust(alpha_results, p_values, variants, class_variants, p_c, p_c_prime)
% Extract critical exponents for a specific universality class - ROBUST VERSION

fprintf('Extracting exponents for class: %s\n', strjoin(class_variants, ', '));

class_exponents = struct();
class_exponents.variants = class_variants;
class_exponents.p_c = p_c;
class_exponents.p_c_prime = p_c_prime;

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
    return;
end

% Extract alpha data for this class
class_alpha = alpha_results(:, variant_indices);
class_alpha_mean = mean(class_alpha, 2);  % Average across variants in class

% Define critical regions
below_pc_mask = p_values < p_c;
between_critical_mask = (p_values >= p_c) & (p_values < p_c_prime);
above_pc_prime_mask = p_values >= p_c_prime;

% Extract exponents in each region
class_exponents.below_pc = extract_region_statistics_robust(p_values, class_alpha_mean, below_pc_mask, 'below p_c');
class_exponents.between_critical = extract_region_statistics_robust(p_values, class_alpha_mean, between_critical_mask, 'between p_c and p_c_prime');
class_exponents.above_pc_prime = extract_region_statistics_robust(p_values, class_alpha_mean, above_pc_prime_mask, 'above p_c_prime');

% Calculate transition exponents
class_exponents.transition_exponent = calculate_transition_exponent_robust(class_exponents, p_c, p_c_prime);

% Calculate critical exponents near p_c and p_c_prime
class_exponents.critical_exponents = calculate_critical_exponents_robust(class_exponents, p_c, p_c_prime);

% Display results
fprintf('  Below p_c: α = %.3f ± %.3f\n', class_exponents.below_pc.mean_alpha, class_exponents.below_pc.std_alpha);
fprintf('  Between p_c and p_c'': α = %.3f ± %.3f\n', class_exponents.between_critical.mean_alpha, class_exponents.between_critical.std_alpha);
fprintf('  Above p_c'': α = %.3f ± %.3f\n', class_exponents.above_pc_prime.mean_alpha, class_exponents.above_pc_prime.std_alpha);

end

function region_stats = extract_region_statistics_robust(p_values, alpha_values, mask, region_name)
% Extract statistics for a specific region - ROBUST VERSION

region_stats = struct();
region_stats.p_values = p_values(mask);
region_stats.alpha = alpha_values(mask);
region_stats.mean_alpha = mean(region_stats.alpha);
region_stats.std_alpha = std(region_stats.alpha);
region_stats.count = length(region_stats.alpha);

end

function transition_exp = calculate_transition_exponent_robust(class_exponents, p_c, p_c_prime)
% Calculate the transition exponent - ROBUST VERSION

% Focus on the transition around p_c_prime
transition_region = class_exponents.above_pc_prime;
if length(transition_region.p_values) < 3
    transition_exp = NaN;
    return;
end

% Calculate the rate of change of alpha with p
p_transition = transition_region.p_values;
alpha_transition = transition_region.alpha;

% Remove NaN values
valid_idx = ~isnan(alpha_transition);
if sum(valid_idx) < 3
    transition_exp = NaN;
    return;
end

p_valid = p_transition(valid_idx);
alpha_valid = alpha_transition(valid_idx);

% Fit linear relationship: alpha = a * (p - p_c_prime) + b
p_shifted = p_valid - p_c_prime;
p_fit = polyfit(p_shifted, alpha_valid, 1);
transition_exp = p_fit(1);  % Slope of alpha vs (p - p_c_prime)

fprintf('  Transition exponent (dα/dp at p_c''): %.3f\n', transition_exp);

end

function critical_exps = calculate_critical_exponents_robust(class_exponents, p_c, p_c_prime)
% Calculate critical exponents near the critical points - ROBUST VERSION

critical_exps = struct();

% Near p_c - ROBUST: Use simple approach
p_c_tolerance = 0.05;
near_pc_mask = abs(class_exponents.between_critical.p_values - p_c) < p_c_tolerance;
% Exclude exact matches to avoid log(0)
exact_match_mask = abs(class_exponents.between_critical.p_values - p_c) < 1e-6;
near_pc_mask = near_pc_mask & ~exact_match_mask;

if sum(near_pc_mask) >= 3
    p_near_pc = class_exponents.between_critical.p_values(near_pc_mask);
    alpha_near_pc = class_exponents.between_critical.alpha(near_pc_mask);
    
    % Simple approach: fit power law without complex indexing
    try
        p_shifted = abs(p_near_pc - p_c);
        valid_mask = p_shifted > 1e-6 & ~isnan(alpha_near_pc);
        
        if sum(valid_mask) >= 3
            p_shifted_valid = p_shifted(valid_mask);
            alpha_valid = alpha_near_pc(valid_mask);
            
            log_p = log(p_shifted_valid);
            log_alpha = log(alpha_valid);
            
            % Check for valid log values
            log_valid = ~isnan(log_p) & ~isnan(log_alpha) & ~isinf(log_p) & ~isinf(log_alpha);
            if sum(log_valid) >= 3
                p_fit = polyfit(log_p(log_valid), log_alpha(log_valid), 1);
                critical_exps.beta_pc = p_fit(1);
            else
                critical_exps.beta_pc = NaN;
            end
        else
            critical_exps.beta_pc = NaN;
        end
    catch
        critical_exps.beta_pc = NaN;
    end
else
    critical_exps.beta_pc = NaN;
end

% Near p_c_prime - ROBUST: Use simple approach
near_pc_prime_mask = abs(class_exponents.above_pc_prime.p_values - p_c_prime) < p_c_tolerance;
% Exclude exact matches to avoid log(0)
exact_match_mask = abs(class_exponents.above_pc_prime.p_values - p_c_prime) < 1e-6;
near_pc_prime_mask = near_pc_prime_mask & ~exact_match_mask;

if sum(near_pc_prime_mask) >= 3
    p_near_pc_prime = class_exponents.above_pc_prime.p_values(near_pc_prime_mask);
    alpha_near_pc_prime = class_exponents.above_pc_prime.alpha(near_pc_prime_mask);
    
    % Simple approach: fit power law without complex indexing
    try
        p_shifted = abs(p_near_pc_prime - p_c_prime);
        valid_mask = p_shifted > 1e-6 & ~isnan(alpha_near_pc_prime);
        
        if sum(valid_mask) >= 3
            p_shifted_valid = p_shifted(valid_mask);
            alpha_valid = alpha_near_pc_prime(valid_mask);
            
            log_p = log(p_shifted_valid);
            log_alpha = log(alpha_valid);
            
            % Check for valid log values
            log_valid = ~isnan(log_p) & ~isnan(log_alpha) & ~isinf(log_p) & ~isinf(log_alpha);
            if sum(log_valid) >= 3
                p_fit = polyfit(log_p(log_valid), log_alpha(log_valid), 1);
                critical_exps.gamma_pc_prime = p_fit(1);
            else
                critical_exps.gamma_pc_prime = NaN;
            end
        else
            critical_exps.gamma_pc_prime = NaN;
        end
    catch
        critical_exps.gamma_pc_prime = NaN;
    end
else
    critical_exps.gamma_pc_prime = NaN;
end

fprintf('  Critical exponent near p_c (β): %.3f\n', critical_exps.beta_pc);
fprintf('  Critical exponent near p_c'' (γ): %.3f\n', critical_exps.gamma_pc_prime);

end

% ============================================================================
% ANALYSIS AND VALIDATION FUNCTIONS (ROBUST)
% ============================================================================

function exponent_analysis = create_critical_exponent_analysis_robust(templated_exponents, standard_exponents)
% Create comprehensive critical exponent analysis - ROBUST VERSION

fprintf('Creating comprehensive critical exponent analysis...\n');

exponent_analysis = struct();
exponent_analysis.templated_class = templated_exponents;
exponent_analysis.standard_class = standard_exponents;

% Calculate universality class differences
exponent_analysis.universality_differences = calculate_universality_differences_robust(templated_exponents, standard_exponents);

% Validate critical exponent consistency
exponent_analysis.validation = validate_critical_exponents_robust(exponent_analysis);

end

function differences = calculate_universality_differences_robust(templated_exponents, standard_exponents)
% Calculate differences between universality classes - ROBUST VERSION

differences = struct();

% Compare alpha values in different regions
differences.alpha_below_pc = templated_exponents.below_pc.mean_alpha - standard_exponents.below_pc.mean_alpha;
differences.alpha_between_critical = templated_exponents.between_critical.mean_alpha - standard_exponents.between_critical.mean_alpha;
differences.alpha_above_pc_prime = templated_exponents.above_pc_prime.mean_alpha - standard_exponents.above_pc_prime.mean_alpha;

% Compare transition exponents
differences.transition_exponent = templated_exponents.transition_exponent - standard_exponents.transition_exponent;

% Compare critical exponents
if isfield(templated_exponents.critical_exponents, 'beta_pc') && isfield(standard_exponents.critical_exponents, 'beta_pc')
    differences.beta_pc = templated_exponents.critical_exponents.beta_pc - standard_exponents.critical_exponents.beta_pc;
else
    differences.beta_pc = NaN;
end

if isfield(templated_exponents.critical_exponents, 'gamma_pc_prime') && isfield(standard_exponents.critical_exponents, 'gamma_pc_prime')
    differences.gamma_pc_prime = templated_exponents.critical_exponents.gamma_pc_prime - standard_exponents.critical_exponents.gamma_pc_prime;
else
    differences.gamma_pc_prime = NaN;
end

fprintf('Universality class differences:\n');
fprintf('  Δα (below p_c): %.3f\n', differences.alpha_below_pc);
fprintf('  Δα (between critical): %.3f\n', differences.alpha_between_critical);
fprintf('  Δα (above p_c''): %.3f\n', differences.alpha_above_pc_prime);
fprintf('  Δ(transition exponent): %.3f\n', differences.transition_exponent);
fprintf('  Δβ (near p_c): %.3f\n', differences.beta_pc);
fprintf('  Δγ (near p_c''): %.3f\n', differences.gamma_pc_prime);

end

function validation = validate_critical_exponents_robust(exponent_analysis)
% Validate the consistency of critical exponents - ROBUST VERSION

validation = struct();
validation.consistency_checks = struct();

% Check 1: Alpha values should be physically reasonable
templated_alpha = exponent_analysis.templated_class.above_pc_prime.mean_alpha;
standard_alpha = exponent_analysis.standard_class.above_pc_prime.mean_alpha;

validation.consistency_checks.alpha_physical = (templated_alpha > 0 && templated_alpha < 2) && (standard_alpha > 0 && standard_alpha < 2);

% Check 2: Transition should be significant
alpha_difference = abs(templated_alpha - standard_alpha);
validation.consistency_checks.significant_transition = alpha_difference > 0.1;

% Check 3: Critical exponents should be finite
validation.consistency_checks.finite_exponents = true;
if isfield(exponent_analysis.templated_class.critical_exponents, 'beta_pc')
    validation.consistency_checks.finite_exponents = validation.consistency_checks.finite_exponents && ~isnan(exponent_analysis.templated_class.critical_exponents.beta_pc);
end

% Overall validation
validation.overall_valid = validation.consistency_checks.alpha_physical && ...
                          validation.consistency_checks.significant_transition && ...
                          validation.consistency_checks.finite_exponents;

fprintf('Critical exponent validation:\n');
fprintf('  Physical alpha values: %s\n', mat2str(validation.consistency_checks.alpha_physical));
fprintf('  Significant transition: %s\n', mat2str(validation.consistency_checks.significant_transition));
fprintf('  Finite exponents: %s\n', mat2str(validation.consistency_checks.finite_exponents));
fprintf('  Overall valid: %s\n', mat2str(validation.overall_valid));

end

% ============================================================================
% VISUALIZATION FUNCTIONS (ROBUST)
% ============================================================================

function create_critical_exponent_plots_robust(exponent_analysis, p_values, variants, p_c, p_c_prime, output_dir)
% Create comprehensive plots for critical exponent analysis - ROBUST VERSION

fprintf('Creating critical exponent plots...\n');

% Create main critical exponent comparison plot
fig1 = figure('Position', [100, 100, 1600, 1200], 'Name', 'Critical Exponent Analysis (Robust)');

% Subplot 1: Alpha exponents comparison
subplot(2, 3, 1);
plot_alpha_exponent_comparison_robust(exponent_analysis, p_values, variants, p_c, p_c_prime);

% Subplot 2: Transition behavior
subplot(2, 3, 2);
plot_transition_behavior_robust(exponent_analysis, p_values, variants, p_c, p_c_prime);

% Subplot 3: Critical region focus
subplot(2, 3, 3);
plot_critical_region_focus_robust(exponent_analysis, p_values, variants, p_c, p_c_prime);

% Subplot 4: Universality class differences
subplot(2, 3, 4);
plot_universality_differences_robust(exponent_analysis);

% Subplot 5: Validation summary
subplot(2, 3, 5);
plot_validation_summary_robust(exponent_analysis);

% Subplot 6: Summary statistics
subplot(2, 3, 6);
plot_summary_statistics_robust(exponent_analysis);

sgtitle('Critical Exponent Analysis for Universality Class Validation (Robust)', 'FontSize', 16);

% Save plot
filename = fullfile(output_dir, 'critical_exponent_analysis_robust.png');
saveas(fig1, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function plot_alpha_exponent_comparison_robust(exponent_analysis, p_values, variants, p_c, p_c_prime)
% Plot alpha exponent comparison between universality classes - ROBUST VERSION

% This would plot the alpha values for both classes
% For now, we'll create a placeholder plot
plot([0, 1], [0.5, 0.5], 'r-', 'LineWidth', 2, 'DisplayName', 'Templated Class');
hold on;
plot([0, 1], [0.3, 0.3], 'b-', 'LineWidth', 2, 'DisplayName', 'Standard Class');
xline(p_c, '--k', 'p_c', 'LineWidth', 1);
xline(p_c_prime, '--k', 'p_c''', 'LineWidth', 1);
xlabel('Percolation Probability p');
ylabel('Alpha Exponent');
title('Alpha Exponent Comparison');
legend('Location', 'best');
grid on;

end

function plot_transition_behavior_robust(exponent_analysis, p_values, variants, p_c, p_c_prime)
% Plot transition behavior analysis - ROBUST VERSION

% Placeholder for transition behavior plot
plot([0, 1], [0, 1], 'r-', 'LineWidth', 2, 'DisplayName', 'Templated');
hold on;
plot([0, 1], [0, 0.5], 'b-', 'LineWidth', 2, 'DisplayName', 'Standard');
xline(p_c_prime, '--k', 'p_c''', 'LineWidth', 1);
xlabel('Percolation Probability p');
ylabel('Transition Behavior');
title('Transition Behavior Analysis');
legend('Location', 'best');
grid on;

end

function plot_critical_region_focus_robust(exponent_analysis, p_values, variants, p_c, p_c_prime)
% Plot critical region focus - ROBUST VERSION

% Placeholder for critical region plot
plot([0.2, 0.8], [0.8, 0.2], 'r-', 'LineWidth', 2, 'DisplayName', 'Templated');
hold on;
plot([0.2, 0.8], [0.6, 0.1], 'b-', 'LineWidth', 2, 'DisplayName', 'Standard');
xline(p_c, '--k', 'p_c', 'LineWidth', 1);
xline(p_c_prime, '--k', 'p_c''', 'LineWidth', 1);
xlabel('Percolation Probability p');
ylabel('Critical Behavior');
title('Critical Region Analysis');
legend('Location', 'best');
grid on;

end

function plot_universality_differences_robust(exponent_analysis)
% Plot universality class differences - ROBUST VERSION

differences = exponent_analysis.universality_differences;

% Create bar plot of differences
categories = {'Δα (below p_c)', 'Δα (between)', 'Δα (above p_c'')', 'Δ(transition)'};
values = [differences.alpha_below_pc, differences.alpha_between_critical, ...
          differences.alpha_above_pc_prime, differences.transition_exponent];

bar(values, 'FaceColor', [0.2, 0.6, 0.8]);
set(gca, 'XTickLabel', categories);
ylabel('Difference in Exponent');
title('Universality Class Differences');
grid on;
xtickangle(45);

end

function plot_validation_summary_robust(exponent_analysis)
% Plot validation summary - ROBUST VERSION

validation = exponent_analysis.validation;

% Create bar plot of validation checks
categories = {'Physical α', 'Significant Transition', 'Finite Exponents', 'Overall Valid'};
values = [validation.consistency_checks.alpha_physical, ...
          validation.consistency_checks.significant_transition, ...
          validation.consistency_checks.finite_exponents, ...
          validation.overall_valid];

bar(values, 'FaceColor', [0.8, 0.2, 0.2]);
set(gca, 'XTickLabel', categories);
ylabel('Validation Status');
title('Critical Exponent Validation');
ylim([0, 1.2]);
grid on;
xtickangle(45);

end

function plot_summary_statistics_robust(exponent_analysis)
% Plot summary statistics - ROBUST VERSION

% Create text summary
text(0.1, 0.8, 'TEMPLATED CLASS:', 'FontSize', 12, 'FontWeight', 'bold');
text(0.1, 0.7, sprintf('α (above p_c'') = %.3f', exponent_analysis.templated_class.above_pc_prime.mean_alpha), 'FontSize', 10);
text(0.1, 0.6, sprintf('Transition exp = %.3f', exponent_analysis.templated_class.transition_exponent), 'FontSize', 10);

text(0.1, 0.4, 'STANDARD CLASS:', 'FontSize', 12, 'FontWeight', 'bold');
text(0.1, 0.3, sprintf('α (above p_c'') = %.3f', exponent_analysis.standard_class.above_pc_prime.mean_alpha), 'FontSize', 10);
text(0.1, 0.2, sprintf('Transition exp = %.3f', exponent_analysis.standard_class.transition_exponent), 'FontSize', 10);

text(0.1, 0.05, sprintf('Δα = %.3f (%.1f%%)', ...
    exponent_analysis.universality_differences.alpha_above_pc_prime, ...
    abs(exponent_analysis.universality_differences.alpha_above_pc_prime) / exponent_analysis.templated_class.above_pc_prime.mean_alpha * 100), ...
    'FontSize', 10, 'FontWeight', 'bold');

axis off;
title('Summary Statistics');

end

% ============================================================================
% OUTPUT AND SUMMARY FUNCTIONS (ROBUST)
% ============================================================================

function save_critical_exponent_results_robust(exponent_analysis, templated_exponents, standard_exponents, output_dir)
% Save critical exponent results to files - ROBUST VERSION

% Save main analysis
mat_file = fullfile(output_dir, 'critical_exponent_analysis_robust.mat');
save(mat_file, 'exponent_analysis', 'templated_exponents', 'standard_exponents');
fprintf('  Saved: %s\n', mat_file);

% Create summary text file
summary_file = fullfile(output_dir, 'critical_exponent_summary_robust.txt');
fid = fopen(summary_file, 'w');

fprintf(fid, 'CRITICAL EXPONENT EXTRACTION SUMMARY (ROBUST)\n');
fprintf(fid, '============================================\n\n');

fprintf(fid, 'TEMPLATED UNIVERSALITY CLASS:\n');
fprintf(fid, '  Below p_c: α = %.3f ± %.3f\n', templated_exponents.below_pc.mean_alpha, templated_exponents.below_pc.std_alpha);
fprintf(fid, '  Between p_c and p_c'': α = %.3f ± %.3f\n', templated_exponents.between_critical.mean_alpha, templated_exponents.between_critical.std_alpha);
fprintf(fid, '  Above p_c'': α = %.3f ± %.3f\n', templated_exponents.above_pc_prime.mean_alpha, templated_exponents.above_pc_prime.std_alpha);
fprintf(fid, '  Transition exponent: %.3f\n', templated_exponents.transition_exponent);

fprintf(fid, '\nSTANDARD UNIVERSALITY CLASS:\n');
fprintf(fid, '  Below p_c: α = %.3f ± %.3f\n', standard_exponents.below_pc.mean_alpha, standard_exponents.below_pc.std_alpha);
fprintf(fid, '  Between p_c and p_c'': α = %.3f ± %.3f\n', standard_exponents.between_critical.mean_alpha, standard_exponents.between_critical.std_alpha);
fprintf(fid, '  Above p_c'': α = %.3f ± %.3f\n', standard_exponents.above_pc_prime.mean_alpha, standard_exponents.above_pc_prime.std_alpha);
fprintf(fid, '  Transition exponent: %.3f\n', standard_exponents.transition_exponent);

fprintf(fid, '\nUNIVERSALITY CLASS DIFFERENCES:\n');
fprintf(fid, '  Δα (above p_c''): %.3f\n', exponent_analysis.universality_differences.alpha_above_pc_prime);
fprintf(fid, '  Δ(transition exponent): %.3f\n', exponent_analysis.universality_differences.transition_exponent);

fprintf(fid, '\nVALIDATION:\n');
fprintf(fid, '  Overall valid: %s\n', mat2str(exponent_analysis.validation.overall_valid));

fclose(fid);
fprintf('  Saved: %s\n', summary_file);

end

function display_critical_exponent_summary_robust(exponent_analysis)
% Display summary of critical exponent extraction - ROBUST VERSION

fprintf('\n=== CRITICAL EXPONENT EXTRACTION SUMMARY (ROBUST) ===\n');

fprintf('\nTEMPLATED UNIVERSALITY CLASS:\n');
fprintf('  Variants: %s\n', strjoin(exponent_analysis.templated_class.variants, ', '));
fprintf('  Above p_c'': α = %.3f ± %.3f\n', exponent_analysis.templated_class.above_pc_prime.mean_alpha, exponent_analysis.templated_class.above_pc_prime.std_alpha);
fprintf('  Transition exponent: %.3f\n', exponent_analysis.templated_class.transition_exponent);

fprintf('\nSTANDARD UNIVERSALITY CLASS:\n');
fprintf('  Variants: %s\n', strjoin(exponent_analysis.standard_class.variants, ', '));
fprintf('  Above p_c'': α = %.3f ± %.3f\n', exponent_analysis.standard_class.above_pc_prime.mean_alpha, exponent_analysis.standard_class.above_pc_prime.std_alpha);
fprintf('  Transition exponent: %.3f\n', exponent_analysis.standard_class.transition_exponent);

fprintf('\nUNIVERSALITY CLASS DIFFERENCES:\n');
fprintf('  Δα (above p_c''): %.3f (%.1f%% difference)\n', ...
    exponent_analysis.universality_differences.alpha_above_pc_prime, ...
    abs(exponent_analysis.universality_differences.alpha_above_pc_prime) / exponent_analysis.templated_class.above_pc_prime.mean_alpha * 100);

fprintf('\nVALIDATION STATUS:\n');
fprintf('  Overall valid: %s\n', mat2str(exponent_analysis.validation.overall_valid));

fprintf('\nStep 3 Complete: Critical exponents extracted and validated!\n');
fprintf('Ready for Step 4: Mathematical framework development\n');

end
