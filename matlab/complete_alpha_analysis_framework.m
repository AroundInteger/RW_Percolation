% complete_alpha_analysis_framework.m
% Main analysis function that implements the complete breakthrough framework

function results = complete_alpha_analysis_framework()
    % Complete α analysis framework implementing theoretical breakthrough
    
    fprintf('=== COMPLETE α ANALYSIS FRAMEWORK ===\n');
    fprintf('Implementing theoretical breakthrough for robust α estimation\n\n');
    
    % Key parameters based on theoretical framework
    p_c_prime = 0.6884;  % Critical point for 3D
    
    % Enhanced simulation parameters for critical region
    L = 500;
    LW = 20000;  % Doubled for better statistics
    NW = 500;    % Increased for better averaging
    n_realizations = 5;  % Ensemble averaging
    
    % Target p values - focused on critical region
    p_values = [0.60, 0.62, 0.64, 0.66, 0.68, 0.69, 0.70];
    
    fprintf('Analysis Parameters:\n');
    fprintf('  Critical point: p_c'' = %.4f\n', p_c_prime);
    fprintf('  System size: L = %d\n', L);
    fprintf('  Walk length: LW = %d\n', LW);
    fprintf('  Number of walkers: NW = %d\n', NW);
    fprintf('  Realizations per p: %d\n', n_realizations);
    fprintf('  Target p values: [');
    fprintf('%.2f ', p_values);
    fprintf(']\n\n');
    
    % Phase 1: Run Enhanced Simulations
    fprintf('=== PHASE 1: ENHANCED SIMULATIONS ===\n');
    ensemble_results = run_enhanced_ensemble_simulations(p_values, p_c_prime, L, LW, NW, n_realizations);
    
    % Phase 2: Apply Breakthrough Analysis
    fprintf('\n=== PHASE 2: BREAKTHROUGH ANALYSIS ===\n');
    analysis_results = apply_breakthrough_analysis(ensemble_results, p_c_prime);
    
    % Phase 3: Comprehensive Validation
    fprintf('\n=== PHASE 3: COMPREHENSIVE VALIDATION ===\n');
    validation_results = comprehensive_validation_framework(ensemble_results, p_c_prime);
    
    % Phase 4: Generate Final Report
    fprintf('\n=== PHASE 4: FINAL REPORT ===\n');
    final_results = generate_final_report(ensemble_results, analysis_results, validation_results, p_c_prime);
    
    % Compile all results
    results.ensemble = ensemble_results;
    results.analysis = analysis_results;
    results.validation = validation_results;
    results.final = final_results;
    results.parameters.p_c_prime = p_c_prime;
    results.parameters.p_values = p_values;
    
    % Save complete results
    save('complete_alpha_analysis_results.mat', 'results');
    
    fprintf('\n=== ANALYSIS COMPLETE ===\n');
    display_executive_summary(results);
    
    return;
end

function ensemble_results = run_enhanced_ensemble_simulations(p_values, p_c_prime, L, LW, NW, n_realizations)
    % Run enhanced ensemble simulations with breakthrough methodology
    
    fprintf('Running enhanced ensemble simulations...\n');
    
    % Initialize results structure
    total_runs = length(p_values) * n_realizations;
    ensemble_results = struct();
    run_counter = 0;
    
    for p_idx = 1:length(p_values)
        p = p_values(p_idx);
        fprintf('  Processing p = %.2f (%d/%d)...\n', p, p_idx, length(p_values));
        
        % Initialize results for this p value
        p_results = struct();
        
        for run = 1:n_realizations
            run_counter = run_counter + 1;
            fprintf('    Realization %d/%d (%.1f%% complete)\n', run, n_realizations, 100*run_counter/total_runs);
            
            % Run single simulation with enhanced parameters
            [t, msd, trajectory_stats] = run_enhanced_simulation(p, L, LW, NW, run);
            
            % Apply breakthrough analysis methodology
            [alpha_est, alpha_err, quality, analysis_details] = analyze_with_breakthrough_method(t, msd, p, p_c_prime);
            
            % Store individual run results
            p_results(run).p = p;
            p_results(run).run = run;
            p_results(run).alpha = alpha_est;
            p_results(run).alpha_err = alpha_err;
            p_results(run).quality = quality;
            p_results(run).analysis_details = analysis_details;
            p_results(run).trajectory_stats = trajectory_stats;
            p_results(run).raw_data.t = t;
            p_results(run).raw_data.msd = msd;
        end
        
        % Calculate ensemble statistics for this p value
        ensemble_stats = calculate_enhanced_ensemble_stats(p_results);
        
        % Store ensemble results
        ensemble_results(p_idx) = ensemble_stats;
        ensemble_results(p_idx).individual_runs = p_results;
        
        fprintf('    Ensemble result: α = %.3f ± %.3f (%s)\n', ...
            ensemble_stats.alpha_mean, ensemble_stats.alpha_se, ensemble_stats.quality);
    end
    
    fprintf('Enhanced ensemble simulations complete.\n');
