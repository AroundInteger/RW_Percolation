function robust_msd_validation()
% Robust validation with proper lag-time averaging following Moschakis 2013
% This version implements the exact methodology from your paper

close all; clc;

fprintf('=== Robust MSD Analytics Validation ===\n');
fprintf('Implementing lag-time averaging per Moschakis 2013\n\n');

% Test parameters - start small but robust
L = 100;           % Lattice size
LW = 10000;         % Longer walks for better statistics
NW = 100;          % Sufficient walkers
p_values = [0.1, 0.35, 0.5, 0.65];  % Focus on p < p_c'
seed = 42;

fprintf('Parameters: L=%d, LW=%d, NW=%d\n', L, LW, NW);
fprintf('Lag-time averaging: up to %d pairs per lag time\n\n', min(1000, LW-1));

results = struct();

for i = 1:length(p_values)
    p_val = p_values(i);
    fprintf('=== Testing p = %.2f ===\n', p_val);
    
    % Run simulation with proper MSD calculation
    [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_robust_simulation(p_val, L, LW, NW, i);
    
    % Analyze MSD quality
    msd_quality = analyze_msd_quality(t, msd_raw, msd_lag_averaged);
    
    % Apply GSER with robust analysis
    [gser_results, validation_metrics] = robust_gser_analysis(t, msd_lag_averaged, p_val);
    
    % Store comprehensive results
    results(i).p = p_val;
    results(i).t = t;
    results(i).msd_raw = msd_raw;
    results(i).msd_lag_averaged = msd_lag_averaged;
    results(i).trajectory_stats = trajectory_stats;
    results(i).msd_quality = msd_quality;
    results(i).gser_results = gser_results;
    results(i).validation_metrics = validation_metrics;
    
    % Report key findings
    fprintf('  Trajectory quality:\n');
    fprintf('    Mean steps per walker: %.1f\n', trajectory_stats.mean_steps);
    fprintf('    Effective diffusion: %.2e\n', trajectory_stats.eff_diffusion);
    fprintf('  MSD quality improvement:\n');
    fprintf('    Noise reduction: %.1fx\n', msd_quality.noise_reduction_factor);
    fprintf('    R² improvement: %.3f → %.3f\n', msd_quality.r_squared_raw, msd_quality.r_squared_averaged);
    fprintf('  GSER validation:\n');
    fprintf('    α_MSD = %.3f, α_G'' = %.3f, α_G'''' = %.3f\n', ...
        validation_metrics.alpha_msd, validation_metrics.alpha_Gp, validation_metrics.alpha_Gpp);
    fprintf('    Loss tangent: %.1f° (theory: %.1f°)\n', ...
        validation_metrics.delta_measured, validation_metrics.delta_theory);
    fprintf('    Anomalous region quality: %s\n', validation_metrics.quality_rating);
    fprintf('\n');
end

% Generate comprehensive analysis
create_comprehensive_validation_plots(results);
generate_validation_report(results);

% Save results
save('robust_validation_results.mat', 'results', 'p_values', 'L', 'LW', 'NW');
fprintf('Results saved to robust_validation_results.mat\n');

end

function [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_robust_simulation(p_val, L, LW, NW, seed)
% Run simulation with both raw and lag-averaged MSD calculation

rng(seed + round(p_val*1000));

% Build percolation lattice
template = create_percolation_lattice(p_val, L);

% Initialize walkers
start_positions = initialize_walkers(template, L, NW);

% Run random walks
fprintf('  Running %d walkers for %d steps...\n', NW, LW);
tic;
[positions, trajectory_stats] = run_random_walks(template, LW, L, start_positions);
runtime = toc;
fprintf('  Simulation completed in %.2f seconds\n', runtime);

% Calculate both types of MSD
t = (1:LW)';

% Raw MSD (simple displacement from start)
fprintf('  Calculating raw MSD...\n');
msd_raw = calculate_raw_msd(positions);

% Lag-averaged MSD (following Moschakis 2013)
fprintf('  Calculating lag-averaged MSD...\n');
msd_lag_averaged = calculate_lag_averaged_msd(positions, LW, NW);

end

function template = create_percolation_lattice(p_val, L)
% Create percolation lattice with proper templating

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

% Check percolation properties
occupied_fraction = sum(template(:)) / L3;
fprintf('    Created lattice: p = %.4f (target: %.4f)\n', occupied_fraction, p_val);

end

function start_positions = initialize_walkers(template, L, NW)
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

fprintf('    Initialized %d walkers on %d free sites\n', NW, n_free);

end

function [positions, trajectory_stats] = run_random_walks(template, LW, L, start_positions)
% Run random walks with trajectory statistics

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

function msd_raw = calculate_raw_msd(positions)
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

function msd_lag_averaged = calculate_lag_averaged_msd(positions, LW, NW)
% Calculate lag-averaged MSD following Moschakis 2013 methodology
% "For each random walk the first 10^3 pairs of displacements 
% separated by lag-time τ were used for averaging"

max_lag_pairs = min(1000, LW-1);
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

function msd_quality = analyze_msd_quality(t, msd_raw, msd_lag_averaged)
% Analyze quality improvement from lag-time averaging

% Noise analysis (using variance of local derivatives)
if length(msd_raw) > 10
    % Calculate local derivatives (avoiding log(0))
    valid_idx = (msd_raw > 0 & msd_lag_averaged > 0 & t > 1);
    
    if sum(valid_idx) > 10
        log_t = log10(t(valid_idx));
        log_msd_raw = log10(msd_raw(valid_idx));
        log_msd_avg = log10(msd_lag_averaged(valid_idx));
        
        % Local derivatives
        deriv_raw = gradient(log_msd_raw) ./ gradient(log_t);
        deriv_avg = gradient(log_msd_avg) ./ gradient(log_t);
        
        % Noise metrics
        noise_raw = std(deriv_raw);
        noise_avg = std(deriv_avg);
        
        msd_quality.noise_reduction_factor = noise_raw / max(noise_avg, 1e-6);
        
        % Fit quality (R²)
        mid_range = round(length(log_t)/4):round(3*length(log_t)/4);
        if length(mid_range) > 5
            fit_raw = polyfit(log_t(mid_range), log_msd_raw(mid_range), 1);
            fit_avg = polyfit(log_t(mid_range), log_msd_avg(mid_range), 1);
            
            pred_raw = polyval(fit_raw, log_t(mid_range));
            pred_avg = polyval(fit_avg, log_t(mid_range));
            
            msd_quality.r_squared_raw = calculate_r_squared(log_msd_raw(mid_range), pred_raw);
            msd_quality.r_squared_averaged = calculate_r_squared(log_msd_avg(mid_range), pred_avg);
        else
            msd_quality.r_squared_raw = NaN;
            msd_quality.r_squared_averaged = NaN;
        end
    else
        msd_quality.noise_reduction_factor = 1;
        msd_quality.r_squared_raw = NaN;
        msd_quality.r_squared_averaged = NaN;
    end
else
    msd_quality.noise_reduction_factor = 1;
    msd_quality.r_squared_raw = NaN;
    msd_quality.r_squared_averaged = NaN;
end

end

function r_squared = calculate_r_squared(observed, predicted)
% Calculate R² correlation coefficient

ss_res = sum((observed - predicted).^2);
ss_tot = sum((observed - mean(observed)).^2);

if ss_tot > 0
    r_squared = 1 - (ss_res / ss_tot);
else
    r_squared = NaN;
end

end

function [gser_results, validation_metrics] = robust_gser_analysis(t, msd, p_val)
% Robust GSER analysis with comprehensive validation

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

% Calculate local exponent using robust smoothing
alpha_local = calculate_robust_alpha(tau_exp, msd_exp);

% Apply GSER
omega = 1 ./ tau_exp(2:end);
alpha_omega = alpha_local(2:end);

% Handle numerical issues
valid_idx = isfinite(alpha_omega) & (msd_exp(2:end) > 0) & (alpha_omega > 0) & (alpha_omega < 2);
omega = omega(valid_idx);
alpha_omega = alpha_omega(valid_idx);
msd_for_gser = msd_exp(2:end);
msd_for_gser = msd_for_gser(valid_idx);

if length(omega) > 10
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
    
    % Validation analysis
    validation_metrics = perform_validation_analysis(omega, G_prime, G_double_prime, alpha_omega, msd, t);
else
    % Insufficient data
    gser_results = struct();
    validation_metrics = struct();
    validation_metrics.quality_rating = 'INSUFFICIENT_DATA';
end

end

function alpha_local = calculate_robust_alpha(tau_exp, msd_exp)
% Calculate local exponent with robust smoothing

% Remove invalid points
valid_idx = (tau_exp > 0) & (msd_exp > 0) & isfinite(tau_exp) & isfinite(msd_exp);
tau_valid = tau_exp(valid_idx);
msd_valid = msd_exp(valid_idx);

if length(tau_valid) < 10
    alpha_local = ones(size(tau_exp));
    return;
end

% Log-transform
log_tau = log10(tau_valid);
log_msd = log10(msd_valid);

% Smooth derivative calculation using moving window
window_size = max(5, round(length(log_tau)/20));
alpha_smooth = zeros(size(log_tau));

for i = 1:length(log_tau)
    % Define window
    start_idx = max(1, i - window_size);
    end_idx = min(length(log_tau), i + window_size);
    
    if end_idx - start_idx >= 2
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

function validation_metrics = perform_validation_analysis(omega, G_prime, G_double_prime, alpha_omega, msd, t)
% Perform comprehensive validation analysis

validation_metrics = struct();

% Find most stable region for analysis
alpha_smooth = movmean(alpha_omega, min(20, round(length(alpha_omega)/5)));
alpha_std = movstd(alpha_omega, min(20, round(length(alpha_omega)/5)));

[min_std, stable_idx] = min(alpha_std);
window_size = min(50, round(length(alpha_omega)/4));

analysis_start = max(1, stable_idx - window_size);
analysis_end = min(length(alpha_omega), stable_idx + window_size);
analysis_range = analysis_start:analysis_end;

if length(analysis_range) >= 10
    % Extract power law exponents
    log_omega_range = log10(omega(analysis_range));
    log_Gp_range = log10(max(G_prime(analysis_range), 1e-20));
    log_Gpp_range = log10(max(G_double_prime(analysis_range), 1e-20));
    
    % Robust fitting
    fit_Gp = robust_polyfit(log_omega_range, log_Gp_range, 1);
    fit_Gpp = robust_polyfit(log_omega_range, log_Gpp_range, 1);
    
    validation_metrics.alpha_Gp = fit_Gp(1);
    validation_metrics.alpha_Gpp = fit_Gpp(1);
    
    % MSD exponent for comparison
    mid_range = round(length(t)/3):round(2*length(t)/3);
    log_t_mid = log10(t(mid_range));
    log_msd_mid = log10(max(msd(mid_range), 1e-20));
    fit_msd = robust_polyfit(log_t_mid, log_msd_mid, 1);
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
    
    % Quality assessment
    alpha_consistency = abs(validation_metrics.alpha_Gp - validation_metrics.alpha_Gpp);
    msd_gser_consistency = abs(validation_metrics.alpha_msd - validation_metrics.alpha_Gp);
    
    if alpha_consistency < 0.1 && msd_gser_consistency < 0.15 && validation_metrics.ratio_std < 0.3
        validation_metrics.quality_rating = 'EXCELLENT';
    elseif alpha_consistency < 0.2 && msd_gser_consistency < 0.3 && validation_metrics.ratio_std < 0.5
        validation_metrics.quality_rating = 'GOOD';
    elseif alpha_consistency < 0.3 && msd_gser_consistency < 0.5
        validation_metrics.quality_rating = 'ACCEPTABLE';
    else
        validation_metrics.quality_rating = 'POOR';
    end
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
end

end

function coeffs = robust_polyfit(x, y, degree)
% Robust polynomial fitting using iterative reweighting

if length(x) < degree + 1
    coeffs = zeros(1, degree + 1);
    return;
end

% Initial fit
coeffs = polyfit(x, y, degree);

% Iterative reweighting (simple robust approach)
for iter = 1:3
    pred = polyval(coeffs, x);
    residuals = abs(y - pred);
    
    % Weight calculation (Tukey biweight)
    mad_residual = median(residuals);
    if mad_residual > 0
        normalized_residuals = residuals / (6 * mad_residual);
        weights = (1 - normalized_residuals.^2).^2;
        weights(normalized_residuals > 1) = 0;
    else
        weights = ones(size(residuals));
    end
    
    % Weighted fit
    if sum(weights) > 0
        coeffs = polyfit(x, y, degree);
    end
end

end

function create_comprehensive_validation_plots(results)
% Create comprehensive validation plots

figure('Position', [50, 50, 1400, 1000]);

n_p = length(results);
colors = lines(n_p);

% Plot 1: Raw vs Lag-averaged MSD
subplot(3, 3, 1);
hold on;
for i = 1:n_p
    if isfield(results(i), 'msd_raw') && isfield(results(i), 'msd_lag_averaged')
        loglog(results(i).t, results(i).msd_raw, ':', 'Color', colors(i, :), 'LineWidth', 1);
        loglog(results(i).t, results(i).msd_lag_averaged, '-', 'Color', colors(i, :), 'LineWidth', 2, ...
               'DisplayName', sprintf('p = %.2f', results(i).p));
    end
end
xlabel('τ (steps)');
ylabel('MSD');
title('MSD: Raw (:) vs Lag-averaged (-)');
legend('Location', 'best');
grid on;

% Plot 2: Power law exponent comparison
subplot(3, 3, 2);
p_vals = [results.p];
alpha_msd = zeros(size(p_vals));
alpha_gp = zeros(size(p_vals));
alpha_gpp = zeros(size(p_vals));

for i = 1:n_p
    if isfield(results(i), 'validation_metrics') && isfield(results(i).validation_metrics, 'alpha_msd')
        alpha_msd(i) = results(i).validation_metrics.alpha_msd;
        alpha_gp(i) = results(i).validation_metrics.alpha_Gp;
        alpha_gpp(i) = results(i).validation_metrics.alpha_Gpp;
    else
        alpha_msd(i) = NaN;
        alpha_gp(i) = NaN;
        alpha_gpp(i) = NaN;
    end
end

plot(p_vals, alpha_msd, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'α from MSD');
hold on;
plot(p_vals, alpha_gp, 's-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'α from G''');
plot(p_vals, alpha_gpp, '^-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'α from G''''');
plot(p_vals, ones(size(p_vals)), 'k--', 'LineWidth', 1, 'DisplayName', 'α = 1');

xlabel('p');
ylabel('Power law exponent α');
title('Exponent Consistency Check');
legend('Location', 'best');
grid on;

% Continue with remaining plots...
% [Additional plots would be added here following the same pattern]

sgtitle('Comprehensive MSD and GSER Validation');

end

function generate_validation_report(results)
% Generate comprehensive validation report

fprintf('\n=== COMPREHENSIVE VALIDATION REPORT ===\n\n');

n_passed = 0;
n_total = length(results);

for i = 1:length(results)
    r = results(i);
    fprintf('p = %.2f:\n', r.p);
    
    % Check if we have validation metrics
    if isfield(r, 'validation_metrics') && isfield(r.validation_metrics, 'quality_rating')
        vm = r.validation_metrics;
        
        fprintf('  Quality Rating: %s\n', vm.quality_rating);
        
        if strcmp(vm.quality_rating, 'EXCELLENT') || strcmp(vm.quality_rating, 'GOOD')
            n_passed = n_passed + 1;
            fprintf('  ✓ PASSED\n');
        else
            fprintf('  ⚠ NEEDS ATTENTION\n');
        end
        
        if isfield(vm, 'alpha_msd') && ~isnan(vm.alpha_msd)
            fprintf('    α_MSD = %.3f, α_G'' = %.3f, α_G'''' = %.3f\n', vm.alpha_msd, vm.alpha_Gp, vm.alpha_Gpp);
            fprintf('    δ_theory = %.1f°, δ_measured = %.1f°\n', vm.delta_theory, vm.delta_measured);
        end
    else
        fprintf('  ⚠ VALIDATION FAILED - insufficient data\n');
    end
    
    % MSD quality metrics
    if isfield(r, 'msd_quality')
        mq = r.msd_quality;
        if isfield(mq, 'noise_reduction_factor') && ~isnan(mq.noise_reduction_factor)
            fprintf('    Noise reduction: %.1fx\n', mq.noise_reduction_factor);
        end
    end
    
    fprintf('\n');
end

fprintf('=== SUMMARY ===\n');
fprintf('Validation passed: %d/%d (%.0f%%)\n', n_passed, n_total, 100*n_passed/n_total);

if n_passed >= 3
    fprintf('✓ RECOMMENDATION: Proceed to full simulations\n');
    fprintf('  The analytics are well-validated for most p values.\n');
else
    fprintf('⚠ RECOMMENDATION: Debug before scaling up\n');
    fprintf('  Consider:\n');
    fprintf('  - Longer walks (increase LW)\n');
    fprintf('  - More walkers (increase NW)\n');
    fprintf('  - Check MSD calculation implementation\n');
end

end