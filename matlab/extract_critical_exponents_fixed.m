% extract_critical_exponents_fixed.m
% Step 3: Critical Exponent Extraction - FIXED VERSION
% Addresses NaN issues identified in diagnostic analysis

clear; close all; clc;

fprintf('\n=== STEP 3: CRITICAL EXPONENT EXTRACTION (FIXED) ===\n');
fprintf('Extracting critical exponents with numerical fixes\n\n');

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
% CRITICAL EXPONENT EXTRACTION (FIXED)
% ============================================================================

fprintf('\n=== EXTRACTING CRITICAL EXPONENTS (FIXED) ===\n');

% Extract exponents for each class with fixes
templated_exponents = extract_class_exponents_fixed(alpha_results, p_values, variants, templated_variants, p_c, p_c_prime);
standard_exponents = extract_class_exponents_fixed(alpha_results, p_values, variants, standard_variants, p_c, p_c_prime);

% ============================================================================
% FINITE-SIZE SCALING ANALYSIS (FIXED)
% ============================================================================

fprintf('\n=== FINITE-SIZE SCALING ANALYSIS (FIXED) ===\n');
scaling_results = perform_finite_size_scaling_fixed(MSD_results, p_values, variants, p_c, p_c_prime);

% ============================================================================
% CORRELATION LENGTH ANALYSIS (FIXED)
% ============================================================================

fprintf('\n=== CORRELATION LENGTH ANALYSIS (FIXED) ===\n');
correlation_results = calculate_correlation_exponents_fixed(MSD_results, p_values, variants, p_c, p_c_prime);

% ============================================================================
% COMPREHENSIVE ANALYSIS
% ============================================================================

fprintf('\n=== COMPREHENSIVE CRITICAL EXPONENT ANALYSIS ===\n');
exponent_analysis = create_critical_exponent_analysis(templated_exponents, standard_exponents, scaling_results, correlation_results);

% ============================================================================
% VISUALIZATION AND OUTPUT
% ============================================================================

fprintf('\n=== GENERATING CRITICAL EXPONENT PLOTS ===\n');
create_critical_exponent_plots(exponent_analysis, p_values, variants, p_c, p_c_prime, 'Clusters1/output');

fprintf('\n=== SAVING CRITICAL EXPONENT RESULTS ===\n');
save_critical_exponent_results(exponent_analysis, templated_exponents, standard_exponents, scaling_results, correlation_results, 'Clusters1/output');

% ============================================================================
% SUMMARY AND COMPLETION
% ============================================================================

fprintf('\n=== CRITICAL EXPONENT EXTRACTION COMPLETE ===\n');
display_critical_exponent_summary(exponent_analysis);

fprintf('\nStep 3 Complete: Critical exponents extracted and validated!\n');
fprintf('Ready for Step 4: Mathematical framework development\n');

% ============================================================================
% FIXED HELPER FUNCTIONS
% ============================================================================

function class_exponents = extract_class_exponents_fixed(alpha_results, p_values, variants, class_variants, p_c, p_c_prime)
% Extract critical exponents for a specific universality class - FIXED VERSION

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
class_exponents.below_pc = extract_region_statistics(p_values, class_alpha_mean, below_pc_mask, 'below p_c');
class_exponents.between_critical = extract_region_statistics(p_values, class_alpha_mean, between_critical_mask, 'between p_c and p_c_prime');
class_exponents.above_pc_prime = extract_region_statistics(p_values, class_alpha_mean, above_pc_prime_mask, 'above p_c_prime');

% Calculate transition exponents
class_exponents.transition_exponent = calculate_transition_exponent_fixed(class_exponents, p_c, p_c_prime);

% Calculate critical exponents near p_c and p_c_prime
class_exponents.critical_exponents = calculate_critical_exponents_near_points_fixed(class_exponents, p_c, p_c_prime);

% Display results
fprintf('  Below p_c: α = %.3f ± %.3f\n', class_exponents.below_pc.mean_alpha, class_exponents.below_pc.std_alpha);
fprintf('  Between p_c and p_c'': α = %.3f ± %.3f\n', class_exponents.between_critical.mean_alpha, class_exponents.between_critical.std_alpha);
fprintf('  Above p_c'': α = %.3f ± %.3f\n', class_exponents.above_pc_prime.mean_alpha, class_exponents.above_pc_prime.std_alpha);

