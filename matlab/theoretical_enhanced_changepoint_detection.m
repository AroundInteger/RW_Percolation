function [results, theoretical_insights] = theoretical_enhanced_changepoint_detection(t, msd, p, p_c_prime, varargin)
% Theoretical Enhanced Changepoint Detection
% Leverages δ = πα/2 framework for advanced changepoint detection
%
% This function implements several theoretical enhancements:
% 1. δ-based region classification
% 2. Phase transition prediction
% 3. Critical scaling analysis
% 4. Viscoelastic crossover detection
% 5. Theoretical validation framework

% Parse optional parameters
parser = inputParser;
addParameter(parser, 'plot_results', true, @islogical);
addParameter(parser, 'save_plots', false, @islogical);
addParameter(parser, 'output_dir', './theoretical_changepoint_analysis', @ischar);
addParameter(parser, 'verbose', true, @islogical);
addParameter(parser, 'nu', 0.88, @isnumeric);  % 3D percolation exponent
parse(parser, varargin{:});

plot_results = parser.Results.plot_results;
save_plots = parser.Results.save_plots;
output_dir = parser.Results.output_dir;
verbose = parser.Results.verbose;
nu = parser.Results.nu;

if verbose
    fprintf('=== Theoretical Enhanced Changepoint Detection ===\n');
    fprintf('p = %.4f, p_c_prime = %.4f, ν = %.2f\n', p, p_c_prime, nu);
end

% Initialize results
results = struct();
theoretical_insights = struct();

%% 1. Theoretical Framework Analysis
if verbose, fprintf('\n--- Theoretical Framework Analysis ---\n'); end

% Calculate theoretical predictions
theoretical_insights = calculate_theoretical_predictions(p, p_c_prime, nu);

% Display theoretical predictions
if verbose
    fprintf('Theoretical Predictions:\n');
    fprintf('  Expected α: %.3f\n', theoretical_insights.expected_alpha);
    fprintf('  Expected δ: %.1f°\n', theoretical_insights.expected_delta);
    fprintf('  Regime: %s\n', theoretical_insights.regime);
    fprintf('  Distance from critical: %.4f\n', theoretical_insights.distance_from_critical);
end

%% 2. δ-Based Region Classification
if verbose, fprintf('\n--- δ-Based Region Classification ---\n'); end
[results.delta_regions, results.delta_quality] = delta_based_classification(t, msd, theoretical_insights);

%% 3. Phase Transition Detection
if verbose, fprintf('\n--- Phase Transition Detection ---\n'); end
[results.phase_transition, results.transition_quality] = detect_phase_transition(t, msd, p, p_c_prime, nu);

%% 4. Critical Scaling Analysis
if verbose, fprintf('\n--- Critical Scaling Analysis ---\n'); end
[results.critical_scaling, results.scaling_quality] = analyze_critical_scaling(t, msd, p, p_c_prime, nu);

%% 5. Viscoelastic Crossover Detection
if verbose, fprintf('\n--- Viscoelastic Crossover Detection ---\n'); end
[results.viscoelastic_crossover, results.crossover_quality] = detect_viscoelastic_crossover(t, msd, theoretical_insights);

%% 6. Theoretical Validation Framework
if verbose, fprintf('\n--- Theoretical Validation Framework ---\n'); end
[results.validation, results.validation_quality] = theoretical_validation_framework(t, msd, theoretical_insights);

%% 7. Enhanced Changepoint Detection
if verbose, fprintf('\n--- Enhanced Changepoint Detection ---\n'); end
[results.enhanced_changepoints, results.enhanced_quality] = enhanced_changepoint_detection_theoretical(t, msd, theoretical_insights);

%% Generate Plots
if plot_results
    plot_theoretical_enhanced_analysis(t, msd, results, theoretical_insights, p, p_c_prime);
    
    if save_plots
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        saveas(gcf, fullfile(output_dir, sprintf('theoretical_enhanced_p%.4f.png', p)));
        saveas(gcf, fullfile(output_dir, sprintf('theoretical_enhanced_p%.4f.fig', p)));
    end
end

%% Summary Report
if verbose
    print_theoretical_summary(results, theoretical_insights, p, p_c_prime);
end

end

%% Theoretical Framework Functions

function theoretical_insights = calculate_theoretical_predictions(p, p_c_prime, nu)
% Calculate theoretical predictions based on δ = πα/2 framework

theoretical_insights = struct();

% Calculate distance from critical point
distance_from_critical = abs(p - p_c_prime) / p_c_prime;
theoretical_insights.distance_from_critical = distance_from_critical;

