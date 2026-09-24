% robust_liquid_regime_analysis.m
% Robust analysis for p < p_c' (liquid regime)
% Focus on identifying regular diffusion region (α ≈ 1.0) after cross-over point

clear; close all; clc;

fprintf('=== ROBUST LIQUID REGIME ANALYSIS ===\n');
fprintf('Specialized analysis for p < p_c'' (liquid regime)\n');
fprintf('Target: Identify regular diffusion region with α ≈ 1.0\n\n');

% Key parameters
p_c_prime = 0.6884;
p_values = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6];  % All < p_c'
L = 500;
LW = 20000;
NW = 500;
n_realizations = 3;

% Initialize results
liquid_results = struct();

fprintf('Testing p values: [');
fprintf('%.1f ', p_values);
fprintf('] (all < p_c'' = %.4f)\n\n', p_c_prime);

for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('=== Processing p = %.1f (Liquid Regime) ===\n', p);
    
    % Run multiple realizations
    for run = 1:n_realizations
        fprintf('  Realization %d/%d...\n', run, n_realizations);
        
        % Run simulation
        [t, msd, trajectory_stats] = run_liquid_simulation(p, L, LW, NW, run);
        
        % Robust analysis for liquid regime
        [alpha_est, alpha_err, quality, analysis_details] = analyze_liquid_regime(t, msd, p, p_c_prime);
        
        % Store results
        liquid_results(p_idx, run).p = p;
        liquid_results(p_idx, run).run = run;
        liquid_results(p_idx, run).alpha = alpha_est;
        liquid_results(p_idx, run).alpha_err = alpha_err;
        liquid_results(p_idx, run).quality = quality;
        liquid_results(p_idx, run).analysis_details = analysis_details;
        liquid_results(p_idx, run).trajectory_stats = trajectory_stats;
    end
    
    % Calculate ensemble statistics for this p value
    liquid_results(p_idx) = calculate_liquid_ensemble_stats(liquid_results(p_idx, :));
    
    fprintf('  Ensemble Results: α = %.3f ± %.3f (%s)\n', ...
        liquid_results(p_idx).alpha_mean, liquid_results(p_idx).alpha_se, ...
        liquid_results(p_idx).quality);
end

% Analyze overall liquid regime behavior
liquid_analysis = analyze_liquid_regime_behavior(liquid_results);

% Create comprehensive plots
create_liquid_regime_plots(liquid_results, liquid_analysis);

% Save results
save('robust_liquid_regime_results.mat', 'liquid_results', 'liquid_analysis');

fprintf('\n=== LIQUID REGIME ANALYSIS COMPLETE ===\n');
fprintf('Results saved to robust_liquid_regime_results.mat\n');

% Display summary
display_liquid_regime_summary(liquid_results, liquid_analysis);

%% Helper Functions

function [t, msd, trajectory_stats] = run_liquid_simulation(p, L, LW, NW, run)
    % Run simulation for liquid regime analysis
    
    % Set random seed for reproducibility
    rng(run);
    
    % Create lattice
    lattice = create_liquid_lattice(p, L);
    
    % Initialize walkers
    walkers = initialize_liquid_walkers(lattice, NW);
    
    % Run walks
    [trajectories, success_rates] = run_liquid_walks(lattice, walkers, LW);
    
    % Calculate MSD
    [t, msd] = calculate_liquid_msd(trajectories);
    
    % Calculate trajectory statistics
    trajectory_stats.success_rate = mean(success_rates);
    trajectory_stats.effective_diffusion = calculate_effective_diffusion(msd, t);
    trajectory_stats.total_moves = sum(success_rates) * LW;
end

