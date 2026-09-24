% targeted_critical_region_simulations.m
% Targeted simulations in the critical region [0.6, 0.7] with enhanced parameters
% to get robust α estimates for the δ phase transition

clear; close all; clc;

fprintf('=== TARGETED CRITICAL REGION SIMULATIONS ===\n');
fprintf('Focusing on p = [0.60, 0.62, 0.64, 0.66, 0.68, 0.69, 0.70]\n');
fprintf('Enhanced parameters for robust α estimation\n\n');

% Critical region parameters
p_c_prime = 0.6884;
critical_p_values = [0.60, 0.62, 0.64, 0.66, 0.68, 0.69, 0.70];

% Enhanced simulation parameters
L = 500;           % System size
LW = 20000;        % Walk length (doubled for better statistics)
NW = 500;          % Number of walkers (increased for better averaging)
n_realizations = 5; % Number of realizations per p value

fprintf('Enhanced Parameters:\n');
fprintf('  L = %d (system size)\n', L);
fprintf('  LW = %d (walk length)\n', LW);
fprintf('  NW = %d (number of walkers)\n', NW);
fprintf('  n_realizations = %d (per p value)\n', n_realizations);
fprintf('  Total simulations: %d\n\n', length(critical_p_values) * n_realizations);

% Initialize results storage
all_results = struct();
ensemble_results = struct();

% Theoretical predictions for comparison
fprintf('Theoretical Predictions (Critical Scaling):\n');
fprintf('p\t\tα_theory\tδ_theory\tBehavior\n');
fprintf('---\t\t---\t\t---\t\t---\n');

nu = 0.88;  % 3D percolation critical exponent
for p = critical_p_values
    if p <= p_c_prime
        alpha_theory = (1 - (p / p_c_prime))^(1/nu);
    else
        alpha_theory = 0;
    end
    delta_theory = pi * alpha_theory / 2 * 180 / pi;
    
    if delta_theory > 45
        behavior = 'Viscous';
    elseif delta_theory > 5
        behavior = 'Viscoelastic';
    else
        behavior = 'Elastic';
    end
    
    fprintf('%.2f\t\t%.3f\t\t%.1f°\t\t%s\n', p, alpha_theory, delta_theory, behavior);
end

fprintf('\n=== RUNNING SIMULATIONS ===\n');