% Determine regime and expected values
if p < p_c_prime - 0.05
    % Liquid regime
    theoretical_insights.regime = 'LIQUID';
    theoretical_insights.expected_alpha = 1.0;
    theoretical_insights.expected_delta = 90.0;  % degrees
    theoretical_insights.behavior = 'Normal diffusion';
    
elseif abs(p - p_c_prime) < 0.05
    % Critical regime
    theoretical_insights.regime = 'CRITICAL';
    theoretical_insights.expected_alpha = 0.5;
    theoretical_insights.expected_delta = 45.0;  % degrees
    theoretical_insights.behavior = 'Anomalous diffusion';
    
else
    % Solid regime
    theoretical_insights.regime = 'SOLID';
    theoretical_insights.expected_alpha = 0.0;
    theoretical_insights.expected_delta = 0.0;   % degrees
    theoretical_insights.behavior = 'Arrested diffusion';
end

% Critical scaling predictions
if theoretical_insights.regime == 'CRITICAL'
    % Use percolation scaling
    theoretical_insights.alpha_scaling = (1 - p/p_c_prime)^(1/nu);
    theoretical_insights.delta_scaling = pi * theoretical_insights.alpha_scaling / 2 * 180 / pi;
else
    theoretical_insights.alpha_scaling = theoretical_insights.expected_alpha;
    theoretical_insights.delta_scaling = theoretical_insights.expected_delta;
end

% Confidence intervals based on regime
switch theoretical_insights.regime
    case 'LIQUID'
        theoretical_insights.alpha_confidence = [0.8, 1.2];
        theoretical_insights.delta_confidence = [70, 110];
    case 'CRITICAL'
        theoretical_insights.alpha_confidence = [0.3, 0.7];
        theoretical_insights.delta_confidence = [25, 65];
    case 'SOLID'
        theoretical_insights.alpha_confidence = [0.0, 0.2];
        theoretical_insights.delta_confidence = [0, 20];
end

end

function [delta_regions, quality] = delta_based_classification(t, msd, theoretical_insights)
% Classify regions based on δ = πα/2 relationship

% Calculate local α and δ
log_t = log10(t);
log_msd = log10(msd);

% Local α calculation with multiple window sizes
window_sizes = [15, 20, 25];
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
            
            [fit_coeff, ~, ~, ~, stats] = polyfit(t_window, msd_window, 1);
            alpha_local(i) = fit_coeff(1);
        else
            alpha_local(i) = NaN;
        end
    end
    
    alpha_smooth = smoothdata(alpha_local, 'gaussian', 5);
    alpha_results{ws_idx} = alpha_smooth;
end

% Combine results
alpha_combined = mean(cat(2, alpha_results{:}), 2, 'omitnan');

% Calculate δ from α
delta_combined = alpha_combined * pi / 2 * 180 / pi;  % Convert to degrees

% Classify regions based on δ
delta_regions = struct();

% Find regions where δ matches theoretical expectations
expected_delta = theoretical_insights.expected_delta;
delta_tolerance = 15;  % degrees

% Liquid-like region (δ ≈ 90°)
liquid_mask = abs(delta_combined - 90) < delta_tolerance;
if any(liquid_mask)
    delta_regions.liquid_start = t(find(liquid_mask, 1));
    delta_regions.liquid_end = t(find(liquid_mask, 1, 'last'));
    delta_regions.liquid_alpha = mean(alpha_combined(liquid_mask), 'omitnan');
    delta_regions.liquid_delta = mean(delta_combined(liquid_mask), 'omitnan');
end

% Critical-like region (δ ≈ 45°)
critical_mask = abs(delta_combined - 45) < delta_tolerance;
if any(critical_mask)
    delta_regions.critical_start = t(find(critical_mask, 1));
    delta_regions.critical_end = t(find(critical_mask, 1, 'last'));
    delta_regions.critical_alpha = mean(alpha_combined(critical_mask), 'omitnan');
    delta_regions.critical_delta = mean(delta_combined(critical_mask), 'omitnan');
end

% Solid-like region (δ ≈ 0°)
solid_mask = abs(delta_combined - 0) < delta_tolerance;
if any(solid_mask)
    delta_regions.solid_start = t(find(solid_mask, 1));
    delta_regions.solid_end = t(find(solid_mask, 1, 'last'));
    delta_regions.solid_alpha = mean(alpha_combined(solid_mask), 'omitnan');
    delta_regions.solid_delta = mean(delta_combined(solid_mask), 'omitnan');
end

% Quality assessment
region_count = sum(structfun(@(x) ~isempty(x), delta_regions));
if region_count >= 2
    quality = 'EXCELLENT';