function [alpha_est, alpha_err, quality, analysis_details] = analyze_liquid_regime(t, msd, p, p_c_prime)
    % Specialized analysis for liquid regime (p < p_c')
    % Focus on identifying regular diffusion region (α ≈ 1.0)
    
    % Step 1: Detect cross-over point
    [tau_cr, crossover_quality] = detect_liquid_crossover(t, msd);
    
    % Step 2: Identify regular diffusion region
    [regular_window, window_quality] = identify_regular_diffusion_region(t, msd, tau_cr);
    
    % Step 3: Estimate α in regular diffusion region
    if ~isempty(regular_window)
        [alpha_est, alpha_err, fit_quality] = estimate_alpha_regular_region(t, msd, regular_window);
    else
        alpha_est = NaN;
        alpha_err = NaN;
        fit_quality = 'INSUFFICIENT_DATA';
    end
    
    % Step 4: Quality assessment for liquid regime
    quality = assess_liquid_quality(alpha_est, alpha_err, fit_quality, crossover_quality, window_quality);
    
    % Step 5: Store analysis details
    analysis_details.tau_cr = tau_cr;
    analysis_details.crossover_quality = crossover_quality;
    analysis_details.regular_window = regular_window;
    analysis_details.window_quality = window_quality;
    analysis_details.fit_quality = fit_quality;
    analysis_details.expected_alpha = 1.0;
end

function [tau_cr, quality] = detect_liquid_crossover(t, msd)
    % Detect cross-over from anomalous to regular diffusion
    % This is critical for liquid regime analysis
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Calculate local α using moving window
    window_size = min(20, length(t)/10);
    alpha_local = zeros(size(t));
    
    for i = 1:length(t)
        start_idx = max(1, i - window_size/2);
        end_idx = min(length(t), i + window_size/2);
        
        if end_idx - start_idx >= 5  % Minimum points for fit
            t_window = log_t(start_idx:end_idx);
            msd_window = log_msd(start_idx:end_idx);
            
            % Linear fit
            [fit_coeff, ~] = polyfit(t_window, msd_window, 1);
            alpha_local(i) = fit_coeff(1);
        else
            alpha_local(i) = NaN;
        end
    end
    
    % Find regions
    % Anomalous region: α < 1 and relatively constant
    % Regular region: α ≈ 1
    
    % Smooth α curve
    alpha_smooth = smoothdata(alpha_local, 'gaussian', 5);
    
    % Find transition point (where α starts approaching 1)
    threshold = 0.8;  % α threshold for regular diffusion
    transition_idx = find(alpha_smooth > threshold, 1);
    
    if ~isempty(transition_idx)
        tau_cr = t(transition_idx);
        
        % Quality assessment
        if transition_idx > length(t)/4 && transition_idx < 3*length(t)/4
            quality = 'GOOD';
        else
            quality = 'MARGINAL';
        end
    else
        % Fallback: use minimum α location
        [~, min_idx] = min(alpha_smooth);
        tau_cr = t(min_idx);
        quality = 'POOR';
    end
end

function [regular_window, quality] = identify_regular_diffusion_region(t, msd, tau_cr)
    % Identify the regular diffusion region after cross-over point
    
    % Start after cross-over point
    start_idx = find(t > tau_cr, 1);
    
    if isempty(start_idx)
        regular_window = [];
        quality = 'NO_CROSSOVER';
        return;
    end
    
    % Use last 1/3 of data after cross-over for stability
    end_idx = length(t);
    min_points = 20;
    
    if end_idx - start_idx < min_points
        regular_window = [];
        quality = 'INSUFFICIENT_DATA';
        return;
    end
    
    % Test different window sizes
    window_sizes = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0];  % Fraction of remaining data
    best_window = [];
    best_quality = 0;
    
    for ws = window_sizes
        window_end = start_idx + round((end_idx - start_idx) * ws);
        if window_end > length(t)
            window_end = length(t);
        end
        
        test_window = start_idx:window_end;
        
        if length(test_window) >= min_points
            % Test α in this window
            t_test = t(test_window);
            msd_test = msd(test_window);
            
            [alpha_test, r_squared] = fit_alpha_linear(t_test, msd_test);
            
            % Quality metric: how close to α = 1.0 and how good the fit
            quality_metric = r_squared * (1 - abs(alpha_test - 1.0));
            
            if quality_metric > best_quality
                best_quality = quality_metric;
                best_window = test_window;
            end
        end
    end
    
    regular_window = best_window;
    
    % Assess quality
    if isempty(regular_window)
        quality = 'NO_VALID_WINDOW';
    elseif best_quality > 0.8
        quality = 'EXCELLENT';
    elseif best_quality > 0.6
        quality = 'GOOD';
    elseif best_quality > 0.4
        quality = 'ACCEPTABLE';
    else
        quality = 'POOR';
    end
end

