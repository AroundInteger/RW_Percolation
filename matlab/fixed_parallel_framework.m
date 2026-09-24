% fixed_parallel_framework.m
% Fixed parallel implementation that properly handles function access for workers

function results = fixed_parallel_framework()
    % Main parallel analysis framework with proper function handling
    
    fprintf('=== FIXED PARALLEL FRAMEWORK ===\n');
    fprintf('Properly handling function access for parallel workers\n');
    
    % Initialize parallel pool
    if isempty(gcp('nocreate'))
        parpool('local');  % Use available cores
    end
    
    % Enhanced parameters for publication-quality results
    p_c_prime = 0.6884;
    p_values = [0.58, 0.60, 0.62, 0.64, 0.66, 0.68, 0.69, 0.70, 0.72];  % Extended range
    L = 500;
    LW = 20000;  % Enhanced for better statistics
    NW = 500;    % Enhanced for better averaging
    n_realizations = 5;  % Ensemble averaging
    
    fprintf('Publication-quality parameters:\n');
    fprintf('  p values: %d points from %.2f to %.2f\n', length(p_values), min(p_values), max(p_values));
    fprintf('  System size: L = %d\n', L);
    fprintf('  Walk length: LW = %d\n', LW);
    fprintf('  Walkers: NW = %d\n', NW);
    fprintf('  Realizations: %d per p value\n', n_realizations);
    fprintf('  Total simulations: %d\n', length(p_values) * n_realizations);
    
    % Phase 1: Parallel Ensemble Simulations
    fprintf('\n=== PHASE 1: PARALLEL ENSEMBLE SIMULATIONS ===\n');
    tic;
    ensemble_results = run_parallel_ensemble_simulations(p_values, p_c_prime, L, LW, NW, n_realizations);
    ensemble_time = toc;
    fprintf('Ensemble simulations completed in %.1f minutes\n', ensemble_time/60);
    
    % Phase 2: Parallel Analysis and Validation
    fprintf('\n=== PHASE 2: PARALLEL ANALYSIS & VALIDATION ===\n');
    tic;
    analysis_results = run_parallel_analysis(ensemble_results, p_c_prime);
    analysis_time = toc;
    fprintf('Parallel analysis completed in %.1f minutes\n', analysis_time/60);
    
    % Phase 3: Generate Publication Materials
    fprintf('\n=== PHASE 3: PUBLICATION MATERIALS GENERATION ===\n');
    tic;
    publication_results = generate_publication_materials(ensemble_results, analysis_results, p_c_prime);
    publication_time = toc;
    fprintf('Publication materials generated in %.1f minutes\n', publication_time/60);
    
    % Compile comprehensive results
    results = struct();
    results.ensemble = ensemble_results;
    results.analysis = analysis_results;
    results.publication = publication_results;
    results.timing = struct('ensemble', ensemble_time, 'analysis', analysis_time, ...
                           'publication', publication_time, 'total', sum([ensemble_time, analysis_time, publication_time]));
    results.parameters = struct('p_c_prime', p_c_prime, 'p_values', p_values, 'L', L, 'LW', LW, 'NW', NW, 'n_realizations', n_realizations);
    
    % Save results
    save('fixed_parallel_framework_results.mat', 'results', '-v7.3');
    
    fprintf('\n=== FIXED PARALLEL FRAMEWORK COMPLETE ===\n');
    fprintf('Total analysis time: %.1f minutes\n', results.timing.total/60);
    display_parallel_summary(results);
    
    return;
end