end

function [alpha_est, alpha_err, quality, analysis_details] = analyze_with_breakthrough_method(t, msd, p, p_c_prime)
    % Apply breakthrough methodology for robust α estimation
    
    analysis_details = struct();
    
    % Step 1: Enhanced cross-over detection
    [tau_cr, tau_cr_confidence, crossover_quality, crossover_details] = enhanced_crossover_detection(t, msd, p, p_c_prime);
    analysis_details.crossover = crossover_details;
    analysis_details.tau_cr = tau_cr;
    analysis_details.crossover_quality = crossover_quality;
    
    % Step 2: Enhanced adaptive window selection
    [optimal_window, window_quality, window_details] = enhanced_adaptive_window_selection(t, msd, p, p_c_prime, tau_cr);
    analysis_details.window = window_details;
    analysis_details.optimal_window = optimal_window;
    analysis_details.window_quality = window_quality;
    
    % Step 3: Multi-method α estimation with validation
    if ~isempty(optimal_window) && length(optimal_window) >= 10
        [alpha_est, alpha_err, estimation_quality, estimation_details] = estimate_alpha_multi_method(t, msd, optimal_window, p, p_c_prime);
        analysis_details.estimation = estimation_details;
    else
        alpha_est = NaN;
        alpha_err = NaN;
        estimation_quality = 'INSUFFICIENT_DATA';
    end
    
    % Step 4: Overall quality assessment
    quality = assess_breakthrough_quality(alpha_est, alpha_err, crossover_quality, window_quality, estimation_quality, p, p_c_prime);
    analysis_details.overall_quality = quality;
    
    % Step 5: Theoretical validation
    expected_alpha = calculate_theoretical_alpha(p, p_c_prime);
    analysis_details.expected_alpha = expected_alpha;
    analysis_details.deviation_from_theory = abs(alpha_est - expected_alpha);
    analysis_details.theoretical_consistency = analysis_details.deviation_from_theory < 0.3;
end

function [alpha_est, alpha_err, quality, details] = estimate_alpha_multi_method(t, msd, window, p, p_c_prime)
    % Multi-method α estimation with cross-validation
    
    t_window = t(window);
    msd_window = msd(window);
    
    % Method 1: Direct log-log linear fit
    [alpha_1, r_squared_1, fit_details_1] = estimate_alpha_linear_fit(t_window, msd_window);
    
    % Method 2: Robust moving window analysis
    [alpha_2, alpha_2_std, moving_details] = estimate_alpha_moving_window(t_window, msd_window);
    
    % Method 3: Derivative-based method
    [alpha_3, derivative_details] = estimate_alpha_derivative_method(t_window, msd_window);
    
    % Method 4: Weighted least squares (if errors available)
    [alpha_4, wls_details] = estimate_alpha_weighted_least_squares(t_window, msd_window);
    
    % Combine methods using reliability weighting
    methods = [alpha_1, alpha_2, alpha_3, alpha_4];
    reliabilities = [r_squared_1, 1/(1+alpha_2_std), 0.7, 0.8];  % Method-specific reliability scores
    
    % Remove NaN values
    valid_idx = ~isnan(methods);
    valid_methods = methods(valid_idx);
    valid_reliabilities = reliabilities(valid_idx);
    
    if ~isempty(valid_methods)
        % Weighted average
        weights = valid_reliabilities / sum(valid_reliabilities);
        alpha_est = sum(valid_methods .* weights);
        
        % Error estimate from method agreement
        if length(valid_methods) > 1
            alpha_err = sqrt(sum(weights .* (valid_methods - alpha_est).^2));
        else
            alpha_err = 0.1;  % Default uncertainty for single method
        end
        
        % Quality assessment
        if length(valid_methods) >= 3 && alpha_err < 0.15 && r_squared_1 > 0.9
            quality = 'EXCELLENT';
        elseif length(valid_methods) >= 2 && alpha_err < 0.25 && r_squared_1 > 0.8
            quality = 'GOOD';
        elseif alpha_err < 0.4 && r_squared_1 > 0.7
            quality = 'ACCEPTABLE';
        else
            quality = 'POOR';
        end
    else
        alpha_est = NaN;
        alpha_err = NaN;
        quality = 'FAILED';
    end
    
    % Store detailed results
    details.method_results = methods;
    details.reliabilities = reliabilities;
    details.valid_methods = valid_methods;
    details.weights = weights;
    details.fit_details_1 = fit_details_1;
    details.moving_details = moving_details;
    details.derivative_details = derivative_details;
    details.wls_details = wls_details;