function [alpha_est, alpha_err, quality] = estimate_alpha_regular_region(t, msd, window)
    % Estimate α in the regular diffusion region using multiple methods
    
    t_window = t(window);
    msd_window = msd(window);
    
    % Method 1: Direct linear fit
    [alpha_1, r_squared_1] = fit_alpha_linear(t_window, msd_window);
    
    % Method 2: Moving window average
    alpha_moving = calculate_moving_alpha(t_window, msd_window);
    alpha_2 = mean(alpha_moving);
    alpha_2_std = std(alpha_moving);
    
    % Method 3: Derivative method
    alpha_3 = calculate_derivative_alpha(t_window, msd_window);
    
    % Combine methods (weighted by reliability)
    weights = [r_squared_1, 1/(1 + alpha_2_std), 0.5];  % Derivative method less reliable
    weights = weights / sum(weights);
    
    alphas = [alpha_1, alpha_2, alpha_3];
    alpha_est = sum(alphas .* weights);
    alpha_err = sqrt(sum((weights .* (alphas - alpha_est)).^2));
    
    % Quality assessment
    if r_squared_1 > 0.95 && alpha_err < 0.1 && abs(alpha_est - 1.0) < 0.2
        quality = 'EXCELLENT';
    elseif r_squared_1 > 0.90 && alpha_err < 0.2 && abs(alpha_est - 1.0) < 0.3
        quality = 'GOOD';
    elseif r_squared_1 > 0.85 && alpha_err < 0.3 && abs(alpha_est - 1.0) < 0.4
        quality = 'ACCEPTABLE';
    else
        quality = 'POOR';
    end
end

function quality = assess_liquid_quality(alpha_est, alpha_err, fit_quality, crossover_quality, window_quality)
    % Assess overall quality for liquid regime analysis
    
    if isnan(alpha_est)
        quality = 'INSUFFICIENT_DATA';
        return;
    end
    
    % Quality scores
    quality_scores = zeros(1, 4);
    
    % 1. α closeness to 1.0
    alpha_deviation = abs(alpha_est - 1.0);
    if alpha_deviation < 0.1
        quality_scores(1) = 1.0;
    elseif alpha_deviation < 0.2
        quality_scores(1) = 0.8;
    elseif alpha_deviation < 0.3
        quality_scores(1) = 0.6;
    else
        quality_scores(1) = 0.2;
    end
    
    % 2. α error
    if alpha_err < 0.1
        quality_scores(2) = 1.0;
    elseif alpha_err < 0.2
        quality_scores(2) = 0.8;
    elseif alpha_err < 0.3
        quality_scores(2) = 0.6;
    else
        quality_scores(2) = 0.3;
    end
    
    % 3. Fit quality
    if strcmp(fit_quality, 'EXCELLENT')
        quality_scores(3) = 1.0;
    elseif strcmp(fit_quality, 'GOOD')
        quality_scores(3) = 0.8;
    elseif strcmp(fit_quality, 'ACCEPTABLE')
        quality_scores(3) = 0.6;
    else
        quality_scores(3) = 0.2;
    end
    
    % 4. Cross-over and window quality
    if strcmp(crossover_quality, 'GOOD') && strcmp(window_quality, 'EXCELLENT')
        quality_scores(4) = 1.0;
    elseif strcmp(crossover_quality, 'GOOD') && strcmp(window_quality, 'GOOD')
        quality_scores(4) = 0.8;
    elseif strcmp(crossover_quality, 'MARGINAL') && strcmp(window_quality, 'ACCEPTABLE')
        quality_scores(4) = 0.6;
    else
        quality_scores(4) = 0.3;
    end
    
    % Overall quality
    overall_score = mean(quality_scores);
    
    if overall_score > 0.8
        quality = 'EXCELLENT';
    elseif overall_score > 0.6
        quality = 'GOOD';
    elseif overall_score > 0.4
        quality = 'ACCEPTABLE';
    else
        quality = 'POOR';
    end
end

function [alpha, r_squared] = fit_alpha_linear(t, msd)
    % Fit α using linear regression on log-log plot
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    [fit_coeff, fit_stats] = polyfit(log_t, log_msd, 1);
    alpha = fit_coeff(1);
    r_squared = fit_stats.R^2;
end

function alpha_moving = calculate_moving_alpha(t, msd)
    % Calculate α using moving window approach
    
    window_size = min(15, length(t)/5);
    alpha_moving = zeros(1, length(t) - window_size + 1);
    
    for i = 1:length(alpha_moving)
        t_window = t(i:i+window_size-1);
        msd_window = msd(i:i+window_size-1);
        
        [alpha_moving(i), ~] = fit_alpha_linear(t_window, msd_window);
    end
end

function alpha_deriv = calculate_derivative_alpha(t, msd)
    % Calculate α using derivative method
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Calculate derivative
    d_log_msd = diff(log_msd) ./ diff(log_t);
    
    % Use median for stability
    alpha_deriv = median(d_log_msd);