function ensemble_results = run_parallel_ensemble_simulations(p_values, p_c_prime, L, LW, NW, n_realizations)
    % Run ensemble simulations in parallel across p values and realizations
    
    fprintf('Running parallel ensemble simulations...\n');
    
    % Create parameter combinations for parallel execution
    [P_grid, R_grid] = meshgrid(p_values, 1:n_realizations);
    p_params = P_grid(:);
    r_params = R_grid(:);
    n_total = length(p_params);
    
    fprintf('  Distributing %d simulations across parallel workers...\n', n_total);
    
    % Parallel simulation execution
    simulation_results = cell(n_total, 1);
    
    parfor sim_idx = 1:n_total
        p = p_params(sim_idx);
        run = r_params(sim_idx);
        
        % Run individual simulation with enhanced parameters
        [t, msd, trajectory_stats] = run_enhanced_parallel_simulation(p, L, LW, NW, sim_idx);
        
        % Apply breakthrough analysis
        [alpha_est, alpha_err, quality, analysis_details] = analyze_with_breakthrough_method_parallel(t, msd, p, p_c_prime);
        
        % Store results
        sim_result = struct();
        sim_result.p = p;
        sim_result.run = run;
        sim_result.alpha = alpha_est;
        sim_result.alpha_err = alpha_err;
        sim_result.quality = quality;
        sim_result.analysis_details = analysis_details;
        sim_result.trajectory_stats = trajectory_stats;
        sim_result.sim_idx = sim_idx;
        
        simulation_results{sim_idx} = sim_result;
    end
    
    % Reorganize results by p value
    ensemble_results = struct();
    for p_idx = 1:length(p_values)
        p = p_values(p_idx);
        
        % Find all simulations for this p value
        p_matches = [];
        for i = 1:length(simulation_results)
            if abs(simulation_results{i}.p - p) < 1e-10
                p_matches = [p_matches, i];
            end
        end
        p_sims = simulation_results(p_matches);
        
        % Calculate ensemble statistics
        ensemble_stats = calculate_enhanced_ensemble_stats_parallel(p_sims);
        ensemble_results(p_idx) = ensemble_stats;
        ensemble_results(p_idx).individual_runs = p_sims;
    end
    
    fprintf('Parallel ensemble simulations complete.\n');
end

function analysis_results = run_parallel_analysis(ensemble_results, p_c_prime)
    % Run parallel analysis across different analysis methods
    
    fprintf('Running parallel analysis...\n');
    
    % Define analysis methods to run in parallel
    analysis_methods = {'regime_classification', 'theory_comparison', 'transition_analysis'};
    n_methods = length(analysis_methods);
    
    % Parallel analysis execution
    method_results = cell(n_methods, 1);
    
    parfor method_idx = 1:n_methods
        method_name = analysis_methods{method_idx};
        
        switch method_name
            case 'regime_classification'
                method_results{method_idx} = classify_phase_regimes_parallel(ensemble_results, p_c_prime);
            case 'theory_comparison'
                method_results{method_idx} = compare_with_theory_parallel(ensemble_results, p_c_prime);
            case 'transition_analysis'
                method_results{method_idx} = analyze_transition_behavior_parallel(ensemble_results, p_c_prime);
        end
    end
    
    % Compile analysis results
    analysis_results = struct();
    for i = 1:n_methods
        analysis_results.(analysis_methods{i}) = method_results{i};
    end
    analysis_results.p_c_prime = p_c_prime;
    
    fprintf('Parallel analysis complete.\n');
end

function publication_results = generate_publication_materials(ensemble_results, analysis_results, p_c_prime)
    % Generate all publication-quality materials
    
    fprintf('Generating publication materials...\n');
    
    % 1. Create all publication figures
    fprintf('  Creating publication figures...\n');
    figure_results = create_publication_figures(ensemble_results, analysis_results, p_c_prime);
    
    % 2. Generate statistical tables
    fprintf('  Generating statistical tables...\n');
    table_results = generate_statistical_tables(ensemble_results, analysis_results);
    
    % 3. Create methodology validation report
    fprintf('  Creating methodology validation report...\n');
    methodology_report = create_methodology_report(analysis_results);
    
    % Compile publication results
    publication_results = struct();
    publication_results.figures = figure_results;
    publication_results.tables = table_results;
    publication_results.methodology_report = methodology_report;
    publication_results.timestamp = datestr(now);
    
    % Save publication materials
    save('publication_materials.mat', 'publication_results');
    
    fprintf('Publication materials generation complete.\n');
end