elseif region_count >= 1
    quality = 'GOOD';
else
    quality = 'POOR';
end

% Store additional details
delta_regions.alpha_combined = alpha_combined;
delta_regions.delta_combined = delta_combined;
delta_regions.region_count = region_count;

end

function [phase_transition, quality] = detect_phase_transition(t, msd, p, p_c_prime, nu)
% Detect phase transitions using theoretical framework

% Calculate local α with high resolution
log_t = log10(t);
log_msd = log10(msd);

window_size = min(15, length(t)/15);
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

alpha_smooth = smoothdata(alpha_local, 'gaussian', 3);

% Look for transitions between different α regimes
phase_transition = struct();

% Find transitions from anomalous to regular diffusion
anomalous_to_regular = find(alpha_smooth < 0.7 & [alpha_smooth(2:end); NaN] > 0.8);
if ~isempty(anomalous_to_regular)
    phase_transition.anomalous_to_regular_time = t(anomalous_to_regular(1));
    phase_transition.anomalous_to_regular_alpha_before = alpha_smooth(anomalous_to_regular(1));
    phase_transition.anomalous_to_regular_alpha_after = alpha_smooth(min(anomalous_to_regular(1)+1, length(alpha_smooth)));
end

% Find transitions from regular to plateau
regular_to_plateau = find(alpha_smooth > 0.8 & [alpha_smooth(2:end); NaN] < 0.2);
if ~isempty(regular_to_plateau)
    phase_transition.regular_to_plateau_time = t(regular_to_plateau(1));
    phase_transition.regular_to_plateau_alpha_before = alpha_smooth(regular_to_plateau(1));
    phase_transition.regular_to_plateau_alpha_after = alpha_smooth(min(regular_to_plateau(1)+1, length(alpha_smooth)));
end

% Find critical gel point (α ≈ 0.5)
critical_gel_mask = abs(alpha_smooth - 0.5) < 0.1;
if any(critical_gel_mask)
    critical_gel_idx = find(critical_gel_mask, 1);
    phase_transition.critical_gel_time = t(critical_gel_idx);
    phase_transition.critical_gel_alpha = alpha_smooth(critical_gel_idx);
    phase_transition.critical_gel_delta = alpha_smooth(critical_gel_idx) * pi / 2 * 180 / pi;
end

% Quality assessment
transition_count = sum(structfun(@(x) ~isempty(x), phase_transition));
if transition_count >= 2
    quality = 'EXCELLENT';
elseif transition_count >= 1
    quality = 'GOOD';
else
    quality = 'POOR';
end

% Store additional details
phase_transition.alpha_smooth = alpha_smooth;
phase_transition.transition_count = transition_count;

end

function [critical_scaling, quality] = analyze_critical_scaling(t, msd, p, p_c_prime, nu)
% Analyze critical scaling behavior

% Calculate local α with fine resolution
log_t = log10(t);
log_msd = log10(msd);

window_size = min(10, length(t)/20);
alpha_local = zeros(size(t));

for i = 1:length(t)
    start_idx = max(1, i - window_size/2);
    end_idx = min(length(t), i + window_size/2);
    
    if end_idx - start_idx >= 3
        t_window = log_t(start_idx:end_idx);
        msd_window = log_msd(start_idx:end_idx);
        
        [fit_coeff, ~, ~, ~, stats] = polyfit(t_window, msd_window, 1);
        alpha_local(i) = fit_coeff(1);
    else
        alpha_local(i) = NaN;
    end
end

alpha_smooth = smoothdata(alpha_local, 'gaussian', 2);

% Look for power-law scaling regions
critical_scaling = struct();

% Find regions with constant α (power-law behavior)
alpha_std = movstd(alpha_smooth, 10);
constant_alpha_mask = alpha_std < 0.05;  % Very stable α

if any(constant_alpha_mask)
    constant_regions = find_continuous_regions(constant_alpha_mask);
    
    for i = 1:length(constant_regions)
        region = constant_regions{i};
        if length(region) >= 20  % Minimum region size
            region_alpha = mean(alpha_smooth(region), 'omitnan');
            region_start = t(region(1));
            region_end = t(region(end));
            
            critical_scaling.(sprintf('power_law_region_%d', i)) = struct(...
                'start_time', region_start, ...
                'end_time', region_end, ...
                'alpha', region_alpha, ...
                'delta', region_alpha * pi / 2 * 180 / pi, ...
                'region_size', length(region));
        end
    end
end

% Analyze scaling with distance from critical point
distance_from_critical = abs(p - p_c_prime) / p_c_prime;