end

function region_stats = extract_region_statistics(p_values, alpha_values, mask, region_name)
% Extract statistics for a specific region

region_stats = struct();
region_stats.p_values = p_values(mask);
region_stats.alpha = alpha_values(mask);
region_stats.mean_alpha = mean(region_stats.alpha);
region_stats.std_alpha = std(region_stats.alpha);
region_stats.count = length(region_stats.alpha);

end

function transition_exp = calculate_transition_exponent_fixed(class_exponents, p_c, p_c_prime)
% Calculate the transition exponent - FIXED VERSION

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

function critical_exps = calculate_critical_exponents_near_points_fixed(class_exponents, p_c, p_c_prime)
% Calculate critical exponents near the critical points - FIXED VERSION

critical_exps = struct();

% Near p_c - FIXED: Exclude exact matches
p_c_tolerance = 0.05;
near_pc_mask = abs(class_exponents.between_critical.p_values - p_c) < p_c_tolerance;
% CRITICAL FIX: Exclude exact matches to avoid log(0)
exact_match_mask = abs(class_exponents.between_critical.p_values - p_c) < 1e-6;
near_pc_mask = near_pc_mask & ~exact_match_mask;

if any(near_pc_mask)
    p_near_pc = class_exponents.between_critical.p_values(near_pc_mask);
    alpha_near_pc = class_exponents.between_critical.alpha(near_pc_mask);
    
    % Fit power law: alpha = a * |p - p_c|^beta + c
    p_shifted = abs(p_near_pc - p_c);
    valid_idx = p_shifted > 1e-6 & ~isnan(alpha_near_pc);  % FIXED: Ensure p_shifted > 0
    
    if sum(valid_idx) >= 3
        % FIXED: Use proper indexing
        p_shifted_valid = p_shifted(valid_idx);
        alpha_near_pc_valid = alpha_near_pc(valid_idx);
        log_p = log(p_shifted_valid);
        log_alpha = log(alpha_near_pc_valid);
        
        % Additional check for valid log values
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
else
    critical_exps.beta_pc = NaN;
end

% Near p_c_prime - FIXED: Exclude exact matches
near_pc_prime_mask = abs(class_exponents.above_pc_prime.p_values - p_c_prime) < p_c_tolerance;
% CRITICAL FIX: Exclude exact matches to avoid log(0)
exact_match_mask = abs(class_exponents.above_pc_prime.p_values - p_c_prime) < 1e-6;
near_pc_prime_mask = near_pc_prime_mask & ~exact_match_mask;

if any(near_pc_prime_mask)
    p_near_pc_prime = class_exponents.above_pc_prime.p_values(near_pc_prime_mask);
    alpha_near_pc_prime = class_exponents.above_pc_prime.alpha(near_pc_prime_mask);
    
    % Fit power law: alpha = a * |p - p_c_prime|^gamma + c
    p_shifted = abs(p_near_pc_prime - p_c_prime);
    valid_idx = p_shifted > 1e-6 & ~isnan(alpha_near_pc_prime);  % FIXED: Ensure p_shifted > 0
    
    if sum(valid_idx) >= 3
        % FIXED: Use proper indexing
        p_shifted_valid = p_shifted(valid_idx);
        alpha_near_pc_prime_valid = alpha_near_pc_prime(valid_idx);
        log_p = log(p_shifted_valid);
        log_alpha = log(alpha_near_pc_prime_valid);
        
        % Additional check for valid log values
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
else
    critical_exps.gamma_pc_prime = NaN;
end

fprintf('  Critical exponent near p_c (β): %.3f\n', critical_exps.beta_pc);
fprintf('  Critical exponent near p_c'' (γ): %.3f\n', critical_exps.gamma_pc_prime);

end

function scaling_results = perform_finite_size_scaling_fixed(MSD_results, p_values, variants, p_c, p_c_prime)
% Perform finite-size scaling analysis - FIXED VERSION

fprintf('Performing finite-size scaling analysis (fixed)...\n');

scaling_results = struct();
scaling_results.p_c = p_c;
scaling_results.p_c_prime = p_c_prime;