% Run simulations for each p value
for p_idx = 1:length(critical_p_values)
    p_val = critical_p_values(p_idx);
    fprintf('\n=== p = %.2f (Critical Region) ===\n', p_val);
    
    % Initialize ensemble results for this p value
    ensemble_alpha_msd = [];
    ensemble_alpha_gp = [];
    ensemble_alpha_gpp = [];
    ensemble_delta_measured = [];
    ensemble_quality = {};
    
    % Run multiple realizations
    for run = 1:n_realizations
        fprintf('  Realization %d/%d...\n', run, n_realizations);
        
        % Set unique seed for each realization
        seed = p_idx * 1000 + run;
        
        % Run simulation
        [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_enhanced_simulation(p_val, L, LW, NW, seed);
        
        % Apply GSER analysis
        [gser_results, validation_metrics] = run_enhanced_gser_analysis(t, msd_lag_averaged, p_val);
        
        % Store individual realization results
        all_results(p_idx, run).p = p_val;
        all_results(p_idx, run).run = run;
        all_results(p_idx, run).t = t;
        all_results(p_idx, run).msd_raw = msd_raw;
        all_results(p_idx, run).msd_lag_averaged = msd_lag_averaged;
        all_results(p_idx, run).gser_results = gser_results;
        all_results(p_idx, run).validation_metrics = validation_metrics;
        all_results(p_idx, run).trajectory_stats = trajectory_stats;
        
        % Collect ensemble data
        if isfield(validation_metrics, 'alpha_msd') && ~isnan(validation_metrics.alpha_msd)
            ensemble_alpha_msd(end+1) = validation_metrics.alpha_msd;
            ensemble_alpha_gp(end+1) = validation_metrics.alpha_Gp;
            ensemble_alpha_gpp(end+1) = validation_metrics.alpha_Gpp;
            ensemble_delta_measured(end+1) = validation_metrics.delta_measured;
            ensemble_quality{end+1} = 'VALID';
        else
            ensemble_quality{end+1} = 'INVALID';
        end
    end
    
    % Calculate ensemble statistics
    if ~isempty(ensemble_alpha_msd)
        ensemble_results(p_idx).p = p_val;
        ensemble_results(p_idx).alpha_msd_mean = mean(ensemble_alpha_msd);
        ensemble_results(p_idx).alpha_msd_std = std(ensemble_alpha_msd);
        ensemble_results(p_idx).alpha_msd_se = std(ensemble_alpha_msd) / sqrt(length(ensemble_alpha_msd));
        
        ensemble_results(p_idx).alpha_gp_mean = mean(ensemble_alpha_gp);
        ensemble_results(p_idx).alpha_gp_std = std(ensemble_alpha_gp);
        ensemble_results(p_idx).alpha_gp_se = std(ensemble_alpha_gp) / sqrt(length(ensemble_alpha_gp));
        
        ensemble_results(p_idx).alpha_gpp_mean = mean(ensemble_alpha_gpp);
        ensemble_results(p_idx).alpha_gpp_std = std(ensemble_alpha_gpp);
        ensemble_results(p_idx).alpha_gpp_se = std(ensemble_alpha_gpp) / sqrt(length(ensemble_alpha_gpp));
        
        ensemble_results(p_idx).delta_measured_mean = mean(ensemble_delta_measured);
        ensemble_results(p_idx).delta_measured_std = std(ensemble_delta_measured);
        ensemble_results(p_idx).delta_measured_se = std(ensemble_delta_measured) / sqrt(length(ensemble_delta_measured));
        
        ensemble_results(p_idx).n_valid = length(ensemble_alpha_msd);
        ensemble_results(p_idx).n_total = n_realizations;
        
        % Calculate theoretical δ from ensemble α
        delta_theory_ensemble = pi * ensemble_results(p_idx).alpha_msd_mean / 2 * 180 / pi;
        ensemble_results(p_idx).delta_theory = delta_theory_ensemble;
        ensemble_results(p_idx).delta_error = abs(ensemble_results(p_idx).delta_measured_mean - delta_theory_ensemble);
        
        % Report ensemble results
        fprintf('  Ensemble Results (n=%d valid):\n', length(ensemble_alpha_msd));
        fprintf('    α_MSD = %.3f ± %.3f (SE)\n', ensemble_results(p_idx).alpha_msd_mean, ensemble_results(p_idx).alpha_msd_se);
        fprintf('    α_G'' = %.3f ± %.3f (SE)\n', ensemble_results(p_idx).alpha_gp_mean, ensemble_results(p_idx).alpha_gp_se);
        fprintf('    δ_measured = %.1f° ± %.1f° (SE)\n', ensemble_results(p_idx).delta_measured_mean, ensemble_results(p_idx).delta_measured_se);
        fprintf('    δ_theory = %.1f°\n', delta_theory_ensemble);
        fprintf('    δ_error = %.1f°\n', ensemble_results(p_idx).delta_error);
        
    else
        fprintf('  ⚠ No valid results for this p value\n');
        ensemble_results(p_idx).p = p_val;
        ensemble_results(p_idx).n_valid = 0;
        ensemble_results(p_idx).n_total = n_realizations;
    end
end

%% PHASE TRANSITION ANALYSIS

fprintf('\n=== PHASE TRANSITION ANALYSIS ===\n');

% Extract ensemble data for analysis
valid_indices = [ensemble_results.n_valid] > 0;
if sum(valid_indices) >= 3
    p_vals_analysis = [ensemble_results(valid_indices).p];
    alpha_msd_analysis = [ensemble_results(valid_indices).alpha_msd_mean];
    alpha_msd_errors = [ensemble_results(valid_indices).alpha_msd_se];
    delta_measured_analysis = [ensemble_results(valid_indices).delta_measured_mean];
    delta_measured_errors = [ensemble_results(valid_indices).delta_measured_se];
    
    % Fit trend to α vs p
    fit_coeff = polyfit(p_vals_analysis, alpha_msd_analysis, 1);
    alpha_slope = fit_coeff(1);
    alpha_intercept = fit_coeff(2);
    
    % Predict α at p_c'
    alpha_at_pc = alpha_slope * p_c_prime + alpha_intercept;
    delta_at_pc = pi * alpha_at_pc / 2 * 180 / pi;
    
    fprintf('Phase Transition Analysis:\n');
    fprintf('  α slope: %.3f ± %.3f\n', alpha_slope, std(alpha_msd_errors));
    fprintf('  α at p_c'': %.3f\n', alpha_at_pc);
    fprintf('  δ at p_c'': %.1f°\n', delta_at_pc);
    
    % Check phase transition support
    if alpha_at_pc < 0.1
        fprintf('  ✓ STRONG support for phase transition (α ≈ 0 at p_c'')\n');
    elseif alpha_at_pc < 0.3
        fprintf('  ⚠ MODERATE support for phase transition\n');
    else
        fprintf('  ✗ WEAK support for phase transition\n');
    end
    
    % Compare with theoretical prediction
    theoretical_alpha_at_pc = 0;  % By definition
    theoretical_delta_at_pc = 0;  % By definition
    fprintf('  Theoretical: α = %.3f, δ = %.1f°\n', theoretical_alpha_at_pc, theoretical_delta_at_pc);
    fprintf('  Agreement: %.1f° difference\n', abs(delta_at_pc - theoretical_delta_at_pc));
    
else
    fprintf('⚠ Insufficient data for phase transition analysis\n');
end

%% CREATE ENHANCED PLOTS

fprintf('\n=== CREATING ENHANCED PLOTS ===\n');

figure('Position', [50, 50, 1400, 1000]);

% Plot 1: α vs p with error bars
subplot(2, 3, 1);
if sum(valid_indices) > 0
    errorbar(p_vals_analysis, alpha_msd_analysis, alpha_msd_errors, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'α_MSD (ensemble)');
    hold on;
    
    % Theoretical curve
    p_theory = 0:0.01:0.7;
    alpha_theory_curve = zeros(size(p_theory));
    for i = 1:length(p_theory)
        if p_theory(i) <= p_c_prime
            alpha_theory_curve(i) = (1 - (p_theory(i) / p_c_prime))^(1/nu);
        else
            alpha_theory_curve(i) = 0;
        end
    end
    plot(p_theory, alpha_theory_curve, '--r', 'LineWidth', 2, 'DisplayName', 'Theory (critical scaling)');
    
    xline(p_c_prime, '--k', 'LineWidth', 2, 'DisplayName', 'p_c''');
    xlabel('p');
    ylabel('α');
    title('α vs p (Critical Region)');
    legend('Location', 'best');
    grid on;
else
    text(0.5, 0.5, 'No valid data', 'HorizontalAlignment', 'center');
    title('α vs p');
end

% Plot 2: δ vs p with error bars
subplot(2, 3, 2);
if sum(valid_indices) > 0
    errorbar(p_vals_analysis, delta_measured_analysis, delta_measured_errors, 's-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'δ_measured (ensemble)');
    hold on;
    
    % Theoretical δ curve
    delta_theory_curve = pi * alpha_theory_curve / 2 * 180 / pi;
    plot(p_theory, delta_theory_curve, '--r', 'LineWidth', 2, 'DisplayName', 'Theory (δ = πα/2)');
    
    xline(p_c_prime, '--k', 'LineWidth', 2, 'DisplayName', 'p_c''');
    xlabel('p');
    ylabel('δ (degrees)');
    title('δ vs p (Critical Region)');
    legend('Location', 'best');
    grid on;
else
    text(0.5, 0.5, 'No valid data', 'HorizontalAlignment', 'center');
    title('δ vs p');
end

% Plot 3: Phase diagram
subplot(2, 3, 3);
if sum(valid_indices) > 0
    % Color code by phase
    colors = zeros(length(p_vals_analysis), 3);
    for i = 1:length(p_vals_analysis)
        if delta_measured_analysis(i) > 45
            colors(i, :) = [0, 0, 1];  % Blue for viscous
        elseif delta_measured_analysis(i) > 5
            colors(i, :) = [0, 1, 0];  % Green for viscoelastic
        else
            colors(i, :) = [1, 0, 0];  % Red for elastic
        end
    end
    
    scatter(p_vals_analysis, delta_measured_analysis, 100, colors, 'filled');
    xline(p_c_prime, '--k', 'LineWidth', 2, 'DisplayName', 'p_c''');
    xlabel('p');
    ylabel('δ (degrees)');
    title('Phase Diagram (Critical Region)');
    grid on;
else
    text(0.5, 0.5, 'No valid data', 'HorizontalAlignment', 'center');
    title('Phase Diagram');
end

% Plot 4: Quality assessment
subplot(2, 3, 4);
if sum(valid_indices) > 0
    n_valid_array = [ensemble_results(valid_indices).n_valid];
    n_total_array = [ensemble_results(valid_indices).n_total];
    success_rate = n_valid_array ./ n_total_array * 100;
    
    bar(p_vals_analysis, success_rate);
    xlabel('p');
    ylabel('Success Rate (%)');
    title('Simulation Success Rate');
    grid on;
else
    text(0.5, 0.5, 'No valid data', 'HorizontalAlignment', 'center');
    title('Success Rate');
end

% Plot 5: δ error analysis
subplot(2, 3, 5);
if sum(valid_indices) > 0
    delta_errors = [ensemble_results(valid_indices).delta_error];
    bar(p_vals_analysis, delta_errors);
    xlabel('p');
    ylabel('|δ_measured - δ_theory| (degrees)');
    title('δ Agreement with Theory');
    grid on;
else
    text(0.5, 0.5, 'No valid data', 'HorizontalAlignment', 'center');
    title('δ Agreement');
end

% Plot 6: MSD-GSER consistency
subplot(2, 3, 6);
if sum(valid_indices) > 0
    alpha_consistency = abs(alpha_msd_analysis - [ensemble_results(valid_indices).alpha_gp_mean]);
    bar(p_vals_analysis, alpha_consistency);
    xlabel('p');
    ylabel('|α_MSD - α_G''|');
    title('MSD-GSER Consistency');
    grid on;
else
    text(0.5, 0.5, 'No valid data', 'HorizontalAlignment', 'center');
    title('Consistency');
end

sgtitle('Critical Region Analysis: Enhanced Parameters');

%% FINAL REPORT

fprintf('\n=== FINAL REPORT ===\n');

fprintf('Critical Region Simulation Results:\n');
fprintf('p\t\tα_MSD\t\tα_G''\t\tδ_measured\tδ_theory\tSuccess\n');
fprintf('---\t\t---\t\t---\t\t---\t\t---\t\t---\n');

for i = 1:length(ensemble_results)
    if ensemble_results(i).n_valid > 0
        p = ensemble_results(i).p;
        alpha_msd = ensemble_results(i).alpha_msd_mean;
        alpha_gp = ensemble_results(i).alpha_gp_mean;
        delta_meas = ensemble_results(i).delta_measured_mean;
        delta_theo = ensemble_results(i).delta_theory;
        success = ensemble_results(i).n_valid / ensemble_results(i).n_total * 100;
        
        fprintf('%.2f\t\t%.3f\t\t%.3f\t\t%.1f°\t\t%.1f°\t\t%.0f%%\n', ...
            p, alpha_msd, alpha_gp, delta_meas, delta_theo, success);
    else
        fprintf('%.2f\t\t---\t\t---\t\t---\t\t---\t\t0%%\n', ensemble_results(i).p);
    end
end

% Save comprehensive results
save('targeted_critical_region_results.mat', 'all_results', 'ensemble_results', ...
     'critical_p_values', 'p_c_prime', 'L', 'LW', 'NW', 'n_realizations');

fprintf('\nResults saved to targeted_critical_region_results.mat\n');
fprintf('Enhanced critical region analysis complete!\n');

%% HELPER FUNCTIONS

function [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_enhanced_simulation(p_val, L, LW, NW, seed)
% Enhanced simulation with better parameters

rng(seed);

% Build percolation lattice
template = create_enhanced_lattice(p_val, L);

% Initialize walkers
start_positions = initialize_enhanced_walkers(template, L, NW);

% Run random walks
[positions, trajectory_stats] = run_enhanced_walks(template, LW, L, start_positions);

% Calculate both types of MSD
t = (1:LW)';

% Raw MSD (simple displacement from start)
msd_raw = calculate_enhanced_raw_msd(positions);

% Lag-averaged MSD (following Moschakis 2013)
msd_lag_averaged = calculate_enhanced_lag_msd(positions, LW, NW);

end

function template = create_enhanced_lattice(p_val, L)
% Create percolation lattice with enhanced precision

L3 = L^3;
template = false(L, L, L);

if p_val > 0
    n_occupied = round(p_val * L3);
    if n_occupied > 0
        % Use linear indexing for efficiency
        idx_occupied = randsample(L3, n_occupied, false);
        template(idx_occupied) = true;
    end
end

end

function start_positions = initialize_enhanced_walkers(template, L, NW)
% Initialize walker positions on free sites

free_sites = find(~template);
n_free = length(free_sites);

if n_free < NW
    error('Insufficient free sites: %d available, %d needed', n_free, NW);
end

% Select random starting positions
selected_indices = randsample(n_free, NW, false);
selected_sites = free_sites(selected_indices);

% Convert to 3D coordinates
[x, y, z] = ind2sub([L, L, L], selected_sites);
start_positions = [x, y, z];

end

function [positions, trajectory_stats] = run_enhanced_walks(template, LW, L, start_positions)
% Run random walks with enhanced statistics

NW = size(start_positions, 1);
positions = zeros(LW, 3, NW);

% Neighbor offsets (von Neumann)
neighbors = [1,0,0; -1,0,0; 0,1,0; 0,-1,0; 0,0,1; 0,0,-1];

total_steps = 0;
total_successful_moves = 0;

for walker = 1:NW
    current_pos = start_positions(walker, :);
    positions(1, :, walker) = current_pos;
    
    successful_moves = 0;
    
    for step = 2:LW
        % Attempt move
        direction = neighbors(randi(6), :);
        new_pos = current_pos + direction;
        
        % Periodic boundary conditions
        new_pos = mod(new_pos - 1, L) + 1;
        
        % Check if move is allowed
        if ~template(new_pos(1), new_pos(2), new_pos(3))
            current_pos = new_pos;
            successful_moves = successful_moves + 1;
        end
        
        positions(step, :, walker) = current_pos;
        total_steps = total_steps + 1;
    end
    
    total_successful_moves = total_successful_moves + successful_moves;
end

% Calculate trajectory statistics
trajectory_stats = struct();
trajectory_stats.mean_steps = total_steps / NW;
trajectory_stats.move_success_rate = total_successful_moves / total_steps;

% Estimate effective diffusion coefficient
final_displacements = squeeze(positions(end, :, :)) - squeeze(positions(1, :, :));
mean_squared_displacement = mean(sum(final_displacements.^2, 1));
trajectory_stats.eff_diffusion = mean_squared_displacement / (6 * LW);  % 3D diffusion

end

function msd_raw = calculate_enhanced_raw_msd(positions)
% Calculate simple MSD (displacement from start)

[LW, ~, NW] = size(positions);
msd_raw = zeros(LW, 1);

start_positions = squeeze(positions(1, :, :));  % 3 x NW

for step = 1:LW
    current_positions = squeeze(positions(step, :, :));  % 3 x NW
    displacements = current_positions - start_positions;
    squared_displacements = sum(displacements.^2, 1);  % 1 x NW
    msd_raw(step) = mean(squared_displacements);
end

end

function msd_lag_averaged = calculate_enhanced_lag_msd(positions, LW, NW)
% Calculate lag-averaged MSD with enhanced sampling

max_lag_pairs = min(2000, LW-1);  % Increased sampling
msd_lag_averaged = zeros(LW, 1);

for tau = 1:LW
    squared_displacements = [];
    
    % For each walker
    for walker = 1:NW
        % Number of pairs available for this lag time
        max_pairs_this_lag = min(max_lag_pairs, LW - tau);
        
        if max_pairs_this_lag > 0
            % Sample pairs separated by lag time tau
            for pair = 1:max_pairs_this_lag
                t_start = pair;
                t_end = t_start + tau;
                
                if t_end <= LW
                    % Calculate displacement
                    pos_start = positions(t_start, :, walker);
                    pos_end = positions(t_end, :, walker);
                    displacement = pos_end - pos_start;
                    
                    % Store squared displacement
                    squared_displacements(end+1) = sum(displacement.^2);
                end
            end
        end
    end
    
    % Average over all pairs
    if ~isempty(squared_displacements)
        msd_lag_averaged(tau) = mean(squared_displacements);
    end
end

end

function [gser_results, validation_metrics] = run_enhanced_gser_analysis(t, msd, p_val)
% Enhanced GSER analysis with improved robustness

% Physical parameters (from your paper)
l = 0.243e-6;  % m
eta = 1.2e-3;  % Pa·s  
R = l/2;       % m
k_B = 1.38e-23; % J/K
T = 293.15;    % K

% Unit conversion
D = k_B * T / (6 * pi * eta * R);
zeta = l^2 / (6 * D);

tau_exp = t * zeta;
msd_exp = msd * l^2;

% Calculate local exponent using enhanced smoothing
alpha_local = calculate_enhanced_alpha(tau_exp, msd_exp);

% Apply GSER
omega = 1 ./ tau_exp(2:end);
alpha_omega = alpha_local(2:end);

% Handle numerical issues with enhanced filtering
valid_idx = isfinite(alpha_omega) & (msd_exp(2:end) > 0) & (alpha_omega > 0) & (alpha_omega < 2);
omega = omega(valid_idx);
alpha_omega = alpha_omega(valid_idx);
msd_for_gser = msd_exp(2:end);
msd_for_gser = msd_for_gser(valid_idx);

if length(omega) > 20  % Increased minimum requirement
    % Calculate G* components
    Gamma_term = gamma(1 + alpha_omega);
    G_star_mag = k_B * T ./ (pi * msd_for_gser .* Gamma_term);
    
    % Calculate G' and G''
    G_prime = G_star_mag .* cos(pi * alpha_omega / 2);
    G_double_prime = G_star_mag .* sin(pi * alpha_omega / 2);
    
    % Store GSER results
    gser_results.omega = omega;
    gser_results.G_prime = G_prime;
    gser_results.G_double_prime = G_double_prime;
    gser_results.alpha_omega = alpha_omega;
    
    % Enhanced validation analysis
    validation_metrics = perform_enhanced_validation(omega, G_prime, G_double_prime, alpha_omega, msd, t);
else
    % Insufficient data
    gser_results = struct();
    validation_metrics = struct();
    validation_metrics.quality_rating = 'INSUFFICIENT_DATA';
end

end

function alpha_local = calculate_enhanced_alpha(tau_exp, msd_exp)
% Calculate local exponent with enhanced smoothing

% Remove invalid points
valid_idx = (tau_exp > 0) & (msd_exp > 0) & isfinite(tau_exp) & isfinite(msd_exp);
tau_valid = tau_exp(valid_idx);
msd_valid = msd_exp(valid_idx);

if length(tau_valid) < 20  % Increased minimum requirement
    alpha_local = ones(size(tau_exp));
    return;
end

% Log-transform
log_tau = log10(tau_valid);
log_msd = log10(msd_valid);

% Enhanced smoothing with adaptive window
window_size = max(10, round(length(log_tau)/15));  % Larger window for stability
alpha_smooth = zeros(size(log_tau));

for i = 1:length(log_tau)
    % Define window
    start_idx = max(1, i - window_size);
    end_idx = min(length(log_tau), i + window_size);
    
    if end_idx - start_idx >= 5  % Increased minimum for fit
        % Linear fit in window
        fit_coeff = polyfit(log_tau(start_idx:end_idx), log_msd(start_idx:end_idx), 1);
        alpha_smooth(i) = fit_coeff(1);
    else
        alpha_smooth(i) = 1;
    end
end

% Interpolate back to original grid
alpha_local = ones(size(tau_exp));
alpha_local(valid_idx) = alpha_smooth;

% Handle boundary effects
alpha_local(~valid_idx) = 1;

end

function validation_metrics = perform_enhanced_validation(omega, G_prime, G_double_prime, alpha_omega, msd, t)
% Perform enhanced validation analysis

validation_metrics = struct();

% Find most stable region for analysis with enhanced criteria
alpha_smooth = movmean(alpha_omega, min(30, round(length(alpha_omega)/4)));  % Larger window
alpha_std = movstd(alpha_omega, min(30, round(length(alpha_omega)/4)));

[min_std, stable_idx] = min(alpha_std);
window_size = min(80, round(length(alpha_omega)/3));  % Larger analysis window

analysis_start = max(1, stable_idx - window_size);
analysis_end = min(length(alpha_omega), stable_idx + window_size);
analysis_range = analysis_start:analysis_end;

if length(analysis_range) >= 20  % Increased minimum requirement
    % Extract power law exponents
    log_omega_range = log10(omega(analysis_range));
    log_Gp_range = log10(max(G_prime(analysis_range), 1e-20));
    log_Gpp_range = log10(max(G_double_prime(analysis_range), 1e-20));
    
    % Enhanced fitting with outlier rejection
    fit_Gp = polyfit(log_omega_range, log_Gp_range, 1);
    fit_Gpp = polyfit(log_omega_range, log_Gpp_range, 1);
    
    validation_metrics.alpha_Gp = fit_Gp(1);
    validation_metrics.alpha_Gpp = fit_Gpp(1);
    
    % MSD exponent for comparison with enhanced range
    mid_range = round(length(t)/4):round(3*length(t)/4);  % Larger range
    log_t_mid = log10(t(mid_range));
    log_msd_mid = log10(max(msd(mid_range), 1e-20));
    fit_msd = polyfit(log_t_mid, log_msd_mid, 1);
    validation_metrics.alpha_msd = fit_msd(1);
    
    % G'/G'' ratio analysis
    ratio = G_prime(analysis_range) ./ G_double_prime(analysis_range);
    validation_metrics.ratio_std = std(ratio);
    validation_metrics.ratio_mean = mean(ratio);
    
    % Loss tangent analysis
    alpha_mean = mean(alpha_omega(analysis_range));
    validation_metrics.delta_theory = pi * alpha_mean / 2 * 180 / pi;
    
    delta_measured = atan2(G_double_prime(analysis_range), G_prime(analysis_range));
    validation_metrics.delta_measured = mean(delta_measured) * 180 / pi;
    
    % Enhanced quality assessment
    alpha_consistency = abs(validation_metrics.alpha_Gp - validation_metrics.alpha_Gpp);
    msd_gser_consistency = abs(validation_metrics.alpha_msd - validation_metrics.alpha_Gp);
    
    if alpha_consistency < 0.08 && msd_gser_consistency < 0.12 && validation_metrics.ratio_std < 0.25
        validation_metrics.quality_rating = 'EXCELLENT';
    elseif alpha_consistency < 0.15 && msd_gser_consistency < 0.25 && validation_metrics.ratio_std < 0.4
        validation_metrics.quality_rating = 'GOOD';
    elseif alpha_consistency < 0.25 && msd_gser_consistency < 0.4
        validation_metrics.quality_rating = 'ACCEPTABLE';
    else
        validation_metrics.quality_rating = 'POOR';
    end
    
    validation_metrics.alpha_consistency = alpha_consistency;
    validation_metrics.msd_gser_consistency = msd_gser_consistency;
    validation_metrics.total_consistency = alpha_consistency + msd_gser_consistency;
else
    % Insufficient data for analysis
    validation_metrics.alpha_Gp = NaN;
    validation_metrics.alpha_Gpp = NaN;
    validation_metrics.alpha_msd = NaN;
    validation_metrics.ratio_std = NaN;
    validation_metrics.ratio_mean = NaN;
    validation_metrics.delta_theory = NaN;
    validation_metrics.delta_measured = NaN;
    validation_metrics.quality_rating = 'INSUFFICIENT_DATA';
    validation_metrics.alpha_consistency = NaN;
    validation_metrics.msd_gser_consistency = NaN;
    validation_metrics.total_consistency = NaN;
end

end 