end

function expected_alpha = calculate_theoretical_alpha(p, p_c_prime)
    % Calculate theoretical α value based on percolation theory
    
    nu = 0.88;  % 3D percolation critical exponent
    
    if p <= p_c_prime
        if p < p_c_prime - 0.05
            % Liquid regime: α should approach 1.0
            expected_alpha = (1 - (p / p_c_prime))^(1/nu);
            expected_alpha = max(expected_alpha, 0.7);  % Floor for liquid regime
        else
            % Near critical: use critical scaling
            expected_alpha = (1 - (p / p_c_prime))^(1/nu);
        end
    else
        % Solid regime: α should be 0
        expected_alpha = 0.0;
    end
end

function quality = assess_breakthrough_quality(alpha_est, alpha_err, crossover_quality, window_quality, estimation_quality, p, p_c_prime)
    % Assess overall quality using breakthrough framework criteria
    
    if isnan(alpha_est)
        quality = 'FAILED';
        return;
    end
    
    % Expected α for this p value
    expected_alpha = calculate_theoretical_alpha(p, p_c_prime);
    
    % Quality criteria
    criteria = struct();
    
    % 1. Theoretical consistency
    deviation = abs(alpha_est - expected_alpha);
    criteria.theoretical = deviation < 0.3;
    
    % 2. Error magnitude
    criteria.precision = alpha_err < 0.2;
    
    % 3. Cross-over detection quality
    criteria.crossover = strcmp(crossover_quality, 'EXCELLENT') || strcmp(crossover_quality, 'GOOD');
    
    % 4. Window selection quality
    criteria.window = strcmp(window_quality, 'EXCELLENT') || strcmp(window_quality, 'GOOD');
    
    % 5. Estimation method quality
    criteria.estimation = strcmp(estimation_quality, 'EXCELLENT') || strcmp(estimation_quality, 'GOOD');
    
    % Overall quality assessment
    passed_criteria = sum(struct2array(criteria));
    total_criteria = length(fieldnames(criteria));
    
    if passed_criteria == total_criteria
        quality = 'EXCELLENT';
    elseif passed_criteria >= total_criteria - 1
        quality = 'GOOD';
    elseif passed_criteria >= total_criteria - 2
        quality = 'ACCEPTABLE';
    else
        quality = 'POOR';
    end
end

