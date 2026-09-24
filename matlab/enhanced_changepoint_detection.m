function [results, comparison] = enhanced_changepoint_detection(t, msd, p, p_c_prime, varargin)
% Enhanced Changepoint Detection Framework
% Implements multiple methods for robust changepoint detection
%
% Methods:
% 1. Current method (moving window α)
% 2. Paper's second derivative method
% 3. Hybrid approach
% 4. Theoretical prediction-based method
% 5. Bisection-based piecewise fitting (paper's approach)
%
% Inputs:
%   t: time vector
%   msd: mean squared displacement vector
%   p: percolation probability
%   p_c_prime: critical percolation probability
%   varargin: optional parameters
%
% Outputs:
%   results: struct with results from each method
%   comparison: struct with method comparison metrics

% Parse optional parameters
parser = inputParser;
addParameter(parser, 'plot_results', true, @islogical);
addParameter(parser, 'save_plots', false, @islogical);
addParameter(parser, 'output_dir', './changepoint_analysis', @ischar);
addParameter(parser, 'verbose', true, @islogical);
parse(parser, varargin{:});

plot_results = parser.Results.plot_results;
save_plots = parser.Results.save_plots;
output_dir = parser.Results.output_dir;
verbose = parser.Results.verbose;

if verbose
    fprintf('=== Enhanced Changepoint Detection Analysis ===\n');
    fprintf('p = %.4f, p_c_prime = %.4f\n', p, p_c_prime);
    fprintf('Data points: %d\n', length(t));
end

% Initialize results structure
results = struct();
comparison = struct();

%% Method 1: Current Moving Window α Method
if verbose, fprintf('\n--- Method 1: Moving Window α Detection ---\n'); end
[results.method1.tau_cr, results.method1.quality] = ...
    detect_liquid_crossover_parallel(t, msd);
results.method1.details = struct(); % Empty details for compatibility

%% Method 2: Paper's Second Derivative Method
if verbose, fprintf('\n--- Method 2: Second Derivative Detection ---\n'); end
[results.method2.tau_cr, results.method2.quality, results.method2.details] = ...
    detect_curvature_changepoint(t, msd);

%% Method 3: Hybrid Approach
if verbose, fprintf('\n--- Method 3: Hybrid Detection ---\n'); end
[results.method3.tau_cr, results.method3.quality, results.method3.details] = ...
    hybrid_changepoint_detection(t, msd, results.method1, results.method2);

%% Method 4: Theoretical Prediction-Based Method
if verbose, fprintf('\n--- Method 4: Theoretical Prediction Method ---\n'); end
[results.method4.tau_cr, results.method4.quality, results.method4.details] = ...
    theoretical_changepoint_detection(t, msd, p, p_c_prime);

%% Method 5: Paper's Bisection Piecewise Fitting
if verbose, fprintf('\n--- Method 5: Bisection Piecewise Fitting ---\n'); end
[results.method5.tau_cr, results.method5.quality, results.method5.details] = ...
    bisection_piecewise_fitting(t, msd, p, p_c_prime);

%% Method 6: Enhanced Region Classification
if verbose, fprintf('\n--- Method 6: Enhanced Region Classification ---\n'); end
[results.method6.regions, results.method6.quality, results.method6.details] = ...
    enhanced_region_classification(t, msd, p, p_c_prime);

%% Compare Results
if verbose, fprintf('\n--- Method Comparison ---\n'); end
comparison = compare_changepoint_methods(results, t, msd, p, p_c_prime);

%% Generate Plots
if plot_results
    plot_changepoint_comparison(t, msd, results, comparison, p, p_c_prime);
    
    if save_plots
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        saveas(gcf, fullfile(output_dir, sprintf('changepoint_comparison_p%.4f.png', p)));
        saveas(gcf, fullfile(output_dir, sprintf('changepoint_comparison_p%.4f.fig', p)));
    end
end

%% Summary Report
if verbose
    print_changepoint_summary(results, comparison, p, p_c_prime);
end

end

%% Method 1: Current Moving Window α Method (Enhanced)
function [tau_cr, quality, details] = detect_liquid_crossover_parallel(t, msd)
    % Enhanced version of your current method
    
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
                [fit_coeff, ~, ~, ~, stats] = polyfit(t_window, msd_window, 1);
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
    
    % Store details
    details.alpha_combined = alpha_combined;
    details.transition_points = transition_points;
    details.qualities = qualities;
    details.best_idx = best_idx;
    details.window_sizes = window_sizes;
end

%% Method 2: Paper's Second Derivative Method
function [tau_l, quality, details] = detect_curvature_changepoint(t, msd)
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
    
    % Find regions based on paper's criteria
    % 1. Finite-size effects: d2 < 0 initially
    % 2. Transition: d2 crosses 0
    % 3. Regular diffusion: d2 > 0
    
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
    
    % Store details
    details.d2_smooth = d2_smooth;
    details.zero_crossings = zero_crossings;
    details.log_t_interp = log_t_interp;
    details.d_log_msd = d_log_msd;
end

%% Method 3: Hybrid Approach
function [tau_cr, quality, details] = hybrid_changepoint_detection(t, msd, method1, method2)
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
    
    % Store details
    details.weight1 = weight1;
    details.weight2 = weight2;
    details.method1_tau = method1.tau_cr;
    details.method2_tau = method2.tau_cr;
end

%% Method 4: Theoretical Prediction-Based Method
function [tau_cr, quality, details] = theoretical_changepoint_detection(t, msd, p, p_c_prime)
    % Use theoretical predictions to guide changepoint detection
    
    % Calculate expected α based on theoretical framework
    if p < p_c_prime - 0.05
        expected_alpha = 1.0;  % Liquid regime
        region_type = 'LIQUID';
    elseif abs(p - p_c_prime) < 0.05
        expected_alpha = 0.5;  % Critical regime
        region_type = 'CRITICAL';
    else
        expected_alpha = 0.0;  % Solid regime
        region_type = 'SOLID';
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
            
            [fit_coeff, ~, ~, ~, stats] = polyfit(t_window, msd_window, 1);
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
    
    % Store details
    details.expected_alpha = expected_alpha;
    details.region_type = region_type;
    details.alpha_smooth = alpha_smooth;
    details.alpha_error = alpha_error;
    details.best_idx = best_idx;
end

%% Method 5: Paper's Bisection Piecewise Fitting
function [tau_cr, quality, details] = bisection_piecewise_fitting(t, msd, p, p_c_prime)
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
            [fit1, ~, ~, ~, stats1] = polyfit(log_t_reduced(segment1_idx), log_msd_reduced(segment1_idx), 1);
            
            % Fit cubic to second segment (as paper suggests)
            [fit2, ~, ~, ~, stats2] = polyfit(log_t_reduced(segment2_idx), log_msd_reduced(segment2_idx), 3);
            
            % Calculate total error
            total_error = stats1.normr^2 + stats2.normr^2;
            
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
    
    % Store details
    details.best_knot = best_knot;
    details.best_error = best_error;
    details.log_t_reduced = log_t_reduced;
    details.log_msd_reduced = log_msd_reduced;
end

%% Method 6: Enhanced Region Classification
function [regions, quality, details] = enhanced_region_classification(t, msd, p, p_c_prime)
    % Enhanced region classification using theoretical framework
    
    % Calculate local α and second derivative
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Local α calculation
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
    
    % Second derivative calculation
    d_log_msd = diff(log_msd) ./ diff(log_t);
    d2_log_msd = diff(d_log_msd) ./ diff(log_t(1:end-1));
    d2_smooth = smoothdata(d2_log_msd, 'gaussian', 5);
    
    % Pad d2 to match original length
    d2_padded = [d2_smooth(1); d2_smooth; d2_smooth(end)];
    
    % Classify regions based on theoretical framework
    regions = struct();
    
    % Find finite-size effects region (α < 1, decreasing)
    finite_size_mask = alpha_smooth < 0.9 & [diff(alpha_smooth); 0] < 0;
    if any(finite_size_mask)
        regions.finite_size_start = t(find(finite_size_mask, 1));
        regions.finite_size_end = t(find(finite_size_mask, 1, 'last'));
    end
    
    % Find anomalous diffusion region (constant α < 1)
    alpha_std = movstd(alpha_smooth, 10);
    anomalous_mask = alpha_smooth < 0.9 & alpha_std < 0.1;
    if any(anomalous_mask)
        regions.anomalous_start = t(find(anomalous_mask, 1));
        regions.anomalous_end = t(find(anomalous_mask, 1, 'last'));
    end
    
    % Find regular diffusion region (α ≈ 1)
    regular_mask = alpha_smooth > 0.8 & alpha_smooth < 1.2;
    if any(regular_mask)
        regions.regular_start = t(find(regular_mask, 1));
        regions.regular_end = t(find(regular_mask, 1, 'last'));
    end
    
    % Find plateau region (α ≈ 0)
    plateau_mask = alpha_smooth < 0.2;
    if any(plateau_mask)
        regions.plateau_start = t(find(plateau_mask, 1));
        regions.plateau_end = t(find(plateau_mask, 1, 'last'));
    end
    
    % Quality assessment
    region_count = sum(structfun(@(x) ~isempty(x), regions));
    if region_count >= 3
        quality = 'EXCELLENT';
    elseif region_count >= 2
        quality = 'GOOD';
    elseif region_count >= 1
        quality = 'MARGINAL';
    else
        quality = 'POOR';
    end
    
    % Store details
    details.alpha_smooth = alpha_smooth;
    details.d2_padded = d2_padded;
    details.region_count = region_count;
end

%% Comparison Function
function comparison = compare_changepoint_methods(results, t, msd, p, p_c_prime)
    % Compare all methods and provide metrics
    
    methods = fieldnames(results);
    n_methods = length(methods);
    
    comparison = struct();
    comparison.methods = methods;
    comparison.tau_values = zeros(n_methods, 1);
    comparison.qualities = cell(n_methods, 1);
    
    % Extract results
    for i = 1:n_methods
        method_name = methods{i};
        if isfield(results.(method_name), 'tau_cr')
            comparison.tau_values(i) = results.(method_name).tau_cr;
        else
            comparison.tau_values(i) = NaN;
        end
        comparison.qualities{i} = results.(method_name).quality;
    end
    
    % Calculate agreement metrics
    valid_taus = comparison.tau_values(~isnan(comparison.tau_values));
    if length(valid_taus) > 1
        comparison.mean_tau = mean(valid_taus);
        comparison.std_tau = std(valid_taus);
        comparison.cv_tau = comparison.std_tau / comparison.mean_tau;
        
        % Agreement score (lower is better)
        comparison.agreement_score = comparison.cv_tau;
    else
        comparison.mean_tau = NaN;
        comparison.std_tau = NaN;
        comparison.cv_tau = NaN;
        comparison.agreement_score = NaN;
    end
    
    % Quality distribution
    quality_counts = containers.Map({'EXCELLENT', 'GOOD', 'MARGINAL', 'POOR'}, [0, 0, 0, 0]);
    for i = 1:n_methods
        quality = comparison.qualities{i};
        if isKey(quality_counts, quality)
            quality_counts(quality) = quality_counts(quality) + 1;
        end
    end
    comparison.quality_distribution = quality_counts;
    
    % Best method selection
    quality_scores = containers.Map({'EXCELLENT', 'GOOD', 'MARGINAL', 'POOR'}, [4, 3, 2, 1]);
    method_scores = zeros(n_methods, 1);
    
    for i = 1:n_methods
        quality = comparison.qualities{i};
        if isKey(quality_scores, quality)
            method_scores(i) = quality_scores(quality);
        end
    end
    
    [~, best_idx] = max(method_scores);
    comparison.best_method = methods{best_idx};
    comparison.best_tau = comparison.tau_values(best_idx);
end

%% Plotting Function
function plot_changepoint_comparison(t, msd, results, comparison, p, p_c_prime)
    % Create comprehensive comparison plots
    
    figure('Position', [100, 100, 1200, 800]);
    
    % Main MSD plot with changepoints
    subplot(2, 3, 1);
    loglog(t, msd, 'b-', 'LineWidth', 2);
    hold on;
    
    colors = {'r', 'g', 'm', 'c', 'k'};
    methods = fieldnames(results);
    
    for i = 1:length(methods)
        method_name = methods{i};
        if isfield(results.(method_name), 'tau_cr')
            tau_cr = results.(method_name).tau_cr;
            quality = results.(method_name).quality;
            
            % Plot changepoint
            plot([tau_cr, tau_cr], ylim, '--', 'Color', colors{mod(i-1, length(colors))+1}, 'LineWidth', 2);
            
            % Add label
            text(tau_cr, max(msd), sprintf('%s\n(%s)', method_name, quality), ...
                'Rotation', 90, 'FontSize', 8, 'Color', colors{mod(i-1, length(colors))+1});
        end
    end
    
    xlabel('Time τ');
    ylabel('MSD');
    title(sprintf('MSD with Changepoints (p=%.4f)', p));
    grid on;
    
    % Tau comparison
    subplot(2, 3, 2);
    valid_indices = ~isnan(comparison.tau_values);
    if any(valid_indices)
        bar(comparison.tau_values(valid_indices));
        set(gca, 'XTickLabel', comparison.methods(valid_indices));
        ylabel('τ_{cr}');
        title('Changepoint Comparison');
        grid on;
    end
    
    % Quality distribution
    subplot(2, 3, 3);
    quality_dist = comparison.quality_distribution;
    quality_names = keys(quality_dist);
    quality_counts = values(quality_dist);
    bar(cell2mat(quality_counts));
    set(gca, 'XTickLabel', quality_names);
    ylabel('Count');
    title('Quality Distribution');
    grid on;
    
    % Method 1 details (Moving Window α)
    if isfield(results, 'method1')
        subplot(2, 3, 4);
        if isfield(results.method1.details, 'alpha_combined')
            plot(t, results.method1.details.alpha_combined, 'b-', 'LineWidth', 2);
            hold on;
            plot([results.method1.tau_cr, results.method1.tau_cr], ylim, 'r--', 'LineWidth', 2);
            xlabel('Time τ');
            ylabel('α');
            title('Method 1: Moving Window α');
            grid on;
        end
    end
    
    % Method 2 details (Second Derivative)
    if isfield(results, 'method2')
        subplot(2, 3, 5);
        if isfield(results.method2.details, 'd2_smooth')
            plot(results.method2.details.log_t_interp(1:end-2), results.method2.details.d2_smooth, 'g-', 'LineWidth', 2);
            hold on;
            plot([log10(results.method2.tau_cr), log10(results.method2.tau_cr)], ylim, 'r--', 'LineWidth', 2);
            plot(xlim, [0, 0], 'k:', 'LineWidth', 1);
            xlabel('log_{10}(τ)');
            ylabel('d²(log MSD)/d(log τ)²');
            title('Method 2: Second Derivative');
            grid on;
        end
    end
    
    % Method 4 details (Theoretical)
    if isfield(results, 'method4')
        subplot(2, 3, 6);
        if isfield(results.method4.details, 'alpha_smooth')
            plot(t, results.method4.details.alpha_smooth, 'm-', 'LineWidth', 2);
            hold on;
            plot([results.method4.tau_cr, results.method4.tau_cr], ylim, 'r--', 'LineWidth', 2);
            plot(xlim, [results.method4.details.expected_alpha, results.method4.details.expected_alpha], 'k:', 'LineWidth', 1);
            xlabel('Time τ');
            ylabel('α');
            title(sprintf('Method 4: Theoretical (α=%.1f)', results.method4.details.expected_alpha));
            grid on;
        end
    end
    
    sgtitle(sprintf('Enhanced Changepoint Detection Comparison (p=%.4f, p_c''=%.4f)', p, p_c_prime));
end

%% Summary Function
function print_changepoint_summary(results, comparison, p, p_c_prime)
    % Print comprehensive summary
    
    fprintf('\n=== CHANGEPOINT DETECTION SUMMARY ===\n');
    fprintf('p = %.4f, p_c_prime = %.4f\n\n', p, p_c_prime);
    
    methods = fieldnames(results);
    fprintf('Method Results:\n');
    fprintf('%-25s %-15s %-10s\n', 'Method', 'τ_cr', 'Quality');
    fprintf('%-25s %-15s %-10s\n', '------------------------', '---------------', '----------');
    
    for i = 1:length(methods)
        method_name = methods{i};
        if isfield(results.(method_name), 'tau_cr')
            tau_cr = results.(method_name).tau_cr;
            quality = results.(method_name).quality;
            fprintf('%-25s %-15.2e %-10s\n', method_name, tau_cr, quality);
        end
    end
    
    fprintf('\nComparison Metrics:\n');
    if ~isnan(comparison.agreement_score)
        fprintf('Mean τ_cr: %.2e\n', comparison.mean_tau);
        fprintf('Std τ_cr: %.2e\n', comparison.std_tau);
        fprintf('Coefficient of Variation: %.3f\n', comparison.cv_tau);
        fprintf('Agreement Score: %.3f (lower is better)\n', comparison.agreement_score);
    end
    
    fprintf('Best Method: %s (τ_cr = %.2e)\n', comparison.best_method, comparison.best_tau);
    
    fprintf('\nQuality Distribution:\n');
    quality_dist = comparison.quality_distribution;
    quality_names = keys(quality_dist);
    for i = 1:length(quality_names)
        fprintf('  %s: %d\n', quality_names{i}, quality_dist(quality_names{i}));
    end
    
    fprintf('\n=== END SUMMARY ===\n');
end 