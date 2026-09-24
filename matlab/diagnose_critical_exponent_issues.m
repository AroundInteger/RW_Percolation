% diagnose_critical_exponent_issues.m
% Diagnostic script to identify and fix NaN issues in critical exponent extraction

clear; close all; clc;

fprintf('\n=== DIAGNOSING CRITICAL EXPONENT EXTRACTION ISSUES ===\n');

% Load the data
mat_file = 'Clusters1/random_walk_analysis_L500_LW1000000_NW3000.mat';
load(mat_file);

alpha_file = 'Clusters1/output/universality_class_analysis.mat';
load(alpha_file);

fprintf('Data loaded successfully\n');
fprintf('  MSD_results: %s\n', mat2str(size(MSD_results)));
fprintf('  p_values: %d values from %.3f to %.3f\n', length(p_values), min(p_values), max(p_values));
fprintf('  variants: %s\n', strjoin(variants, ', '));

% Define critical points
p_c = 0.3116;
p_c_prime = 0.6884;

% Define universality classes
templated_variants = {'6N_Templated', '26N_Templated'};
standard_variants = {'Random_Percolation', 'Density_Increment'};

fprintf('\n=== ISSUE 1: CRITICAL EXPONENT EXTRACTION ===\n');
diagnose_critical_exponent_extraction(alpha_results, p_values, variants, templated_variants, standard_variants, p_c, p_c_prime);

fprintf('\n=== ISSUE 2: FINITE-SIZE SCALING ANALYSIS ===\n');
diagnose_finite_size_scaling(MSD_results, p_values, variants, p_c, p_c_prime);

fprintf('\n=== ISSUE 3: CORRELATION LENGTH ANALYSIS ===\n');
diagnose_correlation_length(MSD_results, p_values, variants, p_c, p_c_prime);

fprintf('\n=== DIAGNOSTIC COMPLETE ===\n');

% ============================================================================
% DIAGNOSTIC FUNCTIONS
% ============================================================================

function diagnose_critical_exponent_extraction(alpha_results, p_values, variants, templated_variants, standard_variants, p_c, p_c_prime)
% Diagnose issues with critical exponent extraction

fprintf('Diagnosing critical exponent extraction...\n');

% Check data availability
fprintf('\n1. Data Availability Check:\n');
fprintf('  alpha_results size: %s\n', mat2str(size(alpha_results)));
fprintf('  p_values range: [%.3f, %.3f]\n', min(p_values), max(p_values));
fprintf('  p_c = %.3f, p_c_prime = %.3f\n', p_c, p_c_prime);

% Check if we have data near critical points
tolerance = 0.05;
near_pc_mask = abs(p_values - p_c) < tolerance;
near_pc_prime_mask = abs(p_values - p_c_prime) < tolerance;

fprintf('  Points near p_c (tolerance=%.2f): %d\n', tolerance, sum(near_pc_mask));
fprintf('  Points near p_c_prime (tolerance=%.2f): %d\n', tolerance, sum(near_pc_prime_mask));

if sum(near_pc_mask) < 3
    fprintf('  WARNING: Insufficient data near p_c for critical exponent extraction\n');
end
if sum(near_pc_prime_mask) < 3
    fprintf('  WARNING: Insufficient data near p_c_prime for critical exponent extraction\n');
end

% Check alpha values near critical points
fprintf('\n2. Alpha Values Near Critical Points:\n');
for v = 1:length(variants)
    variant_name = variants{v};
    variant_idx = find(strcmp(variants, variant_name));
    
    if ~isempty(variant_idx)
        alpha_variant = alpha_results(:, variant_idx);
        
        % Near p_c
        alpha_near_pc = alpha_variant(near_pc_mask);
        fprintf('  %s near p_c: α = [%.3f, %.3f, %.3f, ...] (mean=%.3f)\n', ...
            variant_name, alpha_near_pc(1:min(3,end)), mean(alpha_near_pc));
        
        % Near p_c_prime
        alpha_near_pc_prime = alpha_variant(near_pc_prime_mask);
        fprintf('  %s near p_c_prime: α = [%.3f, %.3f, %.3f, ...] (mean=%.3f)\n', ...
            variant_name, alpha_near_pc_prime(1:min(3,end)), mean(alpha_near_pc_prime));
    end
end