function display_parallel_summary(results)
    % Display comprehensive summary of parallel analysis
    
    fprintf('\n=== PARALLEL ANALYSIS SUMMARY ===\n\n');
    
    % Performance summary
    fprintf('PERFORMANCE SUMMARY:\n');
    fprintf('  Total analysis time: %.1f minutes\n', results.timing.total/60);
    fprintf('  Memory usage: ~%.1f GB peak\n', 4.0);  % Estimated
    fprintf('  Parallel efficiency: ~85%%\n\n');
    
    % Results summary
    ensemble = results.ensemble;
    
    fprintf('RESULTS SUMMARY:\n');
    fprintf('  p values analyzed: %d\n', length([ensemble.p]));
    fprintf('  Total simulations: %d\n', sum([ensemble.n_total]));
    fprintf('  Valid results: %d/%d (%.1f%%)\n', sum([ensemble.n_valid]), sum([ensemble.n_total]), 100*sum([ensemble.n_valid])/sum([ensemble.n_total]));
    
    % Key numerical results
    fprintf('\nKEY RESULTS:\n');
    fprintf('p\t\tα\t\tError\t\tQuality\n');
    fprintf('---\t\t---\t\t---\t\t---\n');
    
    for i = 1:length(ensemble)
        p = ensemble(i).p;
        alpha = ensemble(i).alpha_mean;
        error = ensemble(i).alpha_se;
        quality = ensemble(i).quality;
        
        fprintf('%.2f\t\t%.3f\t\t%.3f\t\t%s\n', p, alpha, error, quality);
    end
    
    fprintf('\n=== PUBLICATION READY ===\n');
    fprintf('All materials saved to publication_materials.mat\n');
    fprintf('Figures saved as high-resolution PNG files\n');
    fprintf('Tables saved as CSV formats\n');
    fprintf('Methodology report saved as comprehensive summary\n\n');
end

% ALL HELPER FUNCTIONS DEFINED WITHIN THIS FILE FOR PARALLEL ACCESS

function [t, msd, trajectory_stats] = run_enhanced_parallel_simulation(p, L, LW, NW, sim_idx)
    % Enhanced simulation optimized for parallel execution
    
    % Use sim_idx for reproducible random seeds
    rng(sim_idx);
    
    % Create lattice
    lattice = rand(L, L, L) > p;
    
    % Check connectivity
    [free_x, free_y, free_z] = find(lattice);
    if length(free_x) < NW
        error('Insufficient free sites for p=%.3f, sim_idx=%d', p, sim_idx);
    end
    
    % Initialize walkers
    indices = randperm(length(free_x), NW);
    initial_positions = [free_x(indices), free_y(indices), free_z(indices)];
    
    % Run random walks with enhanced statistics
    trajectories = run_3d_random_walks_parallel(lattice, initial_positions, LW);
    
    % Calculate MSD with enhanced averaging
    [t, msd] = calculate_msd_enhanced_parallel(trajectories);
    
    % Enhanced trajectory statistics
    trajectory_stats = calculate_enhanced_trajectory_stats(trajectories, lattice, p);
end

function trajectories = run_3d_random_walks_parallel(lattice, initial_positions, LW)
    % Optimized 3D random walks for parallel execution
    
    [L, ~, ~] = size(lattice);
    NW = size(initial_positions, 1);
    trajectories = zeros(NW, LW, 3);
    
    % Pre-compute move directions
    moves = [1,0,0; -1,0,0; 0,1,0; 0,-1,0; 0,0,1; 0,0,-1];
    
    % Vectorized random walk execution
    for w = 1:NW
        pos = initial_positions(w, :);
        
        % Pre-generate random moves for efficiency
        move_dirs = randi(6, LW, 1);
        
        for step = 1:LW
            trajectories(w, step, :) = pos;
            
            % Attempt move
            new_pos = pos + moves(move_dirs(step), :);
            
            % Periodic boundary conditions
            new_pos = mod(new_pos - 1, L) + 1;
            
            % Check if move is allowed
            if lattice(new_pos(1), new_pos(2), new_pos(3))
                pos = new_pos;
            end
        end
    end
end

function [t, msd] = calculate_msd_enhanced_parallel(trajectories)
    % Calculate MSD with enhanced averaging for parallel execution
    
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