if distance_from_critical < 0.1  % Near critical point
    % Look for critical scaling behavior
    critical_mask = abs(alpha_smooth - 0.5) < 0.2;
    if any(critical_mask)
        critical_region = find(critical_mask);
        critical_scaling.critical_behavior = struct(...
            'alpha_mean', mean(alpha_smooth(critical_region), 'omitnan'), ...
            'alpha_std', std(alpha_smooth(critical_region), 'omitnan'), ...
            'region_size', length(critical_region));
    end
end

% Quality assessment
region_count = sum(structfun(@(x) isstruct(x), critical_scaling));
if region_count >= 2
    quality = 'EXCELLENT';
elseif region_count >= 1
    quality = 'GOOD';
else
    quality = 'POOR';
end

% Store additional details
critical_scaling.alpha_smooth = alpha_smooth;
critical_scaling.distance_from_critical = distance_from_critical;
critical_scaling.region_count = region_count;

end

function [viscoelastic_crossover, quality] = detect_viscoelastic_crossover(t, msd, theoretical_insights)
% Detect viscoelastic crossover using theoretical framework

% Calculate local α and δ
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
delta_smooth = alpha_smooth * pi / 2 * 180 / pi;

% Look for viscoelastic crossover (δ ≈ 45°)
viscoelastic_crossover = struct();

% Find regions where δ is close to 45° (viscoelastic behavior)
viscoelastic_mask = abs(delta_smooth - 45) < 10;  % ±10° tolerance

if any(viscoelastic_mask)
    viscoelastic_regions = find_continuous_regions(viscoelastic_mask);
    
    for i = 1:length(viscoelastic_regions)
        region = viscoelastic_regions{i};
        if length(region) >= 15  % Minimum region size
            region_alpha = mean(alpha_smooth(region), 'omitnan');
            region_delta = mean(delta_smooth(region), 'omitnan');
            region_start = t(region(1));
            region_end = t(region(end));
            
            viscoelastic_crossover.(sprintf('viscoelastic_region_%d', i)) = struct(...
                'start_time', region_start, ...
                'end_time', region_end, ...
                'alpha', region_alpha, ...
                'delta', region_delta, ...
                'region_size', length(region));
        end
    end
end

% Look for transitions to/from viscoelastic behavior
% Transition from liquid-like to viscoelastic
liquid_to_viscoelastic = find(delta_smooth > 70 & [delta_smooth(2:end); NaN] < 60);
if ~isempty(liquid_to_viscoelastic)
    viscoelastic_crossover.liquid_to_viscoelastic_time = t(liquid_to_viscoelastic(1));
    viscoelastic_crossover.liquid_to_viscoelastic_delta_before = delta_smooth(liquid_to_viscoelastic(1));
    viscoelastic_crossover.liquid_to_viscoelastic_delta_after = delta_smooth(min(liquid_to_viscoelastic(1)+1, length(delta_smooth)));
end

% Transition from viscoelastic to solid-like
viscoelastic_to_solid = find(delta_smooth > 30 & [delta_smooth(2:end); NaN] < 20);
if ~isempty(viscoelastic_to_solid)
    viscoelastic_crossover.viscoelastic_to_solid_time = t(viscoelastic_to_solid(1));
    viscoelastic_crossover.viscoelastic_to_solid_delta_before = delta_smooth(viscoelastic_to_solid(1));
    viscoelastic_crossover.viscoelastic_to_solid_delta_after = delta_smooth(min(viscoelastic_to_solid(1)+1, length(delta_smooth)));
end

% Quality assessment
region_count = sum(structfun(@(x) isstruct(x), viscoelastic_crossover));
transition_count = sum(structfun(@(x) ~isempty(x) && ~isstruct(x), viscoelastic_crossover));

if region_count >= 1 && transition_count >= 1
    quality = 'EXCELLENT';
elseif region_count >= 1 || transition_count >= 1
    quality = 'GOOD';
else
    quality = 'POOR';
end

% Store additional details
viscoelastic_crossover.alpha_smooth = alpha_smooth;
viscoelastic_crossover.delta_smooth = delta_smooth;
viscoelastic_crossover.region_count = region_count;
viscoelastic_crossover.transition_count = transition_count;

end

function [validation, quality] = theoretical_validation_framework(t, msd, theoretical_insights)
% Validate results against theoretical framework

validation = struct();

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
delta_smooth = alpha_smooth * pi / 2 * 180 / pi;

% Validation metrics
validation.alpha_mean = mean(alpha_smooth, 'omitnan');
validation.alpha_std = std(alpha_smooth, 'omitnan');
validation.delta_mean = mean(delta_smooth, 'omitnan');
validation.delta_std = std(delta_smooth, 'omitnan');