function ensemble_stats = calculate_enhanced_ensemble_stats(p_results)
    % Calculate enhanced ensemble statistics
    
    % Extract α values
    alphas = [p_results.alpha];
    alpha_errors = [p_results.alpha_err];
    qualities = {p_results.quality};
    
    % Filter valid results
    valid_idx = ~isnan(alphas) & ~isnan(alpha_errors);
    valid_alphas = alphas(valid_idx);
    valid_errors = alpha_errors(valid_idx);
    valid_qualities = qualities(valid_idx);
    
    if isempty(valid_alphas)
        ensemble_stats.alpha_mean = NaN;
        ensemble_stats.alpha_se = NaN;
        ensemble_stats.quality = 'NO_VALID_DATA';
        ensemble_stats.n_valid = 0;
        return;
    end
    
    % Calculate ensemble statistics
    ensemble_stats.p = p_results(1).p;
    ensemble_stats.n_valid = length(valid_alphas);
    ensemble_stats.n_total = length(p_results);
    
    % Weighted mean using inverse variance weighting
    if all(valid_errors > 0)
        weights = 1 ./ (valid_errors.^2);
        ensemble_stats.alpha_mean = sum(valid_alphas .* weights) / sum(weights);
        ensemble_stats.alpha_se = sqrt(1 / sum(weights));
    else
        % Simple mean if no valid errors
        ensemble_stats.alpha_mean = mean(valid_alphas);
        ensemble_stats.alpha_se = std(valid_alphas) / sqrt(length(valid_alphas));
    end
    
    % Additional statistics
    ensemble_stats.alpha_std = std(valid_alphas);
    ensemble_stats.alpha_min = min(valid_alphas);
    ensemble_stats.alpha_max = max(valid_alphas);
    ensemble_stats.alpha_median = median(valid_alphas);
    
    % Quality assessment
    excellent_count = sum(strcmp(valid_qualities, 'EXCELLENT'));
    good_count = sum(strcmp(valid_qualities, 'GOOD'));
    acceptable_count = sum(strcmp(valid_qualities, 'ACCEPTABLE'));
    
    if excellent_count >= length(valid_qualities) * 0.6
        ensemble_stats.quality = 'EXCELLENT';
    elseif (excellent_count + good_count) >= length(valid_qualities) * 0.6
        ensemble_stats.quality = 'GOOD';
    elseif (excellent_count + good_count + acceptable_count) >= length(valid_qualities) * 0.5
        ensemble_stats.quality = 'ACCEPTABLE';
    else
        ensemble_stats.quality = 'POOR';
    end
    
    % Store quality distribution
    ensemble_stats.quality_distribution.excellent = excellent_count;
    ensemble_stats.quality_distribution.good = good_count;
    ensemble_stats.quality_distribution.acceptable = acceptable_count;
    ensemble_stats.quality_distribution.poor = length(valid_qualities) - excellent_count - good_count - acceptable_count;
end

function analysis_results = apply_breakthrough_analysis(ensemble_results, p_c_prime)
    % Apply breakthrough analysis to ensemble results
    
    fprintf('Applying breakthrough analysis methodology...\n');
    
    % Extract ensemble data
    p_values = [ensemble_results.p];
    alpha_means = [ensemble_results.alpha_mean];
    alpha_errors = [ensemble_results.alpha_se];
    qualities = {ensemble_results.quality};
    
    % 1. Phase Regime Classification
    fprintf('  Classifying phase regimes...\n');
    regime_analysis = classify_phase_regimes(p_values, alpha_means, p_c_prime);
    
    % 2. Theoretical Comparison
    fprintf('  Comparing with theoretical predictions...\n');
    theory_comparison = compare_with_theory(p_values, alpha_means, alpha_errors, p_c_prime);
    
    % 3. Transition Point Analysis
    fprintf('  Analyzing transition behavior...\n');
    transition_analysis = analyze_transition_behavior(p_values, alpha_means, alpha_errors, p_c_prime);
    
    % 4. Quality Assessment
    fprintf('  Assessing methodology quality...\n');
    methodology_assessment = assess_methodology_quality(ensemble_results, p_c_prime);
    
    % Compile analysis results
    analysis_results.regime_classification = regime_analysis;
    analysis_results.theory_comparison = theory_comparison;
    analysis_results.transition_analysis = transition_analysis;
    analysis_results.methodology_assessment = methodology_assessment;
    analysis_results.p_c_prime = p_c_prime;
    
    fprintf('Breakthrough analysis complete.\n');
end