end

function lattice = create_liquid_lattice(p, L)
    % Create lattice for liquid regime
    
    lattice = rand(L, L, L) > p;
end

function walkers = initialize_liquid_walkers(lattice, NW)
    % Initialize walkers on free sites
    
    [free_x, free_y, free_z] = find(lattice);
    
    if length(free_x) < NW
        error('Not enough free sites for %d walkers', NW);
    end
    
    % Randomly select starting positions
    indices = randperm(length(free_x), NW);
    walkers = [free_x(indices), free_y(indices), free_z(indices)];
end

function [trajectories, success_rates] = run_liquid_walks(lattice, walkers, LW)
    % Run random walks for liquid regime
    
    [L, ~, ~] = size(lattice);
    NW = size(walkers, 1);
    
    trajectories = zeros(NW, LW, 3);
    success_rates = zeros(NW, 1);
    
    % Possible moves (6 directions)
    moves = [1,0,0; -1,0,0; 0,1,0; 0,-1,0; 0,0,1; 0,0,-1];
    
    for w = 1:NW
        pos = walkers(w, :);
        trajectory = zeros(LW, 3);
        success_count = 0;
        
        for step = 1:LW
            trajectory(step, :) = pos;
            
            % Try to move
            move_idx = randi(6);
            new_pos = pos + moves(move_idx, :);
            
            % Periodic boundary conditions
            new_pos = mod(new_pos - 1, L) + 1;
            
            % Check if move is allowed
            if lattice(new_pos(1), new_pos(2), new_pos(3))
                pos = new_pos;
                success_count = success_count + 1;
            end
        end
        
        trajectories(w, :, :) = trajectory;
        success_rates(w) = success_count / LW;
    end
end

function [t, msd] = calculate_liquid_msd(trajectories)
    % Calculate MSD for liquid regime
    
    [NW, LW, ~] = size(trajectories);
    
    % Time points
    t = 1:LW;
    
    % Calculate MSD
    msd = zeros(1, LW);
    
    for lag = 1:LW
        msd_lag = 0;
        count = 0;
        
        for w = 1:NW
            for start = 1:(LW - lag + 1)
                end_pos = start + lag - 1;
                if end_pos <= LW
                    dr = trajectories(w, end_pos, :) - trajectories(w, start, :);
                    msd_lag = msd_lag + sum(dr.^2);
                    count = count + 1;
                end
            end
        end
        
        if count > 0
            msd(lag) = msd_lag / count;
        end
    end
end

function effective_diffusion = calculate_effective_diffusion(msd, t)
    % Calculate effective diffusion coefficient
    
    % Use late time behavior
    late_idx = round(length(t) * 0.7):length(t);
    t_late = t(late_idx);
    msd_late = msd(late_idx);
    
    % Linear fit to MSD vs t
    [fit_coeff, ~] = polyfit(t_late, msd_late, 1);
    effective_diffusion = fit_coeff(1) / 6;  % D = MSD/(6t)
end

function ensemble_stats = calculate_liquid_ensemble_stats(runs)
    % Calculate ensemble statistics for liquid regime
    
    alphas = [runs.alpha];
    valid_alphas = alphas(~isnan(alphas));
    
    if isempty(valid_alphas)
        ensemble_stats.alpha_mean = NaN;
        ensemble_stats.alpha_se = NaN;
        ensemble_stats.quality = 'INSUFFICIENT_DATA';
    else
        ensemble_stats.alpha_mean = mean(valid_alphas);
        ensemble_stats.alpha_se = std(valid_alphas) / sqrt(length(valid_alphas));
        
        % Overall quality
        if length(valid_alphas) >= 2
            if abs(ensemble_stats.alpha_mean - 1.0) < 0.2 && ensemble_stats.alpha_se < 0.1
                ensemble_stats.quality = 'EXCELLENT';
            elseif abs(ensemble_stats.alpha_mean - 1.0) < 0.3 && ensemble_stats.alpha_se < 0.2
                ensemble_stats.quality = 'GOOD';
            elseif abs(ensemble_stats.alpha_mean - 1.0) < 0.4 && ensemble_stats.alpha_se < 0.3
                ensemble_stats.quality = 'ACCEPTABLE';
            else
                ensemble_stats.quality = 'POOR';
            end
        else
            ensemble_stats.quality = 'INSUFFICIENT_DATA';
        end
    end
end

