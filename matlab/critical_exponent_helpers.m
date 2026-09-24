% critical_exponent_helpers.m
% Helper functions for critical exponent extraction

function class_exponents = extract_class_exponents(alpha_results, p_values, variants, class_variants, p_c, p_c_prime)
% Extract critical exponents for a specific universality class

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
class_exponents.below_pc = struct();
class_exponents.below_pc.p_values = p_values(below_pc_mask);
class_exponents.below_pc.alpha = class_alpha_mean(below_pc_mask);
class_exponents.below_pc.mean_alpha = mean(class_exponents.below_pc.alpha);
class_exponents.below_pc.std_alpha = std(class_exponents.below_pc.alpha);

class_exponents.between_critical = struct();
class_exponents.between_critical.p_values = p_values(between_critical_mask);
class_exponents.between_critical.alpha = class_alpha_mean(between_critical_mask);
class_exponents.between_critical.mean_alpha = mean(class_exponents.between_critical.alpha);
class_exponents.between_critical.std_alpha = std(class_exponents.between_critical.alpha);

class_exponents.above_pc_prime = struct();
class_exponents.above_pc_prime.p_values = p_values(above_pc_prime_mask);
class_exponents.above_pc_prime.alpha = class_alpha_mean(above_pc_prime_mask);
class_exponents.above_pc_prime.mean_alpha = mean(class_exponents.above_pc_prime.alpha);
class_exponents.above_pc_prime.std_alpha = std(class_exponents.above_pc_prime.alpha);

% Calculate transition exponents
class_exponents.transition_exponent = calculate_transition_exponent(class_exponents, p_c, p_c_prime);

% Calculate critical exponents near p_c and p_c_prime
class_exponents.critical_exponents = calculate_critical_exponents_near_points(class_exponents, p_c, p_c_prime);

fprintf('  Below p_c: α = %.3f ± %.3f\n', class_exponents.below_pc.mean_alpha, class_exponents.below_pc.std_alpha);
fprintf('  Between p_c and p_c'': α = %.3f ± %.3f\n', class_exponents.between_critical.mean_alpha, class_exponents.between_critical.std_alpha);
fprintf('  Above p_c'': α = %.3f ± %.3f\n', class_exponents.above_pc_prime.mean_alpha, class_exponents.above_pc_prime.std_alpha);

end

function transition_exp = calculate_transition_exponent(class_exponents, p_c, p_c_prime)
% Calculate the transition exponent describing the change across p_c_prime

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

function critical_exps = calculate_critical_exponents_near_points(class_exponents, p_c, p_c_prime)
% Calculate critical exponents near the critical points

critical_exps = struct();

% Near p_c
p_c_tolerance = 0.05;
near_pc_mask = abs(class_exponents.between_critical.p_values - p_c) < p_c_tolerance;
if any(near_pc_mask)
    p_near_pc = class_exponents.between_critical.p_values(near_pc_mask);
    alpha_near_pc = class_exponents.between_critical.alpha(near_pc_mask);
    
    % Fit power law: alpha = a * |p - p_c|^beta + c
    p_shifted = abs(p_near_pc - p_c);
    valid_idx = p_shifted > 0 & ~isnan(alpha_near_pc);
    
    if sum(valid_idx) >= 3
        log_p = log(p_shifted(valid_idx));
        log_alpha = log(alpha_near_pc(valid_idx));
        p_fit = polyfit(log_p, log_alpha, 1);
        critical_exps.beta_pc = p_fit(1);
    else
        critical_exps.beta_pc = NaN;
    end
else
    critical_exps.beta_pc = NaN;
end

% Near p_c_prime
near_pc_prime_mask = abs(class_exponents.above_pc_prime.p_values - p_c_prime) < p_c_tolerance;
if any(near_pc_prime_mask)
    p_near_pc_prime = class_exponents.above_pc_prime.p_values(near_pc_prime_mask);
    alpha_near_pc_prime = class_exponents.above_pc_prime.alpha(near_pc_prime_mask);
    
    % Fit power law: alpha = a * |p - p_c_prime|^gamma + c
    p_shifted = abs(p_near_pc_prime - p_c_prime);
    valid_idx = p_shifted > 0 & ~isnan(alpha_near_pc_prime);
    
    if sum(valid_idx) >= 3
        log_p = log(p_shifted(valid_idx));
        log_alpha = log(alpha_near_pc_prime(valid_idx));
        p_fit = polyfit(log_p, log_alpha, 1);
        critical_exps.gamma_pc_prime = p_fit(1);
    else
        critical_exps.gamma_pc_prime = NaN;
    end