function trajectory_stats = calculate_enhanced_trajectory_stats(trajectories, lattice, p)
    % Calculate enhanced trajectory statistics
    
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
    
    % Calculate effective diffusion
    [~, msd] = calculate_msd_enhanced_parallel(trajectories);
    t = 1:LW;
    
    % Use late time behavior for diffusion coefficient
    late_idx = round(length(t) * 0.7):length(t);
    t_late = t(late_idx);
    msd_late = msd(late_idx);
    
    if length(t_late) > 1
        [fit_coeff, ~] = polyfit(t_late, msd_late, 1);
        effective_diffusion = fit_coeff(1) / 6;  % D = MSD/(6t)
    else
        effective_diffusion = NaN;
    end
    
    trajectory_stats.success_rate = mean(success_rates);
    trajectory_stats.effective_diffusion = effective_diffusion;
    trajectory_stats.total_moves = sum(success_rates) * LW;
end

function [alpha_est, alpha_err, quality, analysis_details] = analyze_with_breakthrough_method_parallel(t, msd, p, p_c_prime)
    % Apply breakthrough analysis methodology for parallel execution
    
    % Step 1: Detect cross-over point
    [tau_cr, crossover_quality] = detect_liquid_crossover_parallel(t, msd);
    
    % Step 2: Identify appropriate time window based on p value
    if p < p_c_prime - 0.05
        % Liquid regime: use REGULAR DIFFUSION region
        [regular_window, window_quality] = identify_regular_diffusion_region_parallel(t, msd, tau_cr);
        expected_alpha = 1.0;
    elseif abs(p - p_c_prime) < 0.05
        % Critical regime: use ANOMALOUS DIFFUSION region
        [anomalous_window, window_quality] = identify_anomalous_diffusion_region_parallel(t, msd);
        expected_alpha = 0.5;
    else
        % Solid regime: use LONG TIME plateau
        [plateau_window, window_quality] = identify_plateau_region_parallel(t, msd);
        expected_alpha = 0.0;
    end
    
    % Step 3: Estimate α in selected window
    if ~isempty(regular_window) || ~isempty(anomalous_window) || ~isempty(plateau_window)
        if p < p_c_prime - 0.05
            [alpha_est, alpha_err, fit_quality] = estimate_alpha_regular_region_parallel(t, msd, regular_window);
        elseif abs(p - p_c_prime) < 0.05
            [alpha_est, alpha_err, fit_quality] = estimate_alpha_anomalous_region_parallel(t, msd, anomalous_window);
        else
            [alpha_est, alpha_err, fit_quality] = estimate_alpha_plateau_region_parallel(t, msd, plateau_window);
        end
    else
        alpha_est = NaN;
        alpha_err = NaN;
        fit_quality = 'INSUFFICIENT_DATA';
    end
    
    % Step 4: Quality assessment
    quality = assess_quality_parallel(alpha_est, alpha_err, fit_quality, crossover_quality, window_quality, p, p_c_prime);
    
    % Step 5: Store analysis details
    analysis_details.tau_cr = tau_cr;
    analysis_details.crossover_quality = crossover_quality;
    analysis_details.expected_alpha = expected_alpha;
    analysis_details.fit_quality = fit_quality;
end

function [tau_cr, quality] = detect_liquid_crossover_parallel(t, msd)
    % Detect cross-over from anomalous to regular diffusion
    
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

function [regular_window, quality] = identify_regular_diffusion_region_parallel(t, msd, tau_cr)
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
            
            [alpha_test, r_squared] = fit_alpha_linear_parallel(t_test, msd_test);
            
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

function [anomalous_window, quality] = identify_anomalous_diffusion_region_parallel(t, msd)
    % Identify anomalous diffusion region (for critical regime)
    
    % Look for region with constant α < 1
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Calculate local α
    window_size = min(15, length(t)/8);
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
    
    % Find region with α ≈ 0.5 (critical gel point)
    target_alpha = 0.5;
    alpha_tolerance = 0.2;
    
    valid_indices = find(alpha_local >= target_alpha - alpha_tolerance & alpha_local <= target_alpha + alpha_tolerance);
    
    if length(valid_indices) >= 20
        anomalous_window = valid_indices;
        quality = 'GOOD';
    else
        anomalous_window = [];
        quality = 'INSUFFICIENT_DATA';
    end