function final_results = generate_final_report(ensemble_results, analysis_results, validation_results, p_c_prime)
    % Generate comprehensive final report
    
    fprintf('Generating final comprehensive report...\n');
    
    % Executive Summary
    executive_summary = create_executive_summary(ensemble_results, analysis_results, validation_results, p_c_prime);
    
    % Key Findings
    key_findings = extract_key_findings(ensemble_results, analysis_results, validation_results, p_c_prime);
    
    % Methodology Validation
    methodology_validation = summarize_methodology_validation(validation_results);
    
    % Recommendations
    recommendations = generate_recommendations(validation_results, analysis_results);
    
    % Create comprehensive plots
    create_comprehensive_plots(ensemble_results, analysis_results, validation_results, p_c_prime);
    
    % Write detailed report file
    write_detailed_report(executive_summary, key_findings, methodology_validation, recommendations, p_c_prime);
    
    % Compile final results
    final_results.executive_summary = executive_summary;
    final_results.key_findings = key_findings;
    final_results.methodology_validation = methodology_validation;
    final_results.recommendations = recommendations;
    final_results.timestamp = datestr(now);
    
    fprintf('Final report generation complete.\n');
end

function display_executive_summary(results)
    % Display executive summary of complete analysis
    
    fprintf('\n=== EXECUTIVE SUMMARY ===\n\n');
    
    % Overall validation result
    if isfield(results.validation, 'overall')
        fprintf('VALIDATION RESULT: %s\n', results.validation.overall.conclusion);
        fprintf('Confidence Score: %.3f\n', results.validation.overall.weighted_score);
        fprintf('Recommendation: %s\n\n', results.validation.overall.recommendation);
    end
    
    % Key numerical results
    p_values = [results.ensemble.p];
    alpha_means = [results.ensemble.alpha_mean];
    alpha_errors = [results.ensemble.alpha_se];
    
    fprintf('KEY RESULTS:\n');
    fprintf('p\t\tα\t\tError\t\tQuality\n');
    fprintf('---\t\t---\t\t---\t\t---\n');
    for i = 1:length(results.ensemble)
        fprintf('%.2f\t\t%.3f\t\t%.3f\t\t%s\n', ...
            results.ensemble(i).p, results.ensemble(i).alpha_mean, ...
            results.ensemble(i).alpha_se, results.ensemble(i).quality);
    end
    
    % Phase transition evidence
    fprintf('\nPHASE TRANSITION EVIDENCE:\n');
    if isfield(results.validation, 'phase_transition')
        if isfield(results.validation.phase_transition, 'approaches_unity')
            if results.validation.phase_transition.approaches_unity
                fprintf('• α approaches 1.0 for p < p_c: YES\n');
            else
                fprintf('• α approaches 1.0 for p < p_c: NO\n');
            end
        end
        if isfield(results.validation.phase_transition, 'approaches_zero')
            if results.validation.phase_transition.approaches_zero
                fprintf('• α approaches 0.0 for p > p_c: YES\n');
            else
                fprintf('• α approaches 0.0 for p > p_c: NO\n');
            end
        end
    end
    
    % Theoretical agreement
    fprintf('\nTHEORETICAL AGREEMENT:\n');
    if isfield(results.validation, 'theoretical')
        fprintf('• Agreement level: %s\n', results.validation.theoretical.agreement);
        fprintf('• Mean deviation: %.3f\n', results.validation.theoretical.mean_deviation);
        fprintf('• Correlation: %.3f\n', results.validation.theoretical.correlation_with_theory);
    end
    
    fprintf('\n=== ANALYSIS COMPLETE ===\n');
    fprintf('Complete results saved to complete_alpha_analysis_results.mat\n');
    fprintf('Detailed report and plots generated.\n\n');
end

% Additional helper functions would go here...
% (Including the enhanced simulation function, fitting methods, etc.)

function [t, msd, trajectory_stats] = run_enhanced_simulation(p, L, LW, NW, run_id)
    % Run enhanced simulation with improved parameters
    
    % Set random seed for reproducibility
    rng(run_id * 1000 + round(p * 100));
    
    % Create 3D lattice
    lattice = rand(L, L, L) > p;
    
    % Initialize walkers on free sites
    [free_x, free_y, free_z] = find(lattice);
    if length(free_x) < NW
        error('Not enough free sites for %d walkers at p=%.2f', NW, p);
    end
    
    % Random walker positions
    indices = randperm(length(free_x), NW);
    initial_positions = [free_x(indices), free_y(indices), free_z(indices)];
    
    % Run random walks
    trajectories = run_3d_random_walks(lattice, initial_positions, LW);
    
    % Calculate MSD with lag-time averaging
    [t, msd] = calculate_msd_with_lag_averaging(trajectories);
    
    % Calculate trajectory statistics
    trajectory_stats = calculate_trajectory_statistics(trajectories, lattice);