else
    critical_exps.gamma_pc_prime = NaN;
end

fprintf('  Critical exponent near p_c (β): %.3f\n', critical_exps.beta_pc);
fprintf('  Critical exponent near p_c'' (γ): %.3f\n', critical_exps.gamma_pc_prime);

end

function scaling_results = perform_finite_size_scaling(MSD_results, p_values, variants, p_c, p_c_prime)
% Perform finite-size scaling analysis

fprintf('Performing finite-size scaling analysis...\n');

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
    scaling_results.(matlab.lang.makeValidName(variant_name)).near_pc = analyze_scaling_near_point(msd_variant, p_values, p_c, 'p_c');
    
    % Analyze scaling near p_c_prime
    scaling_results.(matlab.lang.makeValidName(variant_name)).near_pc_prime = analyze_scaling_near_point(msd_variant, p_values, p_c_prime, 'p_c_prime');
end

end

function scaling_data = analyze_scaling_near_point(msd_data, p_values, critical_p, point_name)
% Analyze scaling behavior near a critical point

scaling_data = struct();
scaling_data.critical_point = critical_p;
scaling_data.point_name = point_name;

% Find points near the critical point
tolerance = 0.05;
near_mask = abs(p_values - critical_p) < tolerance;
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
% Use the time scale where MSD reaches a characteristic value
correlation_lengths = zeros(size(near_p_values));
scaling_exponents = zeros(size(near_p_values));

for i = 1:length(near_p_values)
    msd_curve = msd_near(:, i);
    
    % Find characteristic time scale (e.g., where MSD = 1)
    target_msd = 1.0;
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
        
        valid_idx = ~isnan(log_msd) & ~isinf(log_msd);
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

% Calculate correlation length exponent
valid_corr = ~isnan(correlation_lengths) & correlation_lengths > 0;
if sum(valid_corr) >= 3
    p_shifted = abs(near_p_values(valid_corr) - critical_p);
    log_p = log(p_shifted);
    log_xi = log(correlation_lengths(valid_corr));
    
    p_fit = polyfit(log_p, log_xi, 1);
    scaling_data.correlation_length_exponent = p_fit(1);
else
    scaling_data.correlation_length_exponent = NaN;
end

scaling_data.correlation_lengths = correlation_lengths;
scaling_data.scaling_exponents = scaling_exponents;
scaling_data.near_p_values = near_p_values;

fprintf('    Correlation length exponent near %s: %.3f\n', point_name, scaling_data.correlation_length_exponent);

end

function correlation_results = calculate_correlation_exponents(MSD_results, p_values, variants, p_c, p_c_prime)
% Calculate correlation length exponents from MSD data

fprintf('Calculating correlation length exponents...\n');

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
        
        % Define correlation length as time scale for MSD to reach characteristic value
        target_msd = 10.0;  % Characteristic MSD value
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
    
    % Calculate correlation length exponent near p_c
    near_pc_mask = abs(p_values - p_c) < 0.1;
    if sum(near_pc_mask) >= 3
        p_near = p_values(near_pc_mask);
        xi_near = correlation_lengths(near_pc_mask);
        
        valid_idx = ~isnan(xi_near) & xi_near > 0;
        if sum(valid_idx) >= 3
            p_shifted = abs(p_near(valid_idx) - p_c);
            log_p = log(p_shifted);
            log_xi = log(xi_near(valid_idx));
            
            p_fit = polyfit(log_p, log_xi, 1);
            correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc = p_fit(1);
        else
            correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc = NaN;
        end
    else
        correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc = NaN;
    end
    
    % Calculate correlation length exponent near p_c_prime
    near_pc_prime_mask = abs(p_values - p_c_prime) < 0.1;
    if sum(near_pc_prime_mask) >= 3
        p_near = p_values(near_pc_prime_mask);
        xi_near = correlation_lengths(near_pc_prime_mask);
        
        valid_idx = ~isnan(xi_near) & xi_near > 0;
        if sum(valid_idx) >= 3
            p_shifted = abs(p_near(valid_idx) - p_c_prime);
            log_p = log(p_shifted);
            log_xi = log(xi_near(valid_idx));
            
            p_fit = polyfit(log_p, log_xi, 1);
            correlation_results.(matlab.lang.makeValidName(variant_name)).nu_pc_prime = p_fit(1);
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