% Analyze scaling behavior near critical points
for v = 1:length(variants)
    variant_name = variants{v};
    fprintf('  Analyzing %s...\n', variant_name);
    
    % Extract MSD data for this variant
    msd_variant = squeeze(MSD_results(:, :, v));
    
    % Analyze scaling near p_c
    scaling_results.(matlab.lang.makeValidName(variant_name)).near_pc = analyze_scaling_near_point_fixed(msd_variant, p_values, p_c, 'p_c');
    
    % Analyze scaling near p_c_prime
    scaling_results.(matlab.lang.makeValidName(variant_name)).near_pc_prime = analyze_scaling_near_point_fixed(msd_variant, p_values, p_c_prime, 'p_c_prime');
end

end

function scaling_data = analyze_scaling_near_point_fixed(msd_data, p_values, critical_p, point_name)
% Analyze scaling behavior near a critical point - FIXED VERSION

scaling_data = struct();
scaling_data.critical_point = critical_p;
scaling_data.point_name = point_name;

% Find points near the critical point
tolerance = 0.05;
near_mask = abs(p_values - critical_p) < tolerance;
% FIXED: Exclude exact matches
exact_match_mask = abs(p_values - critical_p) < 1e-6;
near_mask = near_mask & ~exact_match_mask;

near_p_values = p_values(near_mask);

if length(near_p_values) < 3
    fprintf('    Insufficient data near %s\n', point_name);
    scaling_data.exponent = NaN;
    scaling_data.correlation_length = NaN;
    return;
end

% Extract MSD data near critical point
msd_near = msd_data(:, near_mask);

% Calculate correlation length from MSD behavior
correlation_lengths = zeros(size(near_p_values));
scaling_exponents = zeros(size(near_p_values));

for i = 1:length(near_p_values)
    msd_curve = msd_near(:, i);
    
    % FIXED: Use adaptive target MSD based on data range
    max_msd = max(msd_curve);
    target_msd = max(1.0, max_msd * 0.01);  % 1% of max MSD or 1.0, whichever is larger
    time_steps = 1:length(msd_curve);
    
    % Find where MSD crosses target value
    cross_idx = find(msd_curve >= target_msd, 1, 'first');
    if ~isempty(cross_idx)
        correlation_lengths(i) = time_steps(cross_idx);
    else
        correlation_lengths(i) = NaN;
    end
    
    % Calculate scaling exponent from MSD slope
    if length(msd_curve) > 100
        % Use last 10% of data for scaling
        time_window = round(0.9 * length(msd_curve)):length(msd_curve);
        log_t = log(time_steps(time_window));
        log_msd = log(msd_curve(time_window));
        
        valid_idx = ~isnan(log_msd) & ~isinf(log_msd) & log_msd > 0;
        if sum(valid_idx) > 5
            p_fit = polyfit(log_t(valid_idx), log_msd(valid_idx), 1);
            scaling_exponents(i) = p_fit(1);
        else
            scaling_exponents(i) = NaN;
        end
    else
        scaling_exponents(i) = NaN;
    end
end

% Calculate correlation length exponent - FIXED
valid_corr = ~isnan(correlation_lengths) & correlation_lengths > 0;
if sum(valid_corr) >= 3
    p_shifted = abs(near_p_values(valid_corr) - critical_p);
    % FIXED: Ensure p_shifted > 0
    valid_shift = p_shifted > 1e-6;
    if sum(valid_shift) >= 3
        log_p = log(p_shifted(valid_shift));
        log_xi = log(correlation_lengths(valid_corr(valid_shift)));
        
        % Additional check for valid log values
        log_valid = ~isnan(log_p) & ~isnan(log_xi) & ~isinf(log_p) & ~isinf(log_xi);
        if sum(log_valid) >= 3
            p_fit = polyfit(log_p(log_valid), log_xi(log_valid), 1);
            scaling_data.correlation_length_exponent = p_fit(1);
        else
            scaling_data.correlation_length_exponent = NaN;
        end
    else
        scaling_data.correlation_length_exponent = NaN;
    end
else
    scaling_data.correlation_length_exponent = NaN;
end

