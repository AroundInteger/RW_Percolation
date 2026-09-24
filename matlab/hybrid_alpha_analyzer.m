function [results, analyzer] = hybrid_alpha_analyzer(file_path, p_values, p_c_prime)
% HYBRID_ALPHA_ANALYZER MATLAB version of the hybrid alpha analyzer
% Combines physics-based classification, transition detection, and sigmoid fitting
% for robust regime classification and smooth parameter interpolation.
%
% Inputs:
%   file_path: Path to CSV file containing MSD data
%   p_values: Array of percolation probabilities to analyze
%   p_c_prime: Critical percolation threshold (default: 0.6884)
%
% Outputs:
%   results: Structure array with analysis results for each p-value
%   analyzer: Structure containing fitted sigmoid parameters and functions
%
% Example:
%   p_vals = [0.0, 0.1, 0.2, 0.3, 0.3116, 0.4, 0.5, 0.6, 0.6884, 0.7, 0.8];
%   [results, analyzer] = hybrid_alpha_analyzer('p_output_NEW34.csv', p_vals);

% Set default critical threshold if not provided
if nargin < 3
    p_c_prime = 0.6884;
end

fprintf('=== HYBRID ANALYSIS OF %d P-VALUES ===\n', length(p_values));

% Initialize results structure
results = struct();

% Analyze all p-values
for i = 1:length(p_values)
    p = p_values(i);
    fprintf('  Progress: %d/%d - p = %.4f\n', i, length(p_values), p);
    
    % Analyze single p-value
    result = analyze_single_p_value(file_path, p, p_c_prime);
    if ~isempty(result)
        results(i).p = result.p;
        results(i).strategy = result.strategy;
        results(i).alpha_opt = result.alpha_opt;
        results(i).alpha_std = result.alpha_std;
        results(i).r_squared = result.r_squared;
        results(i).confidence = result.confidence;
        results(i).tau_cr = result.tau_cr;
        results(i).window_results = result.window_results;
        results(i).classification_method = result.classification_method;
        results(i).classification_reason = result.classification_reason;
        results(i).physics_score = result.physics_score;
        results(i).geometric_score = result.geometric_score;
        results(i).transition_detected = result.transition_detected;
        results(i).description = result.description;
    else
        fprintf('    Warning: Analysis failed for p = %.4f\n', p);
    end
end

% Remove empty results
results = results(~cellfun(@isempty, {results.p}));

% Fit sigmoid function to α(p) data
fprintf('\nFitting sigmoid function to α(p) data...\n');
[sigmoid_success, sigmoid_params, sigmoid_covariance, sigmoid_r2] = fit_sigmoid_function(results);

if sigmoid_success
    % Add sigmoid predictions to results
    results = add_sigmoid_predictions(results, sigmoid_params);
    
    % Calculate continuous viscoelastic parameters
    [continuous_params, analyzer] = calculate_continuous_parameters(results, sigmoid_params);
    
    % Store analyzer results
    analyzer.sigmoid_params = sigmoid_params;
    analyzer.sigmoid_covariance = sigmoid_covariance;
    analyzer.sigmoid_r2 = sigmoid_r2;
    analyzer.continuous_params = continuous_params;
    analyzer.p_c_prime = p_c_prime;
    
    fprintf('✓ Sigmoid function fitted successfully!\n');
    fprintf('  p_c = %.4f ± %.4f\n', sigmoid_params(1), sqrt(sigmoid_covariance(1,1)));
    fprintf('  width = %.4f ± %.4f\n', sigmoid_params(2), sqrt(sigmoid_covariance(2,2)));
    fprintf('  α_min = %.4f ± %.4f\n', sigmoid_params(3), sqrt(sigmoid_covariance(3,3)));
    fprintf('  α_max = %.4f ± %.4f\n', sigmoid_params(4), sqrt(sigmoid_covariance(4,4)));
    fprintf('  R² = %.4f\n', sigmoid_r2);