function liquid_analysis = analyze_liquid_regime_behavior(liquid_results)
    % Analyze overall behavior of liquid regime
    
    p_vals = [liquid_results.p];
    alpha_means = [liquid_results.alpha_mean];
    alpha_errors = [liquid_results.alpha_se];
    qualities = {liquid_results.quality};
    
    % Extract valid data
    valid_idx = ~isnan(alpha_means);
    p_valid = p_vals(valid_idx);
    alpha_valid = alpha_means(valid_idx);
    alpha_err_valid = alpha_errors(valid_idx);
    
    liquid_analysis.p_values = p_valid;
    liquid_analysis.alpha_means = alpha_valid;
    liquid_analysis.alpha_errors = alpha_err_valid;
    
    % Analyze trend
    if length(p_valid) >= 3
        % Linear fit
        [fit_coeff, fit_stats] = polyfit(p_valid, alpha_valid, 1);
        liquid_analysis.alpha_slope = fit_coeff(1);
        liquid_analysis.alpha_intercept = fit_coeff(2);
        liquid_analysis.r_squared = fit_stats.R^2;
        
        % Test if α ≈ 1.0 across liquid regime
        alpha_deviation = abs(alpha_valid - 1.0);
        liquid_analysis.mean_deviation = mean(alpha_deviation);
        liquid_analysis.max_deviation = max(alpha_deviation);
        
        % Quality assessment
        if liquid_analysis.mean_deviation < 0.2 && liquid_analysis.r_squared > 0.5
            liquid_analysis.overall_quality = 'EXCELLENT';
        elseif liquid_analysis.mean_deviation < 0.3 && liquid_analysis.r_squared > 0.3
            liquid_analysis.overall_quality = 'GOOD';
        else
            liquid_analysis.overall_quality = 'POOR';
        end
    else
        liquid_analysis.overall_quality = 'INSUFFICIENT_DATA';
    end
end