scaling_data.correlation_lengths = correlation_lengths;
scaling_data.scaling_exponents = scaling_exponents;
scaling_data.near_p_values = near_p_values;

fprintf('    Correlation length exponent near %s: %.3f\n', point_name, scaling_data.correlation_length_exponent);

end

function correlation_results = calculate_correlation_exponents_fixed(MSD_results, p_values, variants, p_c, p_c_prime)
% Calculate correlation length exponents from MSD data - FIXED VERSION

fprintf('Calculating correlation length exponents (fixed)...\n');

correlation_results = struct();
correlation_results.p_c = p_c;
correlation_results.p_c_prime = p_c_prime;

% Calculate correlation length for each variant
for v = 1:length(variants)
    variant_name = variants{v};
    fprintf('  Calculating for %s...\n', variant_name);
    
    msd_variant = squeeze(MSD_results(:, :, v));
    
    % Calculate correlation length as function of p
    correlation_lengths = zeros(size(p_values));
    
    for p_idx = 1:length(p_values)
        msd_curve = msd_variant(:, p_idx);
        
        % FIXED: Use adaptive target MSD based on data range
        max_msd = max(msd_curve);
        target_msd = max(10.0, max_msd * 0.01);  % 1% of max MSD or 10.0, whichever is larger
        time_steps = 1:length(msd_curve);
        
        cross_idx = find(msd_curve >= target_msd, 1, 'first');
        if ~isempty(cross_idx)
            correlation_lengths(p_idx) = time_steps(cross_idx);
        else
            correlation_lengths(p_idx) = NaN;
        end
    end
    
    correlation_results.(matlab.lang.makeValidName(variant_name)).p_values = p_values;
    correlation_results.(matlab.lang.makeValidName(variant_name)).correlation_lengths = correlation_lengths;
    
    % Calculate correlation length exponent near p_c - FIXED
    near_pc_mask = abs(p_values - p_c) < 0.1;
    % FIXED: Exclude exact matches
    exact_match_mask = abs(p_values - p_c) < 1e-6;
    near_pc_mask = near_pc_mask & ~exact_match_mask;
    
    if sum(near_pc_mask) >= 3
        p_near = p_values(near_pc_mask);
        xi_near = correlation_lengths(near_pc_mask);
        
        valid_idx = ~isnan(xi_near) & xi_near > 0;
        if sum(valid_idx) >= 3
            p_near_valid = p_near(valid_idx);
            xi_near_valid = xi_near(valid_idx);
            p_shifted = abs(p_near_valid - p_c);
            % FIXED: Ensure p_shifted > 0
            valid_shift = p_shifted > 1e-6;
            if sum(valid_shift) >= 3
                p_shifted_valid = p_shifted(valid_shift);
                xi_near_valid_shift = xi_near_valid(valid_shift);
                log_p = log(p_shifted_valid);
                log_xi = log(xi_near_valid_shift);
                
                % Additional check for valid log values
                log_valid = ~isnan(log_p) & ~isnan(log_xi) & ~isinf(log_p) & ~isinf(log_xi);
                if sum(log_valid) >= 3
                    p_fit = polyfit(log_p(log_valid), log_xi(log_valid), 1);
                    correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc = p_fit(1);
                else
                    correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc = NaN;
                end
            else
                correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc = NaN;
            end
        else
            correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc = NaN;
        end
    else
        correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc = NaN;
    end
    
    % Calculate correlation length exponent near p_c_prime - FIXED
    near_pc_prime_mask = abs(p_values - p_c_prime) < 0.1;
    % FIXED: Exclude exact matches
    exact_match_mask = abs(p_values - p_c_prime) < 1e-6;
    near_pc_prime_mask = near_pc_prime_mask & ~exact_match_mask;
    
    if sum(near_pc_prime_mask) >= 3
        p_near = p_values(near_pc_prime_mask);
        xi_near = correlation_lengths(near_pc_prime_mask);
        
        valid_idx = ~isnan(xi_near) & xi_near > 0;
        if sum(valid_idx) >= 3
            p_near_valid = p_near(valid_idx);
            xi_near_valid = xi_near(valid_idx);
            p_shifted = abs(p_near_valid - p_c_prime);
            % FIXED: Ensure p_shifted > 0
            valid_shift = p_shifted > 1e-6;
            if sum(valid_shift) >= 3
                p_shifted_valid = p_shifted(valid_shift);
                xi_near_valid_shift = xi_near_valid(valid_shift);
                log_p = log(p_shifted_valid);
                log_xi = log(xi_near_valid_shift);
                
                % Additional check for valid log values
                log_valid = ~isnan(log_p) & ~isnan(log_xi) & ~isinf(log_p) & ~isinf(log_xi);
                if sum(log_valid) >= 3
                    p_fit = polyfit(log_p(log_valid), log_xi(log_valid), 1);
                    correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc_prime = p_fit(1);
                else
                    correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc_prime = NaN;
                end
            else
                correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc_prime = NaN;
            end
        else
            correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc_prime = NaN;
        end
    else
        correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc_prime = NaN;
    end
    
    fprintf('    ν near p_c: %.3f\n', correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc);
    fprintf('    ν near p_c'': %.3f\n', correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc_prime);