else
    analyzer = struct();
    fprintf('✗ Sigmoid fitting failed\n');
end

fprintf('\n=== HYBRID ANALYSIS COMPLETE ===\n');
fprintf('Total p-values analyzed: %d\n', length(results));

% Classification summary
strategies = {results.strategy};
unique_strategies = unique(strategies);
fprintf('\nRegime Classification:\n');
for i = 1:length(unique_strategies)
    strategy = unique_strategies{i};
    count = sum(strcmp(strategies, strategy));
    fprintf('  %s: %d p-values\n', strategy, count);
end

% Classification methods summary
methods = {results.classification_method};
unique_methods = unique(methods);
fprintf('\nClassification Methods:\n');
for i = 1:length(unique_methods)
    method = unique_methods{i};
    count = sum(strcmp(methods, method));
    fprintf('  %s: %d p-values\n', method, count);
end

end

function result = analyze_single_p_value(file_path, p_value, p_c_prime)
% Analyze a single p-value using hybrid classification

% Get column name
if p_value == 0.0
    col_name = 'MSD_0';
else
    col_name = sprintf('MSD_%.4f', p_value);
end

% Read CSV file to get column names
opts = detectImportOptions(file_path);
if ~ismember(col_name, opts.VariableNames)
    fprintf('Warning: Column %s not found\n', col_name);
    result = [];
    return;
end

% Extract MSD data
data = readtable(file_path);
msd_data = data.(col_name);
time_steps = (1:length(msd_data))';

% Remove any invalid data
valid_mask = isfinite(msd_data) & (msd_data > 0);
if ~any(valid_mask)
    fprintf('Warning: No valid data for p = %.4f\n', p_value);
    result = [];
    return;
end

msd_valid = msd_data(valid_mask);
time_valid = time_steps(valid_mask);
figure(1);loglog(time_valid,msd_valid,time_valid,time_valid,'--r')

ln_t = log10(time_valid);
ln_y = log10(msd_valid);
ln_z = log10(msd_valid./time_valid);
ln_ti = linspace(min(ln_t),max(ln_t),1e3);
ln_zi = interp1(ln_t,ln_z,ln_ti);

dln_y = gradient(ln_y);
dln_z = gradient(ln_z);
dln_zi = gradient(ln_zi);

figure(2);plot(ln_t,[ln_z,0*ones(size(ln_t))],ln_ti,ln_zi,'.',ln_ti,smoothdata(ln_zi),'o')
figure(3);plot(ln_t,dln_z,'.',ln_ti,dln_zi,'o')

% Multi-window analysis for robust α determination
window_results = analyze_multiple_windows(msd_valid, time_valid);

if isempty(window_results)
    fprintf('Warning: No valid windows for p = %.4f\n', p_value);
    result = [];
    return;
end

% Hybrid classification
classification_result = hybrid_classification(p_value, window_results, p_c_prime);

% Calculate overall statistics
alpha_values = [window_results.alpha];
r_squared_values = [window_results.r_squared];

% Weighted average α (handle zero weights)
if sum(r_squared_values) > 0
    weighted_alpha = sum(alpha_values .* r_squared_values) / sum(r_squared_values);
else
    weighted_alpha = mean(alpha_values);
end

mean_r2 = mean(r_squared_values);
alpha_std = std(alpha_values);

% Confidence score
confidence = calculate_confidence(alpha_values, r_squared_values);

% Create result structure
result.p = p_value;
result.strategy = classification_result.strategy;
result.alpha_opt = weighted_alpha;
result.alpha_std = alpha_std;
result.r_squared = mean_r2;
result.confidence = confidence;
result.tau_cr = window_results(1).tau_cr;
result.window_results = window_results;
result.classification_method = classification_result.method;
result.classification_reason = classification_result.reason;
result.physics_score = classification_result.physics_score;
result.geometric_score = classification_result.geometric_score;
result.transition_detected = classification_result.transition_detected;
result.description = classification_result.description;

