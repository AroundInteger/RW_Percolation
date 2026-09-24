% diagnose_high_percolation.m
% Investigate and optimize analysis for high percolation values (p = 0.8)

clear; close all; clc;

fprintf('=== HIGH PERCOLATION DIAGNOSTIC ===\n');
fprintf('Investigating p = 0.8 issues and optimizing analysis\n\n');

% Test parameters
L = 100;           % Lattice size
LW = 10000;        % Walk length
NW = 100;          % Number of walkers
p_val = 0.8;       % High percolation
seed = 42;

fprintf('Parameters: L=%d, LW=%d, NW=%d, p=%.1f\n', L, LW, NW, p_val);

% Run simulation with detailed analysis
[t, msd_raw, msd_lag_averaged, trajectory_stats] = run_standalone_simulation(p_val, L, LW, NW, seed);

% Detailed MSD analysis
fprintf('\n=== MSD ANALYSIS ===\n');
fprintf('Raw MSD range: %.2e to %.2e\n', min(msd_raw), max(msd_raw));
fprintf('Lag-averaged MSD range: %.2e to %.2e\n', min(msd_lag_averaged), max(msd_lag_averaged));

% Check MSD quality
valid_msd = (t > 1) & (msd_lag_averaged > 0);
fprintf('Valid MSD points: %d/%d\n', sum(valid_msd), length(t));

% MSD fits over different ranges
ranges = {[1, LW], [LW/4, 3*LW/4], [LW/3, 2*LW/3], [LW/2, LW], [2*LW/3, LW]};
range_names = {'Full', 'Middle 50%', 'Middle 33%', 'Last 50%', 'Last 33%%'};

fprintf('MSD fits over different ranges:\n');
for i = 1:length(ranges)
    range = ranges{i};
    start_idx = max(1, round(range(1)));
    end_idx = min(length(t), round(range(2)));
    
    valid_range = valid_msd(start_idx:end_idx);
    t_range = t(start_idx:end_idx);
    msd_range = msd_lag_averaged(start_idx:end_idx);
    
    if sum(valid_range) >= 10
        log_t = log10(t_range(valid_range));
        log_msd = log10(msd_range(valid_range));
        fit_coeff = polyfit(log_t, log_msd, 1);
        r_squared = calculate_r_squared(log_msd, polyval(fit_coeff, log_t));
        fprintf('  %s: α = %.3f (R² = %.3f)\n', range_names{i}, fit_coeff(1), r_squared);
    else
        fprintf('  %s: insufficient data\n', range_names{i});
    end
end

% GSER analysis with different parameters
fprintf('\n=== GSER ANALYSIS OPTIMIZATION ===\n');

% Test different analysis parameters
window_sizes = [10, 20, 30, 50, 100];
analysis_methods = {'standard', 'robust', 'smooth'};

for method_idx = 1:length(analysis_methods)
    method = analysis_methods{method_idx};
    fprintf('\nMethod: %s\n', method);
    
    for window_idx = 1:length(window_sizes)
        window_size = window_sizes(window_idx);
        
        % Apply GSER with different parameters
        [gser_results, validation_metrics] = run_optimized_gser_analysis(t, msd_lag_averaged, p_val, method, window_size);
        
        if ~isempty(gser_results) && isfield(gser_results, 'omega')
            omega = gser_results.omega;
            G_prime = gser_results.G_prime;
            G_double_prime = gser_results.G_double_prime;
            alpha_omega = gser_results.alpha_omega;
            
            fprintf('  Window %d: %d points, α_G'' = %.3f, α_G'''' = %.3f, δ = %.1f°\n', ...
                window_size, length(omega), validation_metrics.alpha_Gp, validation_metrics.alpha_Gpp, validation_metrics.delta_measured);
            
            % Check for negative alpha
            if validation_metrics.alpha_Gpp < 0
                fprintf('    ⚠ WARNING: Negative α_G'''' detected!\n');
            end
            
            % Check consistency
            alpha_diff = abs(validation_metrics.alpha_Gp - validation_metrics.alpha_Gpp);
            if alpha_diff < 0.2
                fprintf('    ✓ GOOD: α_G'' and α_G'''' are consistent\n');
            else
                fprintf('    ⚠ POOR: α_G'' and α_G'''' differ significantly\n');
            end
        else
            fprintf('  Window %d: insufficient data\n', window_size);
        end
    end
end

% Create diagnostic plots
create_high_percolation_plots(t, msd_raw, msd_lag_averaged, trajectory_stats);

fprintf('\n=== DIAGNOSTIC COMPLETED ===\n');

% ============================================================================
% HELPER FUNCTIONS
% ============================================================================

function [gser_results, validation_metrics] = run_optimized_gser_analysis(t, msd, p_val, method, window_size)
% Optimized GSER analysis with different methods

% Physical parameters
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

% Calculate local exponent with different methods
alpha_local = calculate_optimized_alpha(tau_exp, msd_exp, method, window_size);