function create_liquid_regime_plots(liquid_results, liquid_analysis)
    % Create comprehensive plots for liquid regime analysis
    
    figure('Position', [100, 100, 1200, 800]);
    
    % Plot 1: α vs p
    subplot(2, 3, 1);
    p_vals = [liquid_results.p];
    alpha_means = [liquid_results.alpha_mean];
    alpha_errors = [liquid_results.alpha_se];
    
    errorbar(p_vals, alpha_means, alpha_errors, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
    hold on;
    plot([0, 0.7], [1, 1], 'r--', 'LineWidth', 2);  % Theoretical α = 1.0
    xlabel('p');
    ylabel('α');
    title('Liquid Regime: α vs p');
    grid on;
    legend('Simulation', 'Theory (α = 1.0)', 'Location', 'best');
    
    % Plot 2: Quality distribution
    subplot(2, 3, 2);
    qualities = {liquid_results.quality};
    quality_counts = zeros(1, 4);
    quality_labels = {'EXCELLENT', 'GOOD', 'ACCEPTABLE', 'POOR'};
    
    for i = 1:length(qualities)
        switch qualities{i}
            case 'EXCELLENT'
                quality_counts(1) = quality_counts(1) + 1;
            case 'GOOD'
                quality_counts(2) = quality_counts(2) + 1;
            case 'ACCEPTABLE'
                quality_counts(3) = quality_counts(3) + 1;
            case 'POOR'
                quality_counts(4) = quality_counts(4) + 1;
        end
    end
    
    bar(quality_counts);
    set(gca, 'XTickLabel', quality_labels);
    ylabel('Count');
    title('Quality Distribution');
    
    % Plot 3: Deviation from theory
    subplot(2, 3, 3);
    deviations = abs(alpha_means - 1.0);
    bar(p_vals, deviations);
    xlabel('p');
    ylabel('|α - 1.0|');
    title('Deviation from Theory');
    grid on;
    
    % Plot 4: Error bars
    subplot(2, 3, 4);
    bar(p_vals, alpha_errors);
    xlabel('p');
    ylabel('Standard Error');
    title('α Estimation Errors');
    grid on;
    
    % Plot 5: Success rates
    subplot(2, 3, 5);
    success_rates = zeros(1, length(liquid_results));
    for i = 1:length(liquid_results)
        rates = [liquid_results(i, :).trajectory_stats];
        success_rates(i) = mean([rates.success_rate]);
    end
    plot(p_vals, success_rates, 'go-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('p');
    ylabel('Success Rate');
    title('Move Success Rate');
    grid on;
    
    % Plot 6: Effective diffusion
    subplot(2, 3, 6);
    effective_diffusions = zeros(1, length(liquid_results));
    for i = 1:length(liquid_results)
        rates = [liquid_results(i, :).trajectory_stats];
        effective_diffusions(i) = mean([rates.effective_diffusion]);
    end
    semilogy(p_vals, effective_diffusions, 'mo-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('p');
    ylabel('Effective Diffusion');
    title('Effective Diffusion Coefficient');
    grid on;
    
    sgtitle('Liquid Regime Analysis Results', 'FontSize', 16);
    
    % Save plot
    saveas(gcf, 'liquid_regime_analysis.png');
    fprintf('Plots saved to liquid_regime_analysis.png\n');
end

function display_liquid_regime_summary(liquid_results, liquid_analysis)
    % Display summary of liquid regime analysis
    
    fprintf('\n=== LIQUID REGIME SUMMARY ===\n\n');
    
    % Overall statistics
    p_vals = [liquid_results.p];
    alpha_means = [liquid_results.alpha_mean];
    alpha_errors = [liquid_results.alpha_se];
    qualities = {liquid_results.quality};
    
    fprintf('Overall Results:\n');
    fprintf('  Tested p values: [');
    fprintf('%.1f ', p_vals);
    fprintf(']\n');
    
    fprintf('  α values: [');
    for i = 1:length(alpha_means)
        fprintf('%.3f±%.3f ', alpha_means(i), alpha_errors(i));
    end
    fprintf(']\n');
    
    fprintf('  Qualities: [');
    for i = 1:length(qualities)
        fprintf('%s ', qualities{i});
    end
    fprintf(']\n\n');
    
    % Quality statistics
    excellent_count = sum(strcmp(qualities, 'EXCELLENT'));
    good_count = sum(strcmp(qualities, 'GOOD'));
    acceptable_count = sum(strcmp(qualities, 'ACCEPTABLE'));
    poor_count = sum(strcmp(qualities, 'POOR'));
    
    fprintf('Quality Distribution:\n');
    fprintf('  Excellent: %d/%d (%.0f%%)\n', excellent_count, length(qualities), excellent_count/length(qualities)*100);
    fprintf('  Good: %d/%d (%.0f%%)\n', good_count, length(qualities), good_count/length(qualities)*100);
    fprintf('  Acceptable: %d/%d (%.0f%%)\n', acceptable_count, length(qualities), acceptable_count/length(qualities)*100);
    fprintf('  Poor: %d/%d (%.0f%%)\n', poor_count, length(qualities), poor_count/length(qualities)*100);
    
    % Deviation from theory
    deviations = abs(alpha_means - 1.0);
    fprintf('\nDeviation from Theory (α = 1.0):\n');
    fprintf('  Mean deviation: %.3f\n', mean(deviations));
    fprintf('  Max deviation: %.3f\n', max(deviations));
    fprintf('  RMS deviation: %.3f\n', sqrt(mean(deviations.^2)));
    
    % Overall assessment
    if isfield(liquid_analysis, 'overall_quality')
        fprintf('\nOverall Assessment: %s\n', liquid_analysis.overall_quality);
        
        if strcmp(liquid_analysis.overall_quality, 'EXCELLENT')
            fprintf('✓ Liquid regime analysis successful\n');
            fprintf('✓ α ≈ 1.0 confirmed across p < p_c''\n');
            fprintf('✓ Methodology validated for liquid regime\n');
        elseif strcmp(liquid_analysis.overall_quality, 'GOOD')
            fprintf('○ Liquid regime analysis mostly successful\n');
            fprintf('○ α close to 1.0 with some scatter\n');
            fprintf('○ Methodology needs minor improvements\n');
        else
            fprintf('✗ Liquid regime analysis needs improvement\n');
            fprintf('✗ α values deviate significantly from 1.0\n');
            fprintf('✗ Methodology needs revision\n');
        end
    end
    
    fprintf('\n=== RECOMMENDATIONS ===\n');
    
    if excellent_count >= length(qualities) * 0.7
        fprintf('✓ Proceed with confidence to critical region analysis\n');
        fprintf('✓ Liquid regime methodology is robust\n');
    elseif good_count >= length(qualities) * 0.5
        fprintf('○ Proceed with caution to critical region analysis\n');
        fprintf('○ Consider parameter adjustments for better precision\n');
    else
        fprintf('✗ Revise methodology before proceeding\n');
        fprintf('✗ Focus on improving cross-over detection\n');
        fprintf('✗ Consider longer simulation times\n');
    end
end 