end

function window_results = analyze_multiple_windows(msd_valid, time_valid)
% Analyze multiple time windows for robust α determination

% Define analysis windows
windows = struct();
windows(1).name = 'Early';
windows(1).start_frac = 0.1;
windows(1).end_frac = 0.5;
windows(1).strategy = 'liquid';

windows(2).name = 'Middle';
windows(2).start_frac = 0.25;
windows(2).end_frac = 0.75;
windows(2).strategy = 'critical';

windows(3).name = 'Late';
windows(3).start_frac = 0.5;
windows(3).end_frac = 1.0;
windows(3).strategy = 'liquid';

windows(4).name = 'Very Late';
windows(4).start_frac = 0.75;
windows(4).end_frac = 1.0;
windows(4).strategy = 'solid';

window_results = struct();

for i = 1:length(windows)
    window = windows(i);
    start_idx = round(length(msd_valid) * window.start_frac);
    end_idx = round(length(msd_valid) * window.end_frac);
    
    if end_idx - start_idx < 50
        continue;
    end
    
    msd_window = msd_valid(start_idx:end_idx);
    time_window = time_valid(start_idx:end_idx);
    
    window_result = analyze_single_window(msd_window, time_window, window.strategy, window.name);
    
    if ~isempty(window_result)
        if isempty(fieldnames(window_results))
            window_results = window_result;
        else
            window_results(end+1) = window_result;
        end
    end
end

end

function window_result = analyze_single_window(msd_window, time_window, expected_strategy, window_name)
% Analyze a single time window

% Check if MSD is plateauing
msd_ratio = msd_window(end) / msd_window(1);

if msd_ratio < 1.2  % Truly plateauing
    constant = mean(msd_window);
    alpha = 0.0;
    ss_res = sum((msd_window - constant).^2);
    ss_tot = sum((msd_window - mean(msd_window)).^2);
    if ss_tot > 0
        r_squared = 1.0 - ss_res / ss_tot;
    else
        r_squared = 1.0;
    end
else
    % MSD still growing, fit power law
    log_msd = log10(msd_window);
    log_time = log10(time_window);
    
    % Linear regression
    p = polyfit(log_time, log_msd, 1);
    alpha = p(1);
    
    % Calculate R²
    y_fit = polyval(p, log_time);
    ss_res = sum((log_msd - y_fit).^2);
    ss_tot = sum((log_msd - mean(log_msd)).^2);
    if ss_tot > 0
        r_squared = 1.0 - ss_res / ss_tot;
    else
        r_squared = 1.0;
    end
end

window_result.window_name = window_name;
window_result.strategy = expected_strategy;
window_result.alpha = alpha;
window_result.r_squared = r_squared;
window_result.tau_cr = time_window(round(length(time_window)/2));
window_result.window_size = length(time_window);
window_result.msd_start = msd_window(1);
window_result.msd_end = msd_window(end);

end

function classification_result = hybrid_classification(p_value, window_results, p_c_prime)
% Hybrid classification combining physics, transition detection, and geometry

% Extract α values and R² values
alpha_values = [window_results.alpha];
r_squared_values = [window_results.r_squared];

% Calculate weighted average α (handle zero weights)
if sum(r_squared_values) > 0
    weighted_alpha = sum(alpha_values .* r_squared_values) / sum(r_squared_values);
else
    weighted_alpha = mean(alpha_values);
end

mean_r2 = mean(r_squared_values);
alpha_std = std(alpha_values);

% Step 1: Check for clear physics-based classification
if mean_r2 > 0.8
    if weighted_alpha > 0.8
        classification_result = create_result('liquid', 'physics_based', 'clear_liquid', ...
            weighted_alpha, 1.0, 0.0, true);
        return;
    elseif weighted_alpha < 0.2
        classification_result = create_result('solid', 'physics_based', 'clear_solid', ...
            weighted_alpha, 1.0, 0.0, true);
        return;
    end
