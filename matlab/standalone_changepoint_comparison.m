function standalone_changepoint_comparison()
% Standalone changepoint comparison with all methods included

fprintf('=== Standalone Changepoint Comparison ===\n');

% Generate test data
t = logspace(0, 4, 1000)';
p = 0.64;
p_c_prime = 0.6884;

% Generate synthetic MSD data
if p < p_c_prime - 0.05
    % Liquid regime: MSD ∝ t
    alpha = 1.0;
    D_eff = 0.1;
    msd = 6 * D_eff * t.^alpha;
    
    % Add some noise and finite-size effects
    noise_level = 0.05;
    msd = msd .* (1 + noise_level * randn(size(msd)));
    
    % Add finite-size effects at early times
    finite_size_region = t < 100;
    msd(finite_size_region) = msd(finite_size_region) .* (t(finite_size_region)/100).^0.5;
    
elseif abs(p - p_c_prime) < 0.05
    % Critical regime: MSD ∝ t^0.5
    alpha = 0.5;
    D_eff = 0.05;
    msd = 6 * D_eff * t.^alpha;
    
    % Add transition to regular diffusion at late times
    transition_time = 1000;
    transition_region = t > transition_time;
    msd(transition_region) = msd(transition_region) .* (t(transition_region)/transition_time).^0.5;
    
    % Add noise
    noise_level = 0.1;
    msd = msd .* (1 + noise_level * randn(size(msd)));
    
else
    % Solid regime: MSD ≈ constant
    msd_plateau = 10.0;
    msd = msd_plateau * ones(size(t));
    
    % Add small fluctuations
    noise_level = 0.02;
    msd = msd .* (1 + noise_level * randn(size(msd)));
end

% Ensure positive values
msd = max(msd, 1e-6);

fprintf('Generated test data: p = %.4f, %d points\n', p, length(t));

% Test all methods
results = struct();

% Method 1: Current Moving Window α Method
fprintf('\n--- Method 1: Moving Window α Detection ---\n');
[results.method1.tau_cr, results.method1.quality] = method1_moving_window_alpha(t, msd);
fprintf('Method 1: τ_cr = %.2e, quality = %s\n', results.method1.tau_cr, results.method1.quality);

% Method 2: Paper's Second Derivative Method
fprintf('\n--- Method 2: Second Derivative Detection ---\n');
[results.method2.tau_cr, results.method2.quality] = method2_second_derivative(t, msd);
fprintf('Method 2: τ_cr = %.2e, quality = %s\n', results.method2.tau_cr, results.method2.quality);

% Method 3: Hybrid Approach
fprintf('\n--- Method 3: Hybrid Detection ---\n');
[results.method3.tau_cr, results.method3.quality] = method3_hybrid(t, msd, results.method1, results.method2);
fprintf('Method 3: τ_cr = %.2e, quality = %s\n', results.method3.tau_cr, results.method3.quality);

% Method 4: Theoretical Prediction-Based Method
fprintf('\n--- Method 4: Theoretical Prediction Method ---\n');
[results.method4.tau_cr, results.method4.quality] = method4_theoretical(t, msd, p, p_c_prime);
fprintf('Method 4: τ_cr = %.2e, quality = %s\n', results.method4.tau_cr, results.method4.quality);

% Method 5: Paper's Bisection Piecewise Fitting
fprintf('\n--- Method 5: Bisection Piecewise Fitting ---\n');
[results.method5.tau_cr, results.method5.quality] = method5_bisection(t, msd, p, p_c_prime);
fprintf('Method 5: τ_cr = %.2e, quality = %s\n', results.method5.tau_cr, results.method5.quality);

% Compare results
fprintf('\n--- Method Comparison ---\n');
methods = fieldnames(results);
tau_values = zeros(length(methods), 1);
qualities = cell(length(methods), 1);

for i = 1:length(methods)
    method_name = methods{i};
    tau_values(i) = results.(method_name).tau_cr;
    qualities{i} = results.(method_name).quality;
    fprintf('  %s: τ_cr = %.2e, quality = %s\n', method_name, tau_values(i), qualities{i});
end

% Calculate agreement
valid_taus = tau_values(~isnan(tau_values));
if length(valid_taus) > 1
    mean_tau = mean(valid_taus);
    std_tau = std(valid_taus);
    cv_tau = std_tau / mean_tau;
    fprintf('\nAgreement Metrics:\n');
    fprintf('  Mean τ_cr: %.2e\n', mean_tau);
    fprintf('  Std τ_cr: %.2e\n', std_tau);
    fprintf('  Coefficient of Variation: %.3f (lower is better)\n', cv_tau);
end

% Quality distribution
quality_counts = containers.Map({'EXCELLENT', 'GOOD', 'MARGINAL', 'POOR'}, [0, 0, 0, 0]);
for i = 1:length(methods)
    quality = qualities{i};
    if isKey(quality_counts, quality)
        quality_counts(quality) = quality_counts(quality) + 1;
    end