% Apply GSER
omega = 1 ./ tau_exp(2:end);
alpha_omega = alpha_local(2:end);

% Handle numerical issues with stricter filtering
valid_idx = isfinite(alpha_omega) & (msd_exp(2:end) > 0) & (alpha_omega > 0) & (alpha_omega < 2) & (alpha_omega > 0.01);
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
    validation_metrics = perform_optimized_validation(omega, G_prime, G_double_prime, alpha_omega, msd, t);
else
    gser_results = struct();
    validation_metrics = struct();
    validation_metrics.quality_rating = 'INSUFFICIENT_DATA';
end

end

function alpha_local = calculate_optimized_alpha(tau_exp, msd_exp, method, window_size)
% Calculate local exponent with different methods

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

switch method
    case 'standard'
        % Standard moving window
        alpha_smooth = zeros(size(log_tau));
        for i = 1:length(log_tau)
            start_idx = max(1, i - window_size);
            end_idx = min(length(log_tau), i + window_size);
            
            if end_idx - start_idx >= 2
                fit_coeff = polyfit(log_tau(start_idx:end_idx), log_msd(start_idx:end_idx), 1);
                alpha_smooth(i) = fit_coeff(1);
            else
                alpha_smooth(i) = 1;
            end
        end
        
    case 'robust'
        % Robust fitting with outlier removal
        alpha_smooth = zeros(size(log_tau));
        for i = 1:length(log_tau)
            start_idx = max(1, i - window_size);
            end_idx = min(length(log_tau), i + window_size);
            
            if end_idx - start_idx >= 5
                x = log_tau(start_idx:end_idx);
                y = log_msd(start_idx:end_idx);
                
                % Remove outliers
                residuals = abs(y - polyval(polyfit(x, y, 1), x));
                mad_residual = median(residuals);
                inliers = residuals < 3 * mad_residual;
                
                if sum(inliers) >= 3
                    fit_coeff = polyfit(x(inliers), y(inliers), 1);
                    alpha_smooth(i) = fit_coeff(1);
                else
                    alpha_smooth(i) = 1;
                end
            else
                alpha_smooth(i) = 1;
            end
        end
        
    case 'smooth'
        % Smoothing with Savitzky-Golay filter
        if length(log_tau) >= 2*window_size + 1
            % Use Savitzky-Golay smoothing
            alpha_smooth = sgolayfilt(gradient(log_msd) ./ gradient(log_tau), 2, min(2*window_size + 1, length(log_tau)));
        else
            % Fall back to standard method
            alpha_smooth = zeros(size(log_tau));
            for i = 1:length(log_tau)
                start_idx = max(1, i - window_size);
                end_idx = min(length(log_tau), i + window_size);
                
                if end_idx - start_idx >= 2
                    fit_coeff = polyfit(log_tau(start_idx:end_idx), log_msd(start_idx:end_idx), 1);
                    alpha_smooth(i) = fit_coeff(1);
                else
                    alpha_smooth(i) = 1;
                end
            end
        end
end

% Interpolate back to original grid
alpha_local = ones(size(tau_exp));
alpha_local(valid_idx) = alpha_smooth;

% Handle boundary effects
alpha_local(~valid_idx) = 1;

end

function validation_metrics = perform_optimized_validation(omega, G_prime, G_double_prime, alpha_omega, msd, t)
% Perform validation analysis with optimized parameters

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
    fit_Gp = polyfit(log_omega_range, log_Gp_range, 1);
    fit_Gpp = polyfit(log_omega_range, log_Gpp_range, 1);
    
    validation_metrics.alpha_Gp = fit_Gp(1);
    validation_metrics.alpha_Gpp = fit_Gpp(1);
    
    % MSD exponent for comparison
    mid_range = round(length(t)/3):round(2*length(t)/3);
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

function create_high_percolation_plots(t, msd_raw, msd_lag_averaged, trajectory_stats)
% Create diagnostic plots for high percolation analysis

figure('Position', [100, 100, 1200, 800]);

% Plot 1: MSD analysis
subplot(2, 3, 1);
loglog(t, msd_raw, 'b:', 'LineWidth', 1, 'DisplayName', 'Raw MSD');
hold on;
loglog(t, msd_lag_averaged, 'r-', 'LineWidth', 2, 'DisplayName', 'Lag-averaged MSD');
xlabel('Time (steps)');
ylabel('MSD');
title('MSD Analysis (p = 0.8)');
legend('Location', 'best');
grid on;