end

% Step 2: Transition detection for critical region
distance_from_critical = abs(p_value - p_c_prime);
transition_behavior = detect_transition_behavior(alpha_values, r_squared_values);

if distance_from_critical < 0.08  % Wider critical region
    if transition_behavior.is_transition
        if weighted_alpha > 0.3 && weighted_alpha < 0.7
            classification_result = create_result('critical', 'transition_detected', 'gel_point_region', ...
                weighted_alpha, 0.8, 0.2, true);
            return;
        elseif transition_behavior.high_variability
            classification_result = create_result('critical', 'transition_detected', 'high_variability', ...
                weighted_alpha, 0.8, 0.2, true);
            return;
        end
    end
end

% Step 3: Adaptive critical region analysis
if adaptive_critical_region(p_value, alpha_values, p_c_prime)
    classification_result = create_result('critical', 'adaptive_critical', 'adaptive_detection', ...
        weighted_alpha, 0.7, 0.3, true);
    return;
end

% Step 4: Physics-based for intermediate cases
if mean_r2 > 0.8 && weighted_alpha > 0.4 && weighted_alpha < 0.6
    classification_result = create_result('critical', 'physics_based', 'intermediate_alpha', ...
        weighted_alpha, 0.6, 0.4, false);
    return;
end

% Step 5: Fallback to geometric classification
geometric_result = geometric_classification(p_value, p_c_prime);
classification_result = create_result(geometric_result.strategy, 'geometric_fallback', ...
    geometric_result.reason, weighted_alpha, 0.0, 1.0, false);

end

function transition_behavior = detect_transition_behavior(alpha_values, r_squared_values)
% Detect if α values suggest transition behavior

alpha_std = std(alpha_values);
mean_alpha = mean(alpha_values);

% High α variation across windows suggests transition
high_variability = alpha_std > 0.3;

% Check if different windows show different regimes
if length(alpha_values) >= 4
    early_alpha = mean(alpha_values(1:2));
    late_alpha = mean(alpha_values(end-1:end));
    alpha_difference = abs(early_alpha - late_alpha);
    regime_difference = alpha_difference > 0.4;
else
    regime_difference = false;
end

% Transition indicators
is_transition = high_variability || regime_difference;
intermediate_values = mean_alpha > 0.3 && mean_alpha < 0.7;

transition_behavior.is_transition = is_transition;
transition_behavior.high_variability = high_variability;
transition_behavior.regime_difference = regime_difference;
transition_behavior.intermediate_values = intermediate_values;
transition_behavior.alpha_std = alpha_std;

end

function is_critical = adaptive_critical_region(p_value, alpha_values, p_c_prime)
% Adaptively determine critical region width based on α behavior

base_width = 0.05;
alpha_std = std(alpha_values);
mean_alpha = mean(alpha_values);

% Expand critical region if α shows transition behavior
if mean_alpha > 0.3 && mean_alpha < 0.7
    if alpha_std > 0.2  % High variability suggests transition
        adaptive_width = base_width * (1 + alpha_std);
    else
        adaptive_width = base_width * 1.5;  % Moderate expansion
    end
else
    adaptive_width = base_width;
end

is_critical = abs(p_value - p_c_prime) < adaptive_width;

end

function geometric_result = geometric_classification(p_value, p_c_prime)
% Geometric classification (fallback method)

distance = abs(p_value - p_c_prime);

if p_value <= p_c_prime - 0.05
    geometric_result.strategy = 'liquid';
    geometric_result.reason = 'below_critical';
elseif distance < 0.05
    geometric_result.strategy = 'critical';
    geometric_result.reason = 'near_critical';
else
    geometric_result.strategy = 'solid';
    geometric_result.reason = 'above_critical';
end

end

