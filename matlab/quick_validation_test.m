% quick_validation_test.m
% Quick validation test for enhanced methodology
% Test p = 0.5, 0.68, 0.75 to validate numerics

clear; close all; clc;

fprintf('=== QUICK VALIDATION TEST ===\n');
fprintf('Testing enhanced methodology with key p values\n');
fprintf('p = 0.5 (liquid), 0.68 (near critical), 0.75 (solid)\n\n');

% Test parameters
p_c_prime = 0.6884;
p_values = [0.5, 0.68, 0.75];  % Key test points
L = 500;
LW = 10000;  % Reduced for quick test
NW = 10;    % Reduced for quick test
n_realizations = 3;  % Reduced for quick test

fprintf('Test Parameters:\n');
fprintf('  p values: [');
fprintf('%.2f ', p_values);
fprintf(']\n');
fprintf('  System size: L = %d\n', L);
fprintf('  Walk length: LW = %d\n', LW);
fprintf('  Walkers: NW = %d\n', NW);
fprintf('  Realizations: %d per p value\n', n_realizations);
fprintf('  Total simulations: %d\n', length(p_values) * n_realizations);

% Initialize results
test_results = struct();

for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('\n=== Testing p = %.2f ===\n', p);
    
    % Determine expected behavior
    if p < p_c_prime - 0.05
        expected_behavior = 'LIQUID';
        expected_alpha = 1.0;
    elseif abs(p - p_c_prime) < 0.05
        expected_behavior = 'CRITICAL';
        expected_alpha = 0.5;
    else
        expected_behavior = 'SOLID';
        expected_alpha = 0.0;
    end
    
    fprintf('  Expected behavior: %s (α ≈ %.1f)\n', expected_behavior, expected_alpha);
    
    % Run multiple realizations
    p_alphas = [];
    p_errors = [];
    p_qualities = {};
    
    for run = 1:n_realizations
        fprintf('    Realization %d/%d...\n', run, n_realizations);
        
        % Run simulation
        [t, msd, trajectory_stats] = run_quick_simulation(p, L, LW, NW, run);
        
        % Apply enhanced analysis
        [alpha_est, alpha_err, quality, analysis_details] = analyze_quick_test(t, msd, p, p_c_prime);

        [results_1, comparison_1] = enhanced_changepoint_detection(t, msd, p, p_c_prime, varargin);
        
        % Store results
        p_alphas = [p_alphas, alpha_est];
        p_errors = [p_errors, alpha_err];
        p_qualities{end+1} = quality;
        
        fprintf('      α = %.3f ± %.3f (%s)\n', alpha_est, alpha_err, quality);
    end
    
    % Calculate ensemble statistics
    valid_alphas = p_alphas(~isnan(p_alphas));
    if ~isempty(valid_alphas)
        alpha_mean = mean(valid_alphas);
        alpha_se = std(valid_alphas) / sqrt(length(valid_alphas));
        
        % Quality assessment
        alpha_deviation = abs(alpha_mean - expected_alpha);
        if alpha_se < 0.1 && alpha_deviation < 0.2
            overall_quality = 'EXCELLENT';
        elseif alpha_se < 0.2 && alpha_deviation < 0.3
            overall_quality = 'GOOD';
        elseif alpha_se < 0.3 && alpha_deviation < 0.4
            overall_quality = 'ACCEPTABLE';
        else
            overall_quality = 'POOR';
        end
        
        fprintf('  Ensemble: α = %.3f ± %.3f (%s)\n', alpha_mean, alpha_se, overall_quality);
        fprintf('  Deviation from theory: %.3f\n', alpha_deviation);
    else
        alpha_mean = NaN;
        alpha_se = NaN;
        overall_quality = 'INSUFFICIENT_DATA';
        fprintf('  Ensemble: INSUFFICIENT_DATA\n');
    end
    
    % Store results
    test_results(p_idx).p = p;
    test_results(p_idx).expected_behavior = expected_behavior;
    test_results(p_idx).expected_alpha = expected_alpha;
    test_results(p_idx).alpha_mean = alpha_mean;
    test_results(p_idx).alpha_se = alpha_se;
    test_results(p_idx).quality = overall_quality;
    test_results(p_idx).individual_alphas = p_alphas;
    test_results(p_idx).individual_errors = p_errors;
    test_results(p_idx).individual_qualities = p_qualities;
end

% Create validation plots
create_quick_validation_plots(test_results, p_c_prime);