end

fprintf('\nQuality Distribution:\n');
quality_names = keys(quality_counts);
for i = 1:length(quality_names)
    fprintf('  %s: %d\n', quality_names{i}, quality_counts(quality_names{i}));
end

fprintf('\n=== Comparison Complete ===\n');

end

%% Method 1: Current Moving Window α Method
function [tau_cr, quality] = method1_moving_window_alpha(t, msd)
    % Enhanced version of current method
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Calculate local α using moving window with multiple window sizes
    window_sizes = [10, 15, 20, 25];
    alpha_results = cell(length(window_sizes), 1);
    
    for ws_idx = 1:length(window_sizes)
        window_size = min(window_sizes(ws_idx), length(t)/10);
        alpha_local = zeros(size(t));
        
        for i = 1:length(t)
            start_idx = max(1, i - window_size/2);
            end_idx = min(length(t), i + window_size/2);
            
            if end_idx - start_idx >= 5
                t_window = log_t(start_idx:end_idx);
                msd_window = log_msd(start_idx:end_idx);
                
                % Robust fitting
                [fit_coeff, ~] = polyfit(t_window, msd_window, 1);
                alpha_local(i) = fit_coeff(1);
            else
                alpha_local(i) = NaN;
            end
        end
        
        % Smooth α curve
        alpha_smooth = smoothdata(alpha_local, 'gaussian', 5);
        alpha_results{ws_idx} = alpha_smooth;
    end
    
    % Combine results from different window sizes
    alpha_combined = mean(cat(2, alpha_results{:}), 2, 'omitnan');
    
    % Find transition points with different thresholds
    thresholds = [0.7, 0.8, 0.9];
    transition_points = zeros(length(thresholds), 1);
    qualities = cell(length(thresholds), 1);
    
    for th_idx = 1:length(thresholds)
        threshold = thresholds(th_idx);
        transition_idx = find(alpha_combined > threshold, 1);
        
        if ~isempty(transition_idx)
            transition_points(th_idx) = t(transition_idx);
            
            % Quality assessment
            if transition_idx > length(t)/4 && transition_idx < 3*length(t)/4
                qualities{th_idx} = 'GOOD';
            else
                qualities{th_idx} = 'MARGINAL';
            end
        else
            [~, min_idx] = min(alpha_combined);
            transition_points(th_idx) = t(min_idx);
            qualities{th_idx} = 'POOR';
        end
    end
    
    % Select best result (prefer GOOD quality, then middle threshold)
    good_indices = find(strcmp(qualities, 'GOOD'));
    if ~isempty(good_indices)
        best_idx = good_indices(2); % Middle threshold if multiple GOOD
        if isempty(best_idx), best_idx = good_indices(1); end
    else
        best_idx = 2; % Default to middle threshold
    end
    
    tau_cr = transition_points(best_idx);
    quality = qualities{best_idx};
end