function result = create_result(strategy, method, reason, weighted_alpha, physics_score, ...
    geometric_score, transition_detected)
% Create classification result structure

if strcmp(method, 'physics_based')
    description = sprintf('Physics-based: α = %.3f, %s', weighted_alpha, reason);
elseif strcmp(method, 'transition_detected')
    description = sprintf('Transition detected: α = %.3f, %s', weighted_alpha, reason);
elseif strcmp(method, 'adaptive_critical')
    description = sprintf('Adaptive critical: α = %.3f, %s', weighted_alpha, reason);
else
    description = sprintf('Geometric fallback: %s', reason);
end

result.strategy = strategy;
result.method = method;
result.reason = reason;
result.physics_score = physics_score;
result.geometric_score = geometric_score;
result.transition_detected = transition_detected;
result.description = description;
result.weighted_alpha = weighted_alpha;

end

function confidence = calculate_confidence(alpha_values, r_squared_values)
% Calculate confidence score based on consistency and quality

alpha_std = std(alpha_values);
consistency_score = 1.0 / (1.0 + alpha_std);
mean_r2 = mean(r_squared_values);
quality_score = mean_r2;

confidence = consistency_score * quality_score;

end

function [sigmoid_success, sigmoid_params, sigmoid_covariance, sigmoid_r2] = fit_sigmoid_function(results)
% Fit sigmoid function to α(p) data

try
    p_values = [results.p];
    alpha_values = [results.alpha_opt];
    
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
    
    % Fit sigmoid function using lsqcurvefit
    options = optimoptions('lsqcurvefit', 'Display', 'off');
    [sigmoid_params, resnorm] = lsqcurvefit(@sigmoid_function, p0, p_values, alpha_values, lb, ub, options);
    
    % Calculate covariance matrix (simplified)
    sigmoid_covariance = eye(4) * resnorm / length(p_values);
    
    % Calculate R²
    alpha_pred = sigmoid_function(sigmoid_params, p_values);
    ss_res = sum((alpha_values - alpha_pred).^2);
    ss_tot = sum((alpha_values - mean(alpha_values)).^2);
    sigmoid_r2 = 1 - ss_res / ss_tot;
    
    sigmoid_success = true;
    
catch ME
    fprintf('Sigmoid fitting failed: %s\n', ME.message);
    sigmoid_success = false;
    sigmoid_params = [];
    sigmoid_covariance = [];
    sigmoid_r2 = [];
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

function results = add_sigmoid_predictions(results, sigmoid_params)
% Add sigmoid predictions to results

if isempty(sigmoid_params)
    return;
end

p_values = [results.p];
alpha_sigmoid = sigmoid_function(sigmoid_params, p_values);

for i = 1:length(results)
    results(i).alpha_sigmoid = alpha_sigmoid(i);
    results(i).alpha_residual = results(i).alpha_opt - alpha_sigmoid(i);
end

end

function [continuous_params, analyzer] = calculate_continuous_parameters(results, sigmoid_params)
% Calculate continuous viscoelastic parameters using sigmoid α(p)

if isempty(sigmoid_params)
    continuous_params = struct();
    analyzer = struct();
    return;
end

% Create fine p-grid for continuous parameters
p_fine = linspace(min([results.p]), max([results.p]), 1000);
alpha_fine = sigmoid_function(sigmoid_params, p_fine);

% Calculate continuous parameters
G_prime_fine = calculate_G_prime(alpha_fine);
G_double_prime_fine = calculate_G_double_prime(alpha_fine);
delta_fine = calculate_phase_angle(alpha_fine);
tan_delta_fine = calculate_loss_tangent(alpha_fine);

% Store continuous parameter functions
continuous_params.p_fine = p_fine;
continuous_params.alpha_fine = alpha_fine;
continuous_params.G_prime_fine = G_prime_fine;
continuous_params.G_double_prime_fine = G_double_prime_fine;
continuous_params.delta_fine = delta_fine;
continuous_params.tan_delta_fine = tan_delta_fine;