% Check if results are within theoretical confidence intervals
alpha_in_confidence = validation.alpha_mean >= theoretical_insights.alpha_confidence(1) && ...
                     validation.alpha_mean <= theoretical_insights.alpha_confidence(2);
delta_in_confidence = validation.delta_mean >= theoretical_insights.delta_confidence(1) && ...
                     validation.delta_mean <= theoretical_insights.delta_confidence(2);

validation.alpha_theoretical_match = alpha_in_confidence;
validation.delta_theoretical_match = delta_in_confidence;

% Calculate agreement with theoretical predictions
validation.alpha_agreement = 1 - abs(validation.alpha_mean - theoretical_insights.expected_alpha) / theoretical_insights.expected_alpha;
validation.delta_agreement = 1 - abs(validation.delta_mean - theoretical_insights.expected_delta) / theoretical_insights.expected_delta;

% Overall validation score
validation.overall_score = (validation.alpha_agreement + validation.delta_agreement) / 2;

% Quality assessment
if validation.overall_score > 0.8 && alpha_in_confidence && delta_in_confidence
    quality = 'EXCELLENT';
elseif validation.overall_score > 0.6 && (alpha_in_confidence || delta_in_confidence)
    quality = 'GOOD';
elseif validation.overall_score > 0.4
    quality = 'MARGINAL';
else
    quality = 'POOR';
end

% Store additional details
validation.alpha_smooth = alpha_smooth;
validation.delta_smooth = delta_smooth;
validation.theoretical_insights = theoretical_insights;

end

function [enhanced_changepoints, quality] = enhanced_changepoint_detection_theoretical(t, msd, theoretical_insights)
% Enhanced changepoint detection using theoretical framework

% Calculate local α with multiple methods
log_t = log10(t);
log_msd = log10(msd);

% Method 1: Moving window α
window_size = min(20, length(t)/10);
alpha_moving = zeros(size(t));

for i = 1:length(t)
    start_idx = max(1, i - window_size/2);
    end_idx = min(length(t), i + window_size/2);
    
    if end_idx - start_idx >= 5
        t_window = log_t(start_idx:end_idx);
        msd_window = log_msd(start_idx:end_idx);
        
        [fit_coeff, ~, ~, ~, stats] = polyfit(t_window, msd_window, 1);
        alpha_moving(i) = fit_coeff(1);
    else
        alpha_moving(i) = NaN;
    end
end

alpha_moving_smooth = smoothdata(alpha_moving, 'gaussian', 5);

% Method 2: Second derivative approach
log_t_interp = linspace(min(log_t), max(log_t), 1e5);
log_msd_interp = interp1(log_t, log_msd, log_t_interp, 'cubic');

d_log_msd = diff(log_msd_interp) ./ diff(log_t_interp);
d2_log_msd = diff(d_log_msd) ./ diff(log_t_interp(1:end-1));
d2_smooth = smoothdata(d2_log_msd, 'gaussian', 10);

% Find zero crossings
zero_crossings = find(diff(sign(d2_smooth)) ~= 0);

% Method 3: Theoretical prediction-based
expected_alpha = theoretical_insights.expected_alpha;
alpha_diff = abs(alpha_moving_smooth - expected_alpha);
[~, best_theoretical_idx] = min(alpha_diff);

% Combine methods for enhanced detection
enhanced_changepoints = struct();

% Primary changepoint based on theoretical expectations
enhanced_changepoints.primary_changepoint = t(best_theoretical_idx);
enhanced_changepoints.primary_alpha = alpha_moving_smooth(best_theoretical_idx);
enhanced_changepoints.primary_delta = enhanced_changepoints.primary_alpha * pi / 2 * 180 / pi;

% Secondary changepoints from second derivative
if ~isempty(zero_crossings)
    enhanced_changepoints.secondary_changepoints = 10.^log_t_interp(zero_crossings);
    enhanced_changepoints.secondary_count = length(zero_crossings);
else
    enhanced_changepoints.secondary_changepoints = [];
    enhanced_changepoints.secondary_count = 0;
end

% Confidence assessment
alpha_error = alpha_diff(best_theoretical_idx);
if alpha_error < 0.1
    confidence = 'HIGH';
elseif alpha_error < 0.2
    confidence = 'MEDIUM';
else
    confidence = 'LOW';
end

enhanced_changepoints.confidence = confidence;
enhanced_changepoints.alpha_error = alpha_error;

% Quality assessment
if strcmp(confidence, 'HIGH') && enhanced_changepoints.secondary_count >= 1
    quality = 'EXCELLENT';