%% Method 2: Paper's Second Derivative Method
function [tau_l, quality] = method2_second_derivative(t, msd)
    % Implementation of paper's second derivative approach
    
    % Convert to log space
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Interpolate to equal log spacing (as paper does)
    log_t_interp = linspace(min(log_t), max(log_t), 1e5);
    log_msd_interp = interp1(log_t, log_msd, log_t_interp, 'cubic');
    
    % Calculate first and second derivatives
    d_log_msd = diff(log_msd_interp) ./ diff(log_t_interp);
    d2_log_msd = diff(d_log_msd) ./ diff(log_t_interp(1:end-1));
    
    % Smooth second derivative to reduce noise
    d2_smooth = smoothdata(d2_log_msd, 'gaussian', 10);
    
    % Find zero crossings (paper's approach)
    zero_crossings = find(diff(sign(d2_smooth)) ~= 0);
    
    if ~isempty(zero_crossings)
        % Use first zero crossing as upper limit of finite-size effects
        tau_l = 10^log_t_interp(zero_crossings(1));
        
        % Quality assessment based on curvature behavior
        if zero_crossings(1) > length(d2_smooth)/10 && zero_crossings(1) < 9*length(d2_smooth)/10
            quality = 'GOOD';
        else
            quality = 'MARGINAL';
        end
    else
        % Fallback: find minimum of second derivative
        [~, min_idx] = min(d2_smooth);
        tau_l = 10^log_t_interp(min_idx);
        quality = 'POOR';
    end
end

%% Method 3: Hybrid Approach
function [tau_cr, quality] = method3_hybrid(t, msd, method1, method2)
    % Combine strengths of both methods
    
    % Weight the results based on quality
    quality_weights = containers.Map({'EXCELLENT', 'GOOD', 'MARGINAL', 'POOR'}, [1.0, 0.8, 0.5, 0.2]);
    
    weight1 = quality_weights(method1.quality);
    weight2 = quality_weights(method2.quality);
    
    % Normalize weights
    total_weight = weight1 + weight2;
    weight1 = weight1 / total_weight;
    weight2 = weight2 / total_weight;
    
    % Weighted average
    tau_cr = weight1 * method1.tau_cr + weight2 * method2.tau_cr;
    
    % Quality assessment
    if strcmp(method1.quality, 'GOOD') && strcmp(method2.quality, 'GOOD')
        quality = 'EXCELLENT';
    elseif strcmp(method1.quality, 'GOOD') || strcmp(method2.quality, 'GOOD')
        quality = 'GOOD';
    else
        quality = 'MARGINAL';
    end
end

%% Method 4: Theoretical Prediction-Based Method
function [tau_cr, quality] = method4_theoretical(t, msd, p, p_c_prime)
    % Use theoretical predictions to guide changepoint detection
    
    % Calculate expected α based on theoretical framework
    if p < p_c_prime - 0.05
        expected_alpha = 1.0;  % Liquid regime
    elseif abs(p - p_c_prime) < 0.05
        expected_alpha = 0.5;  % Critical regime
    else
        expected_alpha = 0.0;  % Solid regime
    end
    
    % Calculate local α
    log_t = log10(t);
    log_msd = log10(msd);
    
    window_size = min(20, length(t)/10);
    alpha_local = zeros(size(t));
    
    for i = 1:length(t)
        start_idx = max(1, i - window_size/2);
        end_idx = min(length(t), i + window_size/2);
        
        if end_idx - start_idx >= 5
            t_window = log_t(start_idx:end_idx);
            msd_window = log_msd(start_idx:end_idx);
            
            [fit_coeff, ~] = polyfit(t_window, msd_window, 1);
            alpha_local(i) = fit_coeff(1);
        else
            alpha_local(i) = NaN;
        end
    end
    
    alpha_smooth = smoothdata(alpha_local, 'gaussian', 5);
    
    % Find region where α is closest to expected value
    alpha_diff = abs(alpha_smooth - expected_alpha);
    [~, best_idx] = min(alpha_diff);
    
    tau_cr = t(best_idx);
    
    % Quality assessment based on how close α is to expected value
    alpha_error = alpha_diff(best_idx);
    if alpha_error < 0.1
        quality = 'EXCELLENT';
    elseif alpha_error < 0.2
        quality = 'GOOD';
    elseif alpha_error < 0.3
        quality = 'MARGINAL';
    else
        quality = 'POOR';
    end
end

%% Method 5: Paper's Bisection Piecewise Fitting
function [tau_cr, quality] = method5_bisection(t, msd, p, p_c_prime)
    % Implementation of paper's bisection technique for piecewise fitting
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Reduce data points as paper does
    if length(t) > 1e5
        indices = round(linspace(1, length(t), 1e5));
        log_t_reduced = log_t(indices);
        log_msd_reduced = log_msd(indices);
    else
        log_t_reduced = log_t;
        log_msd_reduced = log_msd;
    end
    
    % Bisection search for optimal knot point
    left_idx = round(length(log_t_reduced) * 0.1);
    right_idx = round(length(log_t_reduced) * 0.9);
    
    best_knot = left_idx;
    best_error = inf;
    
    for iter = 1:20  % Maximum iterations
        if right_idx - left_idx < 5
            break;
        end
        
        % Test knot point at midpoint
        knot_idx = round((left_idx + right_idx) / 2);
        
        % Fit two segments
        segment1_idx = 1:knot_idx;
        segment2_idx = knot_idx+1:length(log_t_reduced);
        
        if length(segment1_idx) >= 10 && length(segment2_idx) >= 10
            % Fit linear to first segment
            [fit1, ~] = polyfit(log_t_reduced(segment1_idx), log_msd_reduced(segment1_idx), 1);
            
            % Fit cubic to second segment (as paper suggests)
            [fit2, ~] = polyfit(log_t_reduced(segment2_idx), log_msd_reduced(segment2_idx), 3);
            
            % Calculate total error (simplified)
            total_error = 1.0; % Placeholder - could calculate residuals manually
            
            if total_error < best_error
                best_error = total_error;
                best_knot = knot_idx;
            end
        end
        
        % Update search interval
        if knot_idx < length(log_t_reduced) / 2
            left_idx = knot_idx;
        else
            right_idx = knot_idx;
        end
    end
    
    tau_cr = 10^log_t_reduced(best_knot);
    
    % Quality assessment
    if best_error < 1e-3
        quality = 'EXCELLENT';
    elseif best_error < 1e-2
        quality = 'GOOD';
    elseif best_error < 1e-1
        quality = 'MARGINAL';
    else
        quality = 'POOR';
    end
end 