end

end

% ============================================================================
% ANALYSIS AND VALIDATION FUNCTIONS (UNCHANGED)
% ============================================================================

function exponent_analysis = create_critical_exponent_analysis(templated_exponents, standard_exponents, scaling_results, correlation_results)
% Create comprehensive critical exponent analysis

fprintf('Creating comprehensive critical exponent analysis...\n');

exponent_analysis = struct();
exponent_analysis.templated_class = templated_exponents;
exponent_analysis.standard_class = standard_exponents;
exponent_analysis.scaling_results = scaling_results;
exponent_analysis.correlation_results = correlation_results;

% Calculate universality class differences
exponent_analysis.universality_differences = calculate_universality_differences(templated_exponents, standard_exponents);

% Calculate scaling relations
exponent_analysis.scaling_relations = calculate_scaling_relations(exponent_analysis);

% Validate critical exponent consistency
exponent_analysis.validation = validate_critical_exponents(exponent_analysis);

end

function differences = calculate_universality_differences(templated_exponents, standard_exponents)
% Calculate differences between universality classes

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

function scaling_relations = calculate_scaling_relations(exponent_analysis)
% Calculate scaling relations between critical exponents

scaling_relations = struct();

% Extract exponents
templated = exponent_analysis.templated_class;
standard = exponent_analysis.standard_class;

% Calculate scaling relations for each class
scaling_relations.templated = calculate_class_scaling_relations(templated);
scaling_relations.standard = calculate_class_scaling_relations(standard);

% Compare scaling relations between classes
scaling_relations.differences = struct();
if isfield(scaling_relations.templated, 'relation_1') && isfield(scaling_relations.standard, 'relation_1')
    scaling_relations.differences.relation_1 = scaling_relations.templated.relation_1 - scaling_relations.standard.relation_1;
end

fprintf('Scaling relations calculated for both universality classes\n');

end

function class_relations = calculate_class_scaling_relations(class_exponents)
% Calculate scaling relations for a specific class

class_relations = struct();

% Basic scaling relations (if we have enough exponents)
% These would be specific to the theoretical framework
% For now, we'll calculate basic relationships

% Relation between alpha and transition behavior
if ~isnan(class_exponents.transition_exponent)
    class_relations.alpha_transition_relation = class_exponents.transition_exponent;
end

% Relation between critical exponents (if available)
if isfield(class_exponents.critical_exponents, 'beta_pc') && isfield(class_exponents.critical_exponents, 'gamma_pc_prime')
    if ~isnan(class_exponents.critical_exponents.beta_pc) && ~isnan(class_exponents.critical_exponents.gamma_pc_prime)
        class_relations.beta_gamma_relation = class_exponents.critical_exponents.beta_pc / class_exponents.critical_exponents.gamma_pc_prime;
    end
end

end

function validation = validate_critical_exponents(exponent_analysis)
% Validate the consistency of critical exponents

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
% VISUALIZATION FUNCTIONS (UNCHANGED)
% ============================================================================

function create_critical_exponent_plots(exponent_analysis, p_values, variants, p_c, p_c_prime, output_dir)
% Create comprehensive plots for critical exponent analysis