elseif strcmp(confidence, 'HIGH') || enhanced_changepoints.secondary_count >= 2
    quality = 'GOOD';
elseif strcmp(confidence, 'MEDIUM')
    quality = 'MARGINAL';
else
    quality = 'POOR';
end

% Store additional details
enhanced_changepoints.alpha_moving_smooth = alpha_moving_smooth;
enhanced_changepoints.d2_smooth = d2_smooth;
enhanced_changepoints.zero_crossings = zero_crossings;
enhanced_changepoints.expected_alpha = expected_alpha;

end

%% Utility Functions

function regions = find_continuous_regions(mask)
% Find continuous regions in a boolean mask

regions = {};
current_region = [];

for i = 1:length(mask)
    if mask(i)
        current_region = [current_region, i];
    else
        if ~isempty(current_region)
            regions{end+1} = current_region;
            current_region = [];
        end
    end
end

% Handle region at the end
if ~isempty(current_region)
    regions{end+1} = current_region;
end

end

%% Plotting Functions

function plot_theoretical_enhanced_analysis(t, msd, results, theoretical_insights, p, p_c_prime)
% Create comprehensive theoretical analysis plots

figure('Position', [100, 100, 1400, 1000]);

% Main MSD plot with theoretical regions
subplot(2, 4, 1);
loglog(t, msd, 'b-', 'LineWidth', 2);
hold on;

% Plot theoretical regions if available
if isfield(results, 'delta_regions')
    colors = {'g', 'm', 'c'};
    region_names = {'liquid', 'critical', 'solid'};
    
    for i = 1:length(region_names)
        region_name = region_names{i};
        if isfield(results.delta_regions, [region_name '_start'])
            start_time = results.delta_regions.([region_name '_start']);
            end_time = results.delta_regions.([region_name '_end']);
            
            plot([start_time, start_time], ylim, '--', 'Color', colors{i}, 'LineWidth', 2);
            plot([end_time, end_time], ylim, '--', 'Color', colors{i}, 'LineWidth', 2);
            
            text(start_time, max(msd), sprintf('%s\n(α=%.2f)', region_name, results.delta_regions.([region_name '_alpha'])), ...
                'Rotation', 90, 'FontSize', 8, 'Color', colors{i});
        end
    end
end

xlabel('Time τ');
ylabel('MSD');
title(sprintf('MSD with Theoretical Regions (p=%.4f)', p));
grid on;

% α vs time
subplot(2, 4, 2);
if isfield(results, 'delta_regions') && isfield(results.delta_regions, 'alpha_combined')
    plot(t, results.delta_regions.alpha_combined, 'b-', 'LineWidth', 2);
    hold on;
    plot(xlim, [theoretical_insights.expected_alpha, theoretical_insights.expected_alpha], 'r--', 'LineWidth', 2);
    plot(xlim, theoretical_insights.alpha_confidence, 'r:', 'LineWidth', 1);
    xlabel('Time τ');
    ylabel('α');
    title('Local α vs Time');
    legend('Measured', 'Expected', 'Confidence', 'Location', 'best');
    grid on;
end

% δ vs time
subplot(2, 4, 3);
if isfield(results, 'delta_regions') && isfield(results.delta_regions, 'delta_combined')
    plot(t, results.delta_regions.delta_combined, 'g-', 'LineWidth', 2);
    hold on;
    plot(xlim, [theoretical_insights.expected_delta, theoretical_insights.expected_delta], 'r--', 'LineWidth', 2);
    plot(xlim, theoretical_insights.delta_confidence, 'r:', 'LineWidth', 1);
    xlabel('Time τ');
    ylabel('δ (degrees)');
    title('Local δ vs Time');
    legend('Measured', 'Expected', 'Confidence', 'Location', 'best');
    grid on;
end

% Phase transitions
subplot(2, 4, 4);
if isfield(results, 'phase_transition') && isfield(results.phase_transition, 'alpha_smooth')
    plot(t, results.phase_transition.alpha_smooth, 'm-', 'LineWidth', 2);
    hold on;
    
    % Mark transitions
    if isfield(results.phase_transition, 'anomalous_to_regular_time')
        plot([results.phase_transition.anomalous_to_regular_time, results.phase_transition.anomalous_to_regular_time], ylim, 'r--', 'LineWidth', 2);
        text(results.phase_transition.anomalous_to_regular_time, max(results.phase_transition.alpha_smooth), 'A→R', 'Rotation', 90, 'FontSize', 8);
    end
    
    if isfield(results.phase_transition, 'critical_gel_time')
        plot([results.phase_transition.critical_gel_time, results.phase_transition.critical_gel_time], ylim, 'g--', 'LineWidth', 2);
        text(results.phase_transition.critical_gel_time, 0.5, 'Gel', 'Rotation', 90, 'FontSize', 8);
    end
    
    xlabel('Time τ');
    ylabel('α');
    title('Phase Transitions');
    grid on;