% Create analyzer structure with functions
analyzer.alpha_sigmoid_function = @(p) sigmoid_function(sigmoid_params, p);
analyzer.calculate_G_prime = @(alpha) calculate_G_prime(alpha);
analyzer.calculate_G_double_prime = @(alpha) calculate_G_double_prime(alpha);
analyzer.calculate_phase_angle = @(alpha) calculate_phase_angle(alpha);
analyzer.calculate_loss_tangent = @(alpha) calculate_loss_tangent(alpha);

fprintf('✓ Continuous parameters calculated for %d p-values\n', length(p_fine));

end

function G_prime = calculate_G_prime(alpha_values, G0, omega)
% Calculate storage modulus G'(ω)

if nargin < 2
    G0 = 1.0;
end
if nargin < 3
    omega = 1.0;
end

G_prime = zeros(size(alpha_values));

for i = 1:length(alpha_values)
    alpha = alpha_values(i);
    if alpha <= 0
        G_prime(i) = G0;  % Solid: constant
    elseif alpha >= 1
        G_prime(i) = G0;  % Liquid: constant
    else
        G_prime(i) = G0 * (omega ^ alpha);  % Viscoelastic: power law
    end
end

end

function G_double_prime = calculate_G_double_prime(alpha_values, G0, omega)
% Calculate loss modulus G''(ω)

if nargin < 2
    G0 = 1.0;
end
if nargin < 3
    omega = 1.0;
end

G_double_prime = zeros(size(alpha_values));

for i = 1:length(alpha_values)
    alpha = alpha_values(i);
    if alpha <= 0
        G_double_prime(i) = 0.0;  % Solid: no loss
    elseif alpha >= 1
        G_double_prime(i) = G0;  % Liquid: viscous
    else
        G_double_prime(i) = G0 * (omega ^ alpha);  % Viscoelastic: power law
    end
end

end

function delta = calculate_phase_angle(alpha_values)
% Calculate phase angle δ from α

% δ = πα/2 for power law materials
delta_rad = pi * alpha_values / 2;
delta = delta_rad * 180 / pi;

end

function tan_delta = calculate_loss_tangent(alpha_values)
% Calculate loss tangent tan δ from α

% For power law materials, tan δ depends on α
tan_delta = zeros(size(alpha_values));

for i = 1:length(alpha_values)
    alpha = alpha_values(i);
    if alpha <= 0
        tan_delta(i) = 0.0;  % Solid: no loss
    elseif alpha >= 1
        tan_delta(i) = 100.0;  % Liquid: purely viscous
    else
        % For intermediate α, calculate based on material properties
        % This is a simplified model - could be refined
        tan_delta(i) = tan(pi * alpha / 2);
        % Ensure reasonable bounds
        tan_delta(i) = max(0.0, min(100.0, tan_delta(i)));
    end
end

end

function parameter_value = get_parameter_at_p(analyzer, p_value, parameter_name)
% Get continuous parameter value at specific p-value

if ~isfield(analyzer, 'continuous_params')
    parameter_value = [];
    return;
end

% Find closest p-value in fine grid
p_fine = analyzer.continuous_params.p_fine;
[~, idx] = min(abs(p_fine - p_value));

switch parameter_name
    case 'alpha'
        parameter_value = analyzer.continuous_params.alpha_fine(idx);
    case 'G_prime'
        parameter_value = analyzer.continuous_params.G_prime_fine(idx);
    case 'G_double_prime'
        parameter_value = analyzer.continuous_params.G_double_prime_fine(idx);
    case 'delta'
        parameter_value = analyzer.continuous_params.delta_fine(idx);
    case 'tan_delta'
        parameter_value = analyzer.continuous_params.tan_delta_fine(idx);
    otherwise
        parameter_value = [];
end

end