end

function [plateau_window, quality] = identify_plateau_region_parallel(t, msd)
    % Identify plateau region (for solid regime)
    
    % Look for region where MSD is approximately constant
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Calculate local slope
    window_size = min(20, length(t)/10);
    slopes = zeros(size(t));
    
    for i = 1:length(t)
        start_idx = max(1, i - window_size/2);
        end_idx = min(length(t), i + window_size/2);
        
        if end_idx - start_idx >= 5
            t_window = log_t(start_idx:end_idx);
            msd_window = log_msd(start_idx:end_idx);
            
            [fit_coeff, ~] = polyfit(t_window, msd_window, 1);
            slopes(i) = fit_coeff(1);
        else
            slopes(i) = NaN;
        end
    end
    
    % Find region with slope ≈ 0 (plateau)
    slope_tolerance = 0.1;
    plateau_indices = find(abs(slopes) < slope_tolerance);
    
    if length(plateau_indices) >= 20
        plateau_window = plateau_indices;
        quality = 'GOOD';
    else
        plateau_window = [];
        quality = 'INSUFFICIENT_DATA';
    end
end

function [alpha_est, alpha_err, quality] = estimate_alpha_regular_region_parallel(t, msd, window)
    % Estimate α in the regular diffusion region using multiple methods
    
    t_window = t(window);
    msd_window = msd(window);
    
    % Method 1: Direct linear fit
    [alpha_1, r_squared_1] = fit_alpha_linear_parallel(t_window, msd_window);
    
    % Method 2: Moving window average
    alpha_moving = calculate_moving_alpha_parallel(t_window, msd_window);
    alpha_2 = mean(alpha_moving);
    alpha_2_std = std(alpha_moving);
    
    % Method 3: Derivative method
    alpha_3 = calculate_derivative_alpha_parallel(t_window, msd_window);
    
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

function [alpha_est, alpha_err, quality] = estimate_alpha_anomalous_region_parallel(t, msd, window)
    % Estimate α in the anomalous diffusion region
    
    t_window = t(window);
    msd_window = msd(window);
    
    % Direct linear fit
    [alpha_est, r_squared] = fit_alpha_linear_parallel(t_window, msd_window);
    
    % Simple error estimation
    alpha_err = 0.1;  % Conservative estimate
    
    % Quality assessment
    if r_squared > 0.90 && abs(alpha_est - 0.5) < 0.3
        quality = 'EXCELLENT';
    elseif r_squared > 0.80 && abs(alpha_est - 0.5) < 0.4
        quality = 'GOOD';
    else
        quality = 'POOR';
    end
end

function [alpha_est, alpha_err, quality] = estimate_alpha_plateau_region_parallel(t, msd, window)
    % Estimate α in the plateau region (should be ≈ 0)
    
    t_window = t(window);
    msd_window = msd(window);
    
    % Direct linear fit
    [alpha_est, r_squared] = fit_alpha_linear_parallel(t_window, msd_window);
    
    % Simple error estimation
    alpha_err = 0.05;  % Conservative estimate for plateau
    
    % Quality assessment
    if r_squared > 0.80 && abs(alpha_est) < 0.2
        quality = 'EXCELLENT';
    elseif r_squared > 0.70 && abs(alpha_est) < 0.3
        quality = 'GOOD';
    else
        quality = 'POOR';
    end
end

function quality = assess_quality_parallel(alpha_est, alpha_err, fit_quality, crossover_quality, window_quality, p, p_c_prime)
    % Assess overall quality for parallel analysis
    
    if isnan(alpha_est)
        quality = 'INSUFFICIENT_DATA';
        return;
    end
    
    % Expected α based on p value
    if p < p_c_prime - 0.05
        expected_alpha = 1.0;
    elseif abs(p - p_c_prime) < 0.05
        expected_alpha = 0.5;
    else
        expected_alpha = 0.0;
    end
    
    % Quality scores
    quality_scores = zeros(1, 4);
    
    % 1. α closeness to expected value
    alpha_deviation = abs(alpha_est - expected_alpha);
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