end

% Critical scaling
subplot(2, 4, 5);
if isfield(results, 'critical_scaling') && isfield(results.critical_scaling, 'alpha_smooth')
    plot(t, results.critical_scaling.alpha_smooth, 'c-', 'LineWidth', 2);
    hold on;
    
    % Mark power-law regions
    region_fields = fieldnames(results.critical_scaling);
    power_law_fields = region_fields(startsWith(region_fields, 'power_law_region_'));
    
    for i = 1:length(power_law_fields)
        region = results.critical_scaling.(power_law_fields{i});
        plot([region.start_time, region.end_time], [region.alpha, region.alpha], 'r-', 'LineWidth', 3);
        text(region.start_time, region.alpha, sprintf('α=%.2f', region.alpha), 'FontSize', 8);
    end
    
    xlabel('Time τ');
    ylabel('α');
    title('Critical Scaling');
    grid on;
end

% Viscoelastic crossover
subplot(2, 4, 6);
if isfield(results, 'viscoelastic_crossover') && isfield(results.viscoelastic_crossover, 'delta_smooth')
    plot(t, results.viscoelastic_crossover.delta_smooth, 'k-', 'LineWidth', 2);
    hold on;
    plot(xlim, [45, 45], 'r--', 'LineWidth', 2);
    plot(xlim, [35, 55], 'r:', 'LineWidth', 1);
    
    % Mark viscoelastic regions
    region_fields = fieldnames(results.viscoelastic_crossover);
    viscoelastic_fields = region_fields(startsWith(region_fields, 'viscoelastic_region_'));
    
    for i = 1:length(viscoelastic_fields)
        region = results.viscoelastic_crossover.(viscoelastic_fields{i});
        plot([region.start_time, region.end_time], [region.delta, region.delta], 'g-', 'LineWidth', 3);
        text(region.start_time, region.delta, sprintf('δ=%.1f°', region.delta), 'FontSize', 8);
    end
    
    xlabel('Time τ');
    ylabel('δ (degrees)');
    title('Viscoelastic Crossover');
    legend('Measured', 'Viscoelastic', 'Tolerance', 'Location', 'best');
    grid on;
end

% Theoretical validation
subplot(2, 4, 7);
if isfield(results, 'validation') && isfield(results.validation, 'alpha_smooth')
    plot(t, results.validation.alpha_smooth, 'b-', 'LineWidth', 2);
    hold on;
    plot(xlim, [results.validation.alpha_mean, results.validation.alpha_mean], 'r--', 'LineWidth', 2);
    plot(xlim, theoretical_insights.alpha_confidence, 'r:', 'LineWidth', 1);
    
    xlabel('Time τ');
    ylabel('α');
    title(sprintf('Validation (Score: %.2f)', results.validation.overall_score));
    legend('Measured', 'Mean', 'Confidence', 'Location', 'best');
    grid on;
end

% Enhanced changepoints
subplot(2, 4, 8);
if isfield(results, 'enhanced_changepoints') && isfield(results.enhanced_changepoints, 'alpha_moving_smooth')
    plot(t, results.enhanced_changepoints.alpha_moving_smooth, 'b-', 'LineWidth', 2);
    hold on;
    plot([results.enhanced_changepoints.primary_changepoint, results.enhanced_changepoints.primary_changepoint], ylim, 'r--', 'LineWidth', 2);
    plot(xlim, [results.enhanced_changepoints.expected_alpha, results.enhanced_changepoints.expected_alpha], 'g--', 'LineWidth', 2);
    
    % Mark secondary changepoints
    if ~isempty(results.enhanced_changepoints.secondary_changepoints)
        for i = 1:length(results.enhanced_changepoints.secondary_changepoints)
            plot([results.enhanced_changepoints.secondary_changepoints(i), results.enhanced_changepoints.secondary_changepoints(i)], ylim, 'm:', 'LineWidth', 1);
        end
    end
    
    xlabel('Time τ');
    ylabel('α');
    title(sprintf('Enhanced Changepoints (%s)', results.enhanced_changepoints.confidence));
    legend('Measured', 'Primary', 'Expected', 'Secondary', 'Location', 'best');
    grid on;
end