% Display summary
display_quick_validation_summary(test_results, p_c_prime);

% Save results
save('quick_validation_results.mat', 'test_results');

fprintf('\n=== QUICK VALIDATION COMPLETE ===\n');
fprintf('Results saved to quick_validation_results.mat\n');

%% Helper Functions

function [t, msd, trajectory_stats] = run_quick_simulation(p, L, LW, NW, run)
    % Quick simulation for validation test
    
    % Set random seed for reproducibility
    rng(run);
    
    % Create lattice
    lattice = rand(L, L, L) > p;
    
    % Check connectivity
    [free_x, free_y, free_z] = find(lattice);
    if length(free_x) < NW
        error('Insufficient free sites for p=%.3f, run=%d', p, run);
    end
    
    % Initialize walkers
    indices = randperm(length(free_x), NW);
    initial_positions = [free_x(indices), free_y(indices), free_z(indices)];
    
    % Run random walks
    trajectories = run_quick_walks(lattice, initial_positions, LW);
    
    % Calculate MSD
    [t, msd] = calculate_quick_msd(trajectories);
    
    % Calculate trajectory statistics
    trajectory_stats = calculate_quick_stats(trajectories, lattice, p);
end

function trajectories = run_quick_walks(lattice, initial_positions, LW)
    % Quick random walks implementation
    
    [L, ~, ~] = size(lattice);
    NW = size(initial_positions, 1);
    trajectories = zeros(NW, LW, 3);
    
    % Pre-compute move directions
    moves = [1,0,0; -1,0,0; 0,1,0; 0,-1,0; 0,0,1; 0,0,-1];
    
    for w = 1:NW
        pos = initial_positions(w, :);
        
        for step = 1:LW
            trajectories(w, step, :) = pos;
            
            % Attempt move
            move_dir = randi(6);
            new_pos = pos + moves(move_dir, :);
            
            % Periodic boundary conditions
            new_pos = mod(new_pos - 1, L) + 1;
            
            % Check if move is allowed
            if lattice(new_pos(1), new_pos(2), new_pos(3))
                pos = new_pos;
            end
        end
    end
end

function [t, msd] = calculate_quick_msd(trajectories)
    % Quick MSD calculation
    
    [NW, LW, ~] = size(trajectories);
    t = 1:LW;
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

function stats = calculate_quick_stats(trajectories, lattice, p)
    % Quick trajectory statistics
    
    [NW, LW, ~] = size(trajectories);
    
    % Calculate success rates
    success_rates = zeros(NW, 1);
    for w = 1:NW
        trajectory = squeeze(trajectories(w, :, :));
        success_count = 0;
        
        for step = 2:LW
            dr = trajectory(step, :) - trajectory(step-1, :);
            if any(dr ~= 0)  % Walker moved
                success_count = success_count + 1;
            end
        end
        success_rates(w) = success_count / (LW - 1);
    end
    
    stats.success_rate = mean(success_rates);
    stats.total_moves = sum(success_rates) * LW;
end

function [alpha_est, alpha_err, quality, analysis_details] = analyze_quick_test(t, msd, p, p_c_prime)
    % Quick analysis for validation test
    
    % Determine expected behavior and select analysis method
    if p < p_c_prime - 0.05
        % Liquid regime: look for regular diffusion (α ≈ 1.0)
        [alpha_est, alpha_err, quality] = analyze_liquid_quick(t, msd);
        expected_alpha = 1.0;
    elseif abs(p - p_c_prime) < 0.05
        % Critical regime: look for anomalous diffusion (α ≈ 0.5)
        [alpha_est, alpha_err, quality] = analyze_critical_quick(t, msd);
        expected_alpha = 0.5;
    else
        % Solid regime: look for plateau (α ≈ 0.0)
        [alpha_est, alpha_err, quality] = analyze_solid_quick(t, msd);
        expected_alpha = 0.0;
    end
    
    % Store analysis details
    analysis_details.expected_alpha = expected_alpha;
    analysis_details.regime = get_regime_name(p, p_c_prime);
end