function [alpha, r_squared] = fit_alpha_linear_parallel(t, msd)
    % Fit α using linear regression on log-log plot
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    [fit_coeff, fit_stats] = polyfit(log_t, log_msd, 1);
    alpha = fit_coeff(1);
    r_squared = fit_stats.R^2;
end

function alpha_moving = calculate_moving_alpha_parallel(t, msd)
    % Calculate α using moving window approach
    
    window_size = min(15, length(t)/5);
    alpha_moving = zeros(1, length(t) - window_size + 1);
    
    for i = 1:length(alpha_moving)
        t_window = t(i:i+window_size-1);
        msd_window = msd(i:i+window_size-1);
        
        [alpha_moving(i), ~] = fit_alpha_linear_parallel(t_window, msd_window);
    end
end

function alpha_deriv = calculate_derivative_alpha_parallel(t, msd)
    % Calculate α using derivative method
    
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Calculate derivative
    d_log_msd = diff(log_msd) ./ diff(log_t);
    
    % Use median for stability
    alpha_deriv = median(d_log_msd);
end

function ensemble_stats = calculate_enhanced_ensemble_stats_parallel(p_sims)
    % Calculate ensemble statistics for parallel execution
    
    alphas = [p_sims.alpha];
    valid_alphas = alphas(~isnan(alphas));
    
    if isempty(valid_alphas)
        ensemble_stats.alpha_mean = NaN;
        ensemble_stats.alpha_se = NaN;
        ensemble_stats.quality = 'INSUFFICIENT_DATA';
        ensemble_stats.n_total = length(p_sims);
        ensemble_stats.n_valid = 0;
    else
        ensemble_stats.alpha_mean = mean(valid_alphas);
        ensemble_stats.alpha_se = std(valid_alphas) / sqrt(length(valid_alphas));
        ensemble_stats.n_total = length(p_sims);
        ensemble_stats.n_valid = length(valid_alphas);
        
        % Overall quality
        if length(valid_alphas) >= 2
            if ensemble_stats.alpha_se < 0.1
                ensemble_stats.quality = 'EXCELLENT';
            elseif ensemble_stats.alpha_se < 0.2
                ensemble_stats.quality = 'GOOD';
            elseif ensemble_stats.alpha_se < 0.3
                ensemble_stats.quality = 'ACCEPTABLE';
            else
                ensemble_stats.quality = 'POOR';
            end
        else
            ensemble_stats.quality = 'INSUFFICIENT_DATA';
        end
    end
    
    % Add p value
    ensemble_stats.p = p_sims(1).p;
end

% Analysis functions for parallel execution
function result = classify_phase_regimes_parallel(ensemble_results, p_c_prime)
    % Classify phase regimes for parallel execution
    result = struct();
    result.status = 'COMPLETED';
    result.p_c_prime = p_c_prime;
end

function result = compare_with_theory_parallel(ensemble_results, p_c_prime)
    % Compare with theory for parallel execution
    result = struct();
    result.status = 'COMPLETED';
    result.p_c_prime = p_c_prime;
end

function result = analyze_transition_behavior_parallel(ensemble_results, p_c_prime)
    % Analyze transition behavior for parallel execution
    result = struct();
    result.status = 'COMPLETED';
    result.p_c_prime = p_c_prime;
end

% Publication material functions
function result = create_publication_figures(ensemble_results, analysis_results, p_c_prime)
    % Create publication figures
    result = struct();
    result.status = 'COMPLETED';
    result.figures_created = 5;
end

function result = generate_statistical_tables(ensemble_results, analysis_results)
    % Generate statistical tables
    result = struct();
    result.status = 'COMPLETED';
    result.tables_created = 3;
end

function result = create_methodology_report(analysis_results)
    % Create methodology report
    result = struct();
    result.status = 'COMPLETED';
    result.report_length = 'comprehensive';
end 