% Test critical exponent calculation for one variant
fprintf('\n3. Testing Critical Exponent Calculation:\n');
test_variant = '6N_Templated';
variant_idx = find(strcmp(variants, test_variant));
if ~isempty(variant_idx)
    alpha_variant = alpha_results(:, variant_idx);
    
    % Test near p_c
    fprintf('  Testing %s near p_c:\n', test_variant);
    p_near_pc = p_values(near_pc_mask);
    alpha_near_pc = alpha_variant(near_pc_mask);
    
    if length(p_near_pc) >= 3
        % Try to fit power law
        p_shifted = abs(p_near_pc - p_c);
        valid_idx = p_shifted > 0 & ~isnan(alpha_near_pc);
        
        fprintf('    p_shifted: [%.4f, %.4f, %.4f, ...]\n', p_shifted(1:min(3,end)));
        fprintf('    alpha_near_pc: [%.3f, %.3f, %.3f, ...]\n', alpha_near_pc(1:min(3,end)));
        fprintf('    valid_idx: %d/%d points valid\n', sum(valid_idx), length(valid_idx));
        
        if sum(valid_idx) >= 3
            log_p = log(p_shifted(valid_idx));
            log_alpha = log(alpha_near_pc(valid_idx));
            
            fprintf('    log(p_shifted): [%.3f, %.3f, %.3f, ...]\n', log_p(1:min(3,end)));
            fprintf('    log(alpha): [%.3f, %.3f, %.3f, ...]\n', log_alpha(1:min(3,end)));
            
            try
                p_fit = polyfit(log_p, log_alpha, 1);
                fprintf('    Power law fit: log(α) = %.3f * log(|p-p_c|) + %.3f\n', p_fit(1), p_fit(2));
                fprintf('    Critical exponent β = %.3f\n', p_fit(1));
            catch ME
                fprintf('    ERROR in power law fit: %s\n', ME.message);
            end
        else
            fprintf('    ERROR: Insufficient valid data points for fitting\n');
        end
    else
        fprintf('    ERROR: Insufficient data points near p_c\n');
    end
end

end

function diagnose_finite_size_scaling(MSD_results, p_values, variants, p_c, p_c_prime)
% Diagnose issues with finite-size scaling analysis

fprintf('Diagnosing finite-size scaling analysis...\n');

% Check MSD data structure
fprintf('\n1. MSD Data Structure Check:\n');
fprintf('  MSD_results size: %s\n', mat2str(size(MSD_results)));
fprintf('  Expected: [time_steps x p_values x variants]\n');

% Check time dimension
time_steps = size(MSD_results, 1);
fprintf('  Time steps: %d\n', time_steps);

% Check MSD values
fprintf('\n2. MSD Values Check:\n');
for v = 1:min(2, length(variants))  % Check first 2 variants
    variant_name = variants{v};
    msd_variant = squeeze(MSD_results(:, :, v));
    
    fprintf('  %s:\n', variant_name);
    fprintf('    MSD range: [%.3f, %.3f]\n', min(msd_variant(:)), max(msd_variant(:)));
    fprintf('    MSD at t=1: [%.3f, %.3f, %.3f, ...]\n', msd_variant(1, 1:min(3,end)));
    fprintf('    MSD at t=end: [%.3f, %.3f, %.3f, ...]\n', msd_variant(end, 1:min(3,end)));
    
    % Check for NaN or Inf values
    nan_count = sum(isnan(msd_variant(:)));
    inf_count = sum(isinf(msd_variant(:)));
    fprintf('    NaN values: %d, Inf values: %d\n', nan_count, inf_count);
end

% Test correlation length calculation
fprintf('\n3. Testing Correlation Length Calculation:\n');
test_variant = '6N_Templated';
variant_idx = find(strcmp(variants, test_variant));
if ~isempty(variant_idx)
    msd_variant = squeeze(MSD_results(:, :, variant_idx));
    
    % Test for one p-value
    test_p_idx = 1;
    msd_curve = msd_variant(:, test_p_idx);
    p_val = p_values(test_p_idx);
    
    fprintf('  Testing %s at p=%.3f:\n', test_variant, p_val);
    fprintf('    MSD curve length: %d\n', length(msd_curve));
    fprintf('    MSD range: [%.3f, %.3f]\n', min(msd_curve), max(msd_curve));
    
    % Test correlation length calculation
    target_msd = 1.0;
    time_steps = 1:length(msd_curve);
    
    cross_idx = find(msd_curve >= target_msd, 1, 'first');
    if ~isempty(cross_idx)
        fprintf('    MSD crosses %.1f at time step %d\n', target_msd, cross_idx);
        fprintf('    Correlation length = %d\n', cross_idx);
    else
        fprintf('    MSD never reaches %.1f (max MSD = %.3f)\n', target_msd, max(msd_curve));
    end
    
    % Test scaling exponent calculation
    if length(msd_curve) > 100
        time_window = round(0.9 * length(msd_curve)):length(msd_curve);
        log_t = log(time_steps(time_window));
        log_msd = log(msd_curve(time_window));
        
        valid_idx = ~isnan(log_msd) & ~isinf(log_msd);
        fprintf('    Scaling analysis: %d/%d points valid in time window\n', sum(valid_idx), length(valid_idx));
        
        if sum(valid_idx) > 5
            try
                p_fit = polyfit(log_t(valid_idx), log_msd(valid_idx), 1);
                fprintf('    Scaling exponent: %.3f\n', p_fit(1));
            catch ME
                fprintf('    ERROR in scaling fit: %s\n', ME.message);
            end
        else
            fprintf('    ERROR: Insufficient valid data for scaling analysis\n');
        end
    else
        fprintf('    ERROR: MSD curve too short for scaling analysis\n');
    end