% Plot 2: MSD growth rate
subplot(2, 3, 2);
valid_msd = (t > 1) & (msd_lag_averaged > 0);
if sum(valid_msd) >= 10
    log_t = log10(t(valid_msd));
    log_msd = log10(msd_lag_averaged(valid_msd));
    
    % Calculate local derivative
    d_log_msd = gradient(log_msd) ./ gradient(log_t);
    semilogx(t(valid_msd), d_log_msd, 'b-', 'LineWidth', 2);
    yline(1, 'r--', 'LineWidth', 1, 'DisplayName', 'α = 1 (normal)');
    yline(0.5, 'g--', 'LineWidth', 1, 'DisplayName', 'α = 0.5 (subdiffusive)');
    xlabel('Time (steps)');
    ylabel('Local α');
    title('Local Growth Exponent');
    legend('Location', 'best');
    grid on;
end

% Plot 3: Trajectory statistics
subplot(2, 3, 3);
stats_data = [trajectory_stats.move_success_rate, trajectory_stats.eff_diffusion];
bar(stats_data);
set(gca, 'XTickLabel', {'Move Success Rate', 'Effective Diffusion'});
ylabel('Value');
title('Trajectory Statistics');
grid on;

% Plot 4: MSD vs time with fits
subplot(2, 3, 4);
loglog(t, msd_lag_averaged, 'b-', 'LineWidth', 2, 'DisplayName', 'MSD');
hold on;

% Add fits for different ranges
ranges = {[1, length(t)], [round(length(t)/4), round(3*length(t)/4)], [round(length(t)/2), length(t)]};
range_names = {'Full', 'Middle 50%', 'Last 50%'};
colors = {'r', 'g', 'm'};

for i = 1:length(ranges)
    range = ranges{i};
    start_idx = max(1, range(1));
    end_idx = min(length(t), range(2));
    
    valid_range = valid_msd(start_idx:end_idx);
    t_range = t(start_idx:end_idx);
    msd_range = msd_lag_averaged(start_idx:end_idx);
    
    if sum(valid_range) >= 10
        log_t = log10(t_range(valid_range));
        log_msd = log10(msd_range(valid_range));
        fit_coeff = polyfit(log_t, log_msd, 1);
        
        % Plot fit line
        t_fit = logspace(log10(min(t_range)), log10(max(t_range)), 100);
        msd_fit = 10.^polyval(fit_coeff, log10(t_fit));
        loglog(t_fit, msd_fit, '--', 'Color', colors{i}, 'LineWidth', 1, 'DisplayName', sprintf('%s: α=%.3f', range_names{i}, fit_coeff(1)));
    end
end

xlabel('Time (steps)');
ylabel('MSD');
title('MSD with Power Law Fits');
legend('Location', 'best');
grid on;

% Plot 5: MSD plateau analysis
subplot(2, 3, 5);
% Check if MSD plateaus
msd_normalized = msd_lag_averaged / max(msd_lag_averaged);
semilogx(t, msd_normalized, 'b-', 'LineWidth', 2);
xlabel('Time (steps)');
ylabel('Normalized MSD');
title('MSD Plateau Analysis');
grid on;
yline(0.9, 'r--', 'LineWidth', 1, 'DisplayName', '90% of max');

% Plot 6: Summary
subplot(2, 3, 6);
summary_data = [trajectory_stats.move_success_rate, trajectory_stats.eff_diffusion, min(msd_lag_averaged), max(msd_lag_averaged)];
summary_labels = {'Success Rate', 'Diffusion', 'Min MSD', 'Max MSD'};
bar(summary_data);
set(gca, 'XTickLabel', summary_labels);
ylabel('Value');
title('Summary Statistics');
grid on;

sgtitle('High Percolation (p = 0.8) Diagnostic Analysis');

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

% Include the standalone simulation functions
function [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_standalone_simulation(p_val, L, LW, NW, seed)
% Run simulation with both raw and lag-averaged MSD calculation

rng(seed + round(p_val*1000));

% Build percolation lattice
template = create_standalone_lattice(p_val, L);

% Initialize walkers
start_positions = initialize_standalone_walkers(template, L, NW);

% Run random walks
fprintf('  Running %d walkers for %d steps...\n', NW, LW);
tic;
[positions, trajectory_stats] = run_standalone_walks(template, LW, L, start_positions);
runtime = toc;
fprintf('  Simulation completed in %.2f seconds\n', runtime);

% Calculate both types of MSD
t = (1:LW)';

% Raw MSD (simple displacement from start)
fprintf('  Calculating raw MSD...\n');
msd_raw = calculate_standalone_raw_msd(positions);

% Lag-averaged MSD (following Moschakis 2013)
fprintf('  Calculating lag-averaged MSD...\n');
msd_lag_averaged = calculate_standalone_lag_msd(positions, LW, NW);

end

function template = create_standalone_lattice(p_val, L)
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

function start_positions = initialize_standalone_walkers(template, L, NW)
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

function [positions, trajectory_stats] = run_standalone_walks(template, LW, L, start_positions)
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

function msd_raw = calculate_standalone_raw_msd(positions)
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

function msd_lag_averaged = calculate_standalone_lag_msd(positions, LW, NW)
% Calculate lag-averaged MSD following Moschakis 2013 methodology

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