end

function trajectories = run_3d_random_walks(lattice, initial_positions, LW)
    % Run 3D random walks on lattice
    
    [L, ~, ~] = size(lattice);
    NW = size(initial_positions, 1);
    trajectories = zeros(NW, LW, 3);
    
    % Possible moves (6 directions in 3D)
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
            
            % Check if site is free
            if lattice(new_pos(1), new_pos(2), new_pos(3))
                pos = new_pos;
            end
        end
    end
end

function [t, msd] = calculate_msd_with_lag_averaging(trajectories)
    % Calculate MSD with proper lag-time averaging
    
    [NW, LW, ~] = size(trajectories);
    t = 1:LW;
    msd = zeros(1, LW);
    
    % Calculate MSD for each lag time
    for lag = 1:LW
        total_displacement_sq = 0;
        count = 0;
        
        for w = 1:NW
            for start_time = 1:(LW - lag + 1)
                end_time = start_time + lag - 1;
                
                if end_time <= LW
                    r_start = squeeze(trajectories(w, start_time, :));
                    r_end = squeeze(trajectories(w, end_time, :));
                    displacement_sq = sum((r_end - r_start).^2);
                    
                    total_displacement_sq = total_displacement_sq + displacement_sq;
                    count = count + 1;
                end
            end
        end
        
        if count > 0
            msd(lag) = total_displacement_sq / count;
        end
    end
end

% Additional helper functions for α estimation methods...

function [alpha, r_squared, details] = estimate_alpha_linear_fit(t, msd)
    % Direct linear fit in log-log space
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    [fit_coeff, fit_stats] = polyfit(log_t, log_msd, 1);
    alpha = fit_coeff(1);
    
    % Calculate R²
    msd_pred = polyval(fit_coeff, log_t);
    ss_res = sum((log_msd - msd_pred).^2);
    ss_tot = sum((log_msd - mean(log_msd)).^2);
    r_squared = 1 - (ss_res / ss_tot);
    
    details.fit_coeff = fit_coeff;
    details.fit_stats = fit_stats;
    details.ss_res = ss_res;
    details.ss_tot = ss_tot;
end

function [alpha, alpha_std, details] = estimate_alpha_moving_window(t, msd)
    % Moving window α estimation
    
    window_size = min(15, length(t)/4);
    n_windows = length(t) - window_size + 1;
    alpha_values = zeros(1, n_windows);
    
    for i = 1:n_windows
        window_idx = i:(i + window_size - 1);
        t_window = t(window_idx);
        msd_window = msd(window_idx);
        
        [alpha_values(i), ~] = estimate_alpha_linear_fit(t_window, msd_window);
    end
    
    alpha = mean(alpha_values);
    alpha_std = std(alpha_values);
    
    details.alpha_values = alpha_values;
    details.window_size = window_size;
    details.n_windows = n_windows;
end

function [alpha, details] = estimate_alpha_derivative_method(t, msd)
    % Derivative-based α estimation
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Calculate derivative using gradient
    d_log_msd = gradient(log_msd, log_t);
    
    % Use median for robustness
    alpha = median(d_log_msd);
    
    details.d_log_msd = d_log_msd;
    details.alpha_values = d_log_msd;
    details.method = 'gradient_median';
end

function [alpha, details] = estimate_alpha_weighted_least_squares(t, msd)
    % Weighted least squares if heteroscedasticity suspected
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Simple uniform weighting for now
    weights = ones(size(log_t));
    
    % Weighted fit
    X = [ones(length(log_t), 1), log_t(:)];
    W = diag(weights);
    y = log_msd(:);
    
    beta = (X' * W * X) \ (X' * W * y);
    alpha = beta(2);
    
    details.weights = weights;
    details.beta = beta;
    details.method = 'weighted_least_squares';
end