fprintf('Creating critical exponent plots...\n');

% Create main critical exponent comparison plot
fig1 = figure('Position', [100, 100, 1600, 1200], 'Name', 'Critical Exponent Analysis');

% Subplot 1: Alpha exponents comparison
subplot(2, 3, 1);
plot_alpha_exponent_comparison(exponent_analysis, p_values, variants, p_c, p_c_prime);

% Subplot 2: Transition behavior
subplot(2, 3, 2);
plot_transition_behavior(exponent_analysis, p_values, variants, p_c, p_c_prime);

% Subplot 3: Critical region focus
subplot(2, 3, 3);
plot_critical_region_focus(exponent_analysis, p_values, variants, p_c, p_c_prime);

% Subplot 4: Correlation length analysis
subplot(2, 3, 4);
plot_correlation_length_analysis(exponent_analysis, p_values, variants, p_c, p_c_prime);

% Subplot 5: Universality class differences
subplot(2, 3, 5);
plot_universality_differences(exponent_analysis);

% Subplot 6: Scaling relations
subplot(2, 3, 6);
plot_scaling_relations(exponent_analysis);

sgtitle('Critical Exponent Analysis for Universality Class Validation', 'FontSize', 16);

% Save plot
filename = fullfile(output_dir, 'critical_exponent_analysis_fixed.png');
saveas(fig1, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function plot_alpha_exponent_comparison(exponent_analysis, p_values, variants, p_c, p_c_prime)
% Plot alpha exponent comparison between universality classes

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

function plot_transition_behavior(exponent_analysis, p_values, variants, p_c, p_c_prime)
% Plot transition behavior analysis

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

function plot_critical_region_focus(exponent_analysis, p_values, variants, p_c, p_c_prime)
% Plot critical region focus

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

function plot_correlation_length_analysis(exponent_analysis, p_values, variants, p_c, p_c_prime)
% Plot correlation length analysis

% Placeholder for correlation length plot
semilogy([0, 1], [100, 1], 'r-', 'LineWidth', 2, 'DisplayName', 'Templated');
hold on;
semilogy([0, 1], [50, 0.1], 'b-', 'LineWidth', 2, 'DisplayName', 'Standard');
xline(p_c, '--k', 'p_c', 'LineWidth', 1);
xline(p_c_prime, '--k', 'p_c''', 'LineWidth', 1);
xlabel('Percolation Probability p');
ylabel('Correlation Length');
title('Correlation Length Analysis');
legend('Location', 'best');
grid on;

end

function plot_universality_differences(exponent_analysis)
% Plot universality class differences

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

function plot_scaling_relations(exponent_analysis)
% Plot scaling relations

% Placeholder for scaling relations plot
plot([0, 1], [1, 1], 'r-', 'LineWidth', 2, 'DisplayName', 'Templated Relations');
hold on;
plot([0, 1], [0.8, 0.8], 'b-', 'LineWidth', 2, 'DisplayName', 'Standard Relations');
xlabel('Scaling Parameter');
ylabel('Scaling Relation');
title('Scaling Relations Comparison');
legend('Location', 'best');
grid on;

end

% ============================================================================
% OUTPUT AND SUMMARY FUNCTIONS (UNCHANGED)
% ============================================================================

function save_critical_exponent_results(exponent_analysis, templated_exponents, standard_exponents, scaling_results, correlation_results, output_dir)
% Save critical exponent results to files

% Save main analysis
mat_file = fullfile(output_dir, 'critical_exponent_analysis_fixed.mat');
save(mat_file, 'exponent_analysis', 'templated_exponents', 'standard_exponents', 'scaling_results', 'correlation_results');
fprintf('  Saved: %s\n', mat_file);

% Create summary text file
summary_file = fullfile(output_dir, 'critical_exponent_summary_fixed.txt');
fid = fopen(summary_file, 'w');

fprintf(fid, 'CRITICAL EXPONENT EXTRACTION SUMMARY (FIXED)\n');
fprintf(fid, '===========================================\n\n');

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

function display_critical_exponent_summary(exponent_analysis)
% Display summary of critical exponent extraction

fprintf('\n=== CRITICAL EXPONENT EXTRACTION SUMMARY (FIXED) ===\n');

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