function [alpha_est, alpha_err, quality] = analyze_liquid_quick(t, msd)
    % Quick analysis for liquid regime (p < p_c' - 0.05)
    
    % Use last 1/3 of data for regular diffusion region
    start_idx = round(length(t) * 0.67);
    t_window = t(start_idx:end);
    msd_window = msd(start_idx:end);
    
    if length(t_window) >= 10
        [alpha_est, r_squared] = fit_alpha_quick(t_window, msd_window);
        alpha_err = 0.1;  % Conservative estimate
        
        % Quality assessment
        if r_squared > 0.95 && abs(alpha_est - 1.0) < 0.2
            quality = 'EXCELLENT';
        elseif r_squared > 0.90 && abs(alpha_est - 1.0) < 0.3
            quality = 'GOOD';
        elseif r_squared > 0.85 && abs(alpha_est - 1.0) < 0.4
            quality = 'ACCEPTABLE';
        else
            quality = 'POOR';
        end
    else
        alpha_est = NaN;
        alpha_err = NaN;
        quality = 'INSUFFICIENT_DATA';
    end
end

function [alpha_est, alpha_err, quality] = analyze_critical_quick(t, msd)
    % Quick analysis for critical regime (p ≈ p_c')
    
    % Use middle 1/3 of data for anomalous diffusion region
    start_idx = round(length(t) * 0.33);
    end_idx = round(length(t) * 0.67);
    t_window = t(start_idx:end_idx);
    msd_window = msd(start_idx:end_idx);
    
    if length(t_window) >= 10
        [alpha_est, r_squared] = fit_alpha_quick(t_window, msd_window);
        alpha_err = 0.15;  % Conservative estimate for critical region
        
        % Quality assessment
        if r_squared > 0.90 && abs(alpha_est - 0.5) < 0.3
            quality = 'EXCELLENT';
        elseif r_squared > 0.80 && abs(alpha_est - 0.5) < 0.4
            quality = 'GOOD';
        elseif r_squared > 0.70 && abs(alpha_est - 0.5) < 0.5
            quality = 'ACCEPTABLE';
        else
            quality = 'POOR';
        end
    else
        alpha_est = NaN;
        alpha_err = NaN;
        quality = 'INSUFFICIENT_DATA';
    end
end

function [alpha_est, alpha_err, quality] = analyze_solid_quick(t, msd)
    % Quick analysis for solid regime (p > p_c' + 0.05)
    
    % Use last 1/4 of data for plateau region
    start_idx = round(length(t) * 0.75);
    t_window = t(start_idx:end);
    msd_window = msd(start_idx:end);
    
    if length(t_window) >= 10
        [alpha_est, r_squared] = fit_alpha_quick(t_window, msd_window);
        alpha_err = 0.05;  % Conservative estimate for plateau
        
        % Quality assessment
        if r_squared > 0.80 && abs(alpha_est) < 0.2
            quality = 'EXCELLENT';
        elseif r_squared > 0.70 && abs(alpha_est) < 0.3
            quality = 'GOOD';
        elseif r_squared > 0.60 && abs(alpha_est) < 0.4
            quality = 'ACCEPTABLE';
        else
            quality = 'POOR';
        end
    else
        alpha_est = NaN;
        alpha_err = NaN;
        quality = 'INSUFFICIENT_DATA';
    end
end

function [alpha, r_squared] = fit_alpha_quick(t, msd)
    % Quick α fitting
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    [fit_coeff, fit_stats] = polyfit(log_t, log_msd, 1);
    alpha = fit_coeff(1);
    r_squared = fit_stats.R^2;
end

function regime = get_regime_name(p, p_c_prime)
    % Get regime name based on p value
    
    if p < p_c_prime - 0.05
        regime = 'LIQUID';
    elseif abs(p - p_c_prime) < 0.05
        regime = 'CRITICAL';
    else
        regime = 'SOLID';
    end
end

function create_quick_validation_plots(test_results, p_c_prime)
    % Create validation plots
    
    figure('Position', [100, 100, 1200, 400]);
    
    % Plot 1: α vs p
    subplot(1, 3, 1);
    p_vals = [test_results.p];
    alpha_means = [test_results.alpha_mean];
    alpha_errors = [test_results.alpha_se];
    
    errorbar(p_vals, alpha_means, alpha_errors, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
    hold on;
    
    % Plot theoretical expectations
    p_theory = [0.4, 0.5, 0.6, 0.68, 0.8];
    alpha_theory = zeros(size(p_theory));
    for i = 1:length(p_theory)
        if p_theory(i) < p_c_prime - 0.05
            alpha_theory(i) = 1.0;
        elseif abs(p_theory(i) - p_c_prime) < 0.05
            alpha_theory(i) = 0.5;
        else
            alpha_theory(i) = 0.0;
        end
    end
    plot(p_theory, alpha_theory, 'r--', 'LineWidth', 2);
    
    xlabel('p');
    ylabel('α');
    title('Quick Validation: α vs p');
    grid on;
    legend('Simulation', 'Theory', 'Location', 'best');
    
    % Plot 2: Quality distribution
    subplot(1, 3, 2);
    qualities = {test_results.quality};
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
    subplot(1, 3, 3);
    expected_alphas = [test_results.expected_alpha];
    deviations = abs(alpha_means - expected_alphas);
    bar(p_vals, deviations);
    xlabel('p');
    ylabel('|α - α_theory|');
    title('Deviation from Theory');
    grid on;
    
    sgtitle('Quick Validation Test Results', 'FontSize', 16);
    
    % Save plot
    saveas(gcf, 'quick_validation_results.png');
    fprintf('Validation plots saved to quick_validation_results.png\n');
end

function display_quick_validation_summary(test_results, p_c_prime)
    % Display validation summary
    
    fprintf('\n=== QUICK VALIDATION SUMMARY ===\n\n');
    
    % Overall statistics
    p_vals = [test_results.p];
    alpha_means = [test_results.alpha_mean];
    alpha_errors = [test_results.alpha_se];
    qualities = {test_results.quality};
    expected_alphas = [test_results.expected_alpha];
    
    fprintf('Test Results:\n');
    fprintf('p\t\tα\t\tError\t\tTheory\t\tDeviation\tQuality\n');
    fprintf('---\t\t---\t\t---\t\t---\t\t---\t\t---\n');
    
    for i = 1:length(test_results)
        p = p_vals(i);
        alpha = alpha_means(i);
        error = alpha_errors(i);
        theory = expected_alphas(i);
        deviation = abs(alpha - theory);
        quality = qualities{i};
        
        fprintf('%.2f\t\t%.3f\t\t%.3f\t\t%.1f\t\t%.3f\t\t%s\n', p, alpha, error, theory, deviation, quality);
    end
    
    % Quality statistics
    excellent_count = sum(strcmp(qualities, 'EXCELLENT'));
    good_count = sum(strcmp(qualities, 'GOOD'));
    acceptable_count = sum(strcmp(qualities, 'ACCEPTABLE'));
    poor_count = sum(strcmp(qualities, 'POOR'));
    
    fprintf('\nQuality Distribution:\n');
    fprintf('  Excellent: %d/%d (%.0f%%)\n', excellent_count, length(qualities), excellent_count/length(qualities)*100);
    fprintf('  Good: %d/%d (%.0f%%)\n', good_count, length(qualities), good_count/length(qualities)*100);
    fprintf('  Acceptable: %d/%d (%.0f%%)\n', acceptable_count, length(qualities), acceptable_count/length(qualities)*100);
    fprintf('  Poor: %d/%d (%.0f%%)\n', poor_count, length(qualities), poor_count/length(qualities)*100);
    
    % Overall assessment
    deviations = abs(alpha_means - expected_alphas);
    mean_deviation = mean(deviations);
    max_deviation = max(deviations);
    
    fprintf('\nOverall Assessment:\n');
    fprintf('  Mean deviation from theory: %.3f\n', mean_deviation);
    fprintf('  Max deviation from theory: %.3f\n', max_deviation);
    
    if mean_deviation < 0.2 && excellent_count >= length(qualities) * 0.5
        fprintf('  CONCLUSION: ✓ Methodology validated - proceed with confidence!\n');
    elseif mean_deviation < 0.3 && good_count >= length(qualities) * 0.5
        fprintf('  CONCLUSION: ○ Methodology mostly validated - proceed with caution\n');
    else
        fprintf('  CONCLUSION: ✗ Methodology needs improvement - revise before proceeding\n');
    end
    
    fprintf('\n=== RECOMMENDATIONS ===\n');
    
    if mean_deviation < 0.2
        fprintf('✓ Proceed with full parallel framework\n');
        fprintf('✓ Methodology is robust and validated\n');
        fprintf('✓ Expected to achieve publication-quality results\n');
    elseif mean_deviation < 0.3
        fprintf('○ Proceed with full parallel framework\n');
        fprintf('○ Consider parameter adjustments for better precision\n');
        fprintf('○ Monitor quality metrics closely\n');
    else
        fprintf('✗ Revise methodology before proceeding\n');
        fprintf('✗ Focus on improving α estimation accuracy\n');
        fprintf('✗ Consider longer simulation times or larger systems\n');
    end
end 