sgtitle(sprintf('Theoretical Enhanced Analysis (p=%.4f, p_c''=%.4f, Regime: %s)', p, p_c_prime, theoretical_insights.regime));

end

%% Summary Function

function print_theoretical_summary(results, theoretical_insights, p, p_c_prime)
% Print comprehensive theoretical summary

fprintf('\n=== THEORETICAL ENHANCED ANALYSIS SUMMARY ===\n');
fprintf('p = %.4f, p_c_prime = %.4f\n', p, p_c_prime);
fprintf('Regime: %s\n', theoretical_insights.regime);
fprintf('Expected α: %.3f, Expected δ: %.1f°\n\n', theoretical_insights.expected_alpha, theoretical_insights.expected_delta);

% δ-based regions
if isfield(results, 'delta_regions')
    fprintf('δ-Based Regions (%s):\n', results.delta_regions.region_count);
    region_fields = fieldnames(results.delta_regions);
    for i = 1:length(region_fields)
        field = region_fields{i};
        if contains(field, '_alpha') && ~strcmp(field, 'alpha_combined')
            region_name = strrep(field, '_alpha', '');
            alpha_val = results.delta_regions.(field);
            delta_val = results.delta_regions.(strrep(field, '_alpha', '_delta'));
            fprintf('  %s: α = %.3f, δ = %.1f°\n', region_name, alpha_val, delta_val);
        end
    end
end

% Phase transitions
if isfield(results, 'phase_transition')
    fprintf('\nPhase Transitions (%s):\n', results.phase_transition.transition_count);
    transition_fields = fieldnames(results.phase_transition);
    for i = 1:length(transition_fields)
        field = transition_fields{i};
        if contains(field, '_time')
            transition_name = strrep(field, '_time', '');
            time_val = results.phase_transition.(field);
            fprintf('  %s: τ = %.2e\n', transition_name, time_val);
        end
    end
end

% Critical scaling
if isfield(results, 'critical_scaling')
    fprintf('\nCritical Scaling (%s regions):\n', results.critical_scaling.region_count);
    region_fields = fieldnames(results.critical_scaling);
    power_law_fields = region_fields(startsWith(region_fields, 'power_law_region_'));
    for i = 1:length(power_law_fields)
        region = results.critical_scaling.(power_law_fields{i});
        fprintf('  Region %d: α = %.3f, δ = %.1f°, τ = [%.2e, %.2e]\n', ...
            i, region.alpha, region.delta, region.start_time, region.end_time);
    end
end

% Viscoelastic crossover
if isfield(results, 'viscoelastic_crossover')
    fprintf('\nViscoelastic Crossover (%s regions, %s transitions):\n', ...
        results.viscoelastic_crossover.region_count, results.viscoelastic_crossover.transition_count);
    region_fields = fieldnames(results.viscoelastic_crossover);
    viscoelastic_fields = region_fields(startsWith(region_fields, 'viscoelastic_region_'));
    for i = 1:length(viscoelastic_fields)
        region = results.viscoelastic_crossover.(viscoelastic_fields{i});
        fprintf('  Region %d: α = %.3f, δ = %.1f°, τ = [%.2e, %.2e]\n', ...
            i, region.alpha, region.delta, region.start_time, region.end_time);
    end
end

% Validation
if isfield(results, 'validation')
    fprintf('\nTheoretical Validation:\n');
    fprintf('  α: %.3f ± %.3f (expected: %.3f) - %s\n', ...
        results.validation.alpha_mean, results.validation.alpha_std, ...
        theoretical_insights.expected_alpha, ...
        results.validation.alpha_theoretical_match);
    fprintf('  δ: %.1f° ± %.1f° (expected: %.1f°) - %s\n', ...
        results.validation.delta_mean, results.validation.delta_std, ...
        theoretical_insights.expected_delta, ...
        results.validation.delta_theoretical_match);
    fprintf('  Overall Score: %.3f\n', results.validation.overall_score);
end

% Enhanced changepoints
if isfield(results, 'enhanced_changepoints')
    fprintf('\nEnhanced Changepoints (%s confidence):\n', results.enhanced_changepoints.confidence);
    fprintf('  Primary: τ = %.2e, α = %.3f, δ = %.1f°\n', ...
        results.enhanced_changepoints.primary_changepoint, ...
        results.enhanced_changepoints.primary_alpha, ...
        results.enhanced_changepoints.primary_delta);
    fprintf('  Secondary: %d changepoints\n', results.enhanced_changepoints.secondary_count);
    fprintf('  α Error: %.3f\n', results.enhanced_changepoints.alpha_error);
end

fprintf('\n=== END THEORETICAL SUMMARY ===\n');

end 