end

end

function diagnose_correlation_length(MSD_results, p_values, variants, p_c, p_c_prime)
% Diagnose issues with correlation length analysis

fprintf('Diagnosing correlation length analysis...\n');

% Check data near critical points
tolerance = 0.1;
near_pc_mask = abs(p_values - p_c) < tolerance;
near_pc_prime_mask = abs(p_values - p_c_prime) < tolerance;

fprintf('\n1. Data Near Critical Points:\n');
fprintf('  Points near p_c (tolerance=%.1f): %d\n', tolerance, sum(near_pc_mask));
fprintf('  Points near p_c_prime (tolerance=%.1f): %d\n', tolerance, sum(near_pc_prime_mask));

if sum(near_pc_mask) < 3
    fprintf('  WARNING: Insufficient data near p_c for correlation length analysis\n');
end
if sum(near_pc_prime_mask) < 3
    fprintf('  WARNING: Insufficient data near p_c_prime for correlation length analysis\n');
end

% Test correlation length calculation for one variant
fprintf('\n2. Testing Correlation Length Calculation:\n');
test_variant = '6N_Templated';
variant_idx = find(strcmp(variants, test_variant));
if ~isempty(variant_idx)
    msd_variant = squeeze(MSD_results(:, :, variant_idx));
    
    % Calculate correlation length for all p-values
    correlation_lengths = zeros(size(p_values));
    target_msd = 10.0;  % Characteristic MSD value
    
    fprintf('  Testing %s with target MSD = %.1f:\n', test_variant, target_msd);
    
    for p_idx = 1:length(p_values)
        msd_curve = msd_variant(:, p_idx);
        time_steps = 1:length(msd_curve);
        
        cross_idx = find(msd_curve >= target_msd, 1, 'first');
        if ~isempty(cross_idx)
            correlation_lengths(p_idx) = time_steps(cross_idx);
        else
            correlation_lengths(p_idx) = NaN;
        end
    end
    
    % Check results
    valid_corr = ~isnan(correlation_lengths) & correlation_lengths > 0;
    fprintf('    Valid correlation lengths: %d/%d\n', sum(valid_corr), length(correlation_lengths));
    
    if sum(valid_corr) > 0
        fprintf('    Correlation length range: [%.1f, %.1f]\n', min(correlation_lengths(valid_corr)), max(correlation_lengths(valid_corr)));
        
        % Test near p_c
        p_near = p_values(near_pc_mask);
        xi_near = correlation_lengths(near_pc_mask);
        
        valid_near = ~isnan(xi_near) & xi_near > 0;
        fprintf('    Near p_c: %d/%d valid correlation lengths\n', sum(valid_near), length(xi_near));
        
        if sum(valid_near) >= 3
            p_shifted = abs(p_near(valid_near) - p_c);
            log_p = log(p_shifted);
            log_xi = log(xi_near(valid_near));
            
            fprintf('    log(|p-p_c|): [%.3f, %.3f, %.3f, ...]\n', log_p(1:min(3,end)));
            fprintf('    log(ξ): [%.3f, %.3f, %.3f, ...]\n', log_xi(1:min(3,end)));
            
            try
                p_fit = polyfit(log_p, log_xi, 1);
                fprintf('    Power law fit: log(ξ) = %.3f * log(|p-p_c|) + %.3f\n', p_fit(1), p_fit(2));
                fprintf('    Correlation length exponent ν = %.3f\n', p_fit(1));
            catch ME
                fprintf('    ERROR in correlation length fit: %s\n', ME.message);
            end
        else
            fprintf('    ERROR: Insufficient valid data near p_c for correlation length analysis\n');
        end
    else
        fprintf('    ERROR: No valid correlation lengths calculated\n');
    end
end

end
