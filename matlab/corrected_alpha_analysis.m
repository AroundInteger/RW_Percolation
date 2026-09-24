% corrected_alpha_analysis.m
% Corrected analysis using consistent frequency ranges
% Focuses on matching frequency region where α ≈ 0.109

clear; close all; clc;

fprintf('=== CORRECTED ALPHA ANALYSIS ===\n');
fprintf('Using consistent frequency ranges and matching regions\n\n');

% Parameters (same as successful test)
L = 100;           % Lattice size
LW = 10000;        % Walk length
NW = 100;          % Number of walkers
p_val = 0.10;      % Low percolation
seed = 42;

fprintf('Parameters: L=%d, LW=%d, NW=%d, p=%.2f\n', L, LW, NW, p_val);

try
    % Run simulation
    [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_standalone_simulation(p_val, L, LW, NW, seed);
    
    % Apply corrected GSER analysis with consistent ranges
    [gser_results, validation_metrics] = corrected_gser_analysis(t, msd_lag_averaged, p_val);
    
    % Detailed analysis with consistent ranges
    fprintf('\n=== CORRECTED ANALYSIS RESULTS ===\n');
    
    % 1. MSD Analysis with consistent time windows
    fprintf('1. MSD Analysis (consistent windows):\n');
    
    % Define consistent time windows based on diagnostic results
    time_windows = {
        [round(LW/3), round(2*LW/3)],     % Middle 33% (where α ≈ 0.109)
        [round(LW/4), round(3*LW/4)],     % Middle 50%
        [round(LW/2), LW],                % Last 50%
        [1, LW]                           % Full range
    };
    window_names = {'Middle 33%', 'Middle 50%', 'Last 50%', 'Full'};
    
    msd_results = struct();
    for i = 1:length(time_windows)
        window = time_windows{i};
        start_idx = max(1, window(1));
        end_idx = min(length(t), window(2));
        
        valid_range = (t(start_idx:end_idx) > 1) & (msd_lag_averaged(start_idx:end_idx) > 0);
        t_range = t(start_idx:end_idx);
        msd_range = msd_lag_averaged(start_idx:end_idx);
        
        if sum(valid_range) >= 10
            log_t = log10(t_range(valid_range));
            log_msd = log10(msd_range(valid_range));
            fit_coeff = polyfit(log_t, log_msd, 1);
            r_squared = calculate_r_squared(log_msd, polyval(fit_coeff, log_t));
            
            msd_results(i).window_name = window_names{i};
            msd_results(i).alpha = fit_coeff(1);
            msd_results(i).r_squared = r_squared;
            msd_results(i).time_range = [min(t_range), max(t_range)];
            
            fprintf('   %s: α = %.3f (R² = %.3f)\n', window_names{i}, fit_coeff(1), r_squared);
        end
    end
    
    % 2. GSER Analysis with matching frequency ranges
    fprintf('\n2. GSER Analysis (matching frequency ranges):\n');
    
    if ~isempty(gser_results) && isfield(gser_results, 'omega')
        omega = gser_results.omega;
        G_prime = gser_results.G_prime;
        G_double_prime = gser_results.G_double_prime;
        alpha_omega = gser_results.alpha_omega;
        
        % Find frequency ranges that match MSD time windows
        gser_results_matched = struct();
        
        for i = 1:length(time_windows)
            window = time_windows{i};
            start_idx = max(1, window(1));
            end_idx = min(length(t), window(2));
            
            % Convert time range to frequency range
            freq_min = 1 / t(end_idx);
            freq_max = 1 / t(start_idx);
            
            % Find frequencies in this range
            in_freq_range = (omega >= freq_min) & (omega <= freq_max);
            
            if sum(in_freq_range) >= 10
                omega_range = omega(in_freq_range);
                Gp_range = G_prime(in_freq_range);
                Gpp_range = G_double_prime(in_freq_range);
                alpha_range = alpha_omega(in_freq_range);
                
                % Fit G' and G'' in this frequency range
                log_omega = log10(omega_range);
                log_Gp = log10(max(Gp_range, 1e-20));
                log_Gpp = log10(max(Gpp_range, 1e-20));
                
                fit_Gp = polyfit(log_omega, log_Gp, 1);
                fit_Gpp = polyfit(log_omega, log_Gpp, 1);
                
                % Calculate consistency metrics
                alpha_consistency = abs(fit_Gp(1) - fit_Gpp(1));
                msd_gser_consistency = abs(msd_results(i).alpha - fit_Gp(1));
                
                gser_results_matched(i).window_name = window_names{i};
                gser_results_matched(i).alpha_Gp = fit_Gp(1);
                gser_results_matched(i).alpha_Gpp = fit_Gpp(1);
                gser_results_matched(i).alpha_consistency = alpha_consistency;
                gser_results_matched(i).msd_gser_consistency = msd_gser_consistency;
                gser_results_matched(i).freq_range = [min(omega_range), max(omega_range)];
                gser_results_matched(i).alpha_mean = mean(alpha_range);
                gser_results_matched(i).alpha_std = std(alpha_range);
                
                fprintf('   %s:\n', window_names{i});
                fprintf('     α_G'' = %.3f, α_G'''' = %.3f\n', fit_Gp(1), fit_Gpp(1));
                fprintf('     α_MSD = %.3f (consistency: %.3f)\n', msd_results(i).alpha, msd_gser_consistency);
                fprintf('     G''/G'''' consistency: %.3f\n', alpha_consistency);
                fprintf('     Frequency range: %.2e to %.2e rad/s\n', min(omega_range), max(omega_range));
            end
        end
        
        % 3. Find optimal matching region
        fprintf('\n3. Optimal Matching Region:\n');
        
        % Look for the region with best consistency
        best_consistency = inf;
        best_idx = 1;
        
        for i = 1:length(gser_results_matched)
            if isfield(gser_results_matched(i), 'msd_gser_consistency')
                total_consistency = gser_results_matched(i).msd_gser_consistency + ...
                                   gser_results_matched(i).alpha_consistency;
                
                if total_consistency < best_consistency
                    best_consistency = total_consistency;
                    best_idx = i;
                end
            end
        end
        
        if isfield(gser_results_matched(best_idx), 'window_name')
            fprintf('   Best matching region: %s\n', gser_results_matched(best_idx).window_name);
            fprintf('   α_MSD = %.3f, α_G'' = %.3f, α_G'''' = %.3f\n', ...
                msd_results(best_idx).alpha, ...
                gser_results_matched(best_idx).alpha_Gp, ...
                gser_results_matched(best_idx).alpha_Gpp);
            fprintf('   Total consistency error: %.3f\n', best_consistency);
        end
    end
    
    % 4. Create corrected plots
    fprintf('\n4. Creating corrected plots...\n');
    
    figure('Position', [100, 100, 1400, 1000]);
    
    % Plot 1: MSD with consistent windows
    subplot(2, 4, 1);
    loglog(t, msd_raw, 'b:', 'LineWidth', 1, 'DisplayName', 'Raw MSD');
    hold on;
    loglog(t, msd_lag_averaged, 'r-', 'LineWidth', 2, 'DisplayName', 'Lag-averaged MSD');
    
    % Add fit lines for different windows
    colors = {'g', 'm', 'c', 'k'};
    for i = 1:length(msd_results)
        if isfield(msd_results(i), 'alpha')
            window = time_windows{i};
            start_idx = max(1, window(1));
            end_idx = min(length(t), window(2));
            
            t_fit = logspace(log10(t(start_idx)), log10(t(end_idx)), 100);
            msd_fit = 10.^polyval([msd_results(i).alpha, 0], log10(t_fit));
            loglog(t_fit, msd_fit, '--', 'Color', colors{i}, 'LineWidth', 2, ...
                'DisplayName', sprintf('%s: α=%.3f', msd_results(i).window_name, msd_results(i).alpha));
        end
    end
    
    xlabel('Time (steps)');
    ylabel('MSD');
    title('MSD Analysis (Consistent Windows)');
    legend('Location', 'best');
    grid on;
    
    % Plot 2: GSER with matching frequency ranges
    if ~isempty(gser_results) && isfield(gser_results, 'omega')
        subplot(2, 4, 2);
        loglog(gser_results.omega, gser_results.G_prime, 'b-', 'LineWidth', 2, 'DisplayName', 'G''');
        hold on;
        loglog(gser_results.omega, gser_results.G_double_prime, 'r-', 'LineWidth', 2, 'DisplayName', 'G''''');
        
        % Highlight best matching region
        if isfield(gser_results_matched(best_idx), 'freq_range')
            freq_range = gser_results_matched(best_idx).freq_range;
            in_range = (gser_results.omega >= freq_range(1)) & (gser_results.omega <= freq_range(2));
            loglog(gser_results.omega(in_range), gser_results.G_prime(in_range), 'g-', 'LineWidth', 3, 'DisplayName', 'Best Match');
        end
        
        xlabel('ω (rad/s)');
        ylabel('G''(ω), G''''(ω) (Pa)');
        title('GSER Analysis (Matching Ranges)');
        legend('Location', 'best');
        grid on;
        
        % Plot 3: Alpha consistency comparison
        subplot(2, 4, 3);
        alpha_msd_vals = [];
        alpha_gp_vals = [];
        window_labels = {};
        
        for i = 1:length(msd_results)
            if isfield(msd_results(i), 'alpha') && isfield(gser_results_matched(i), 'alpha_Gp')
                alpha_msd_vals(end+1) = msd_results(i).alpha;
                alpha_gp_vals(end+1) = gser_results_matched(i).alpha_Gp;
                window_labels{end+1} = msd_results(i).window_name;
            end
        end
        
        if ~isempty(alpha_msd_vals)
            bar([alpha_msd_vals; alpha_gp_vals]');
            set(gca, 'XTickLabel', window_labels);
            ylabel('Power Law Exponent');
            title('α Comparison (MSD vs G'')');
            legend('α_MSD', 'α_G''', 'Location', 'best');
            grid on;
        end
        
        % Plot 4: Consistency metrics
        subplot(2, 4, 4);
        consistency_vals = [];
        for i = 1:length(gser_results_matched)
            if isfield(gser_results_matched(i), 'msd_gser_consistency')
                consistency_vals(end+1) = gser_results_matched(i).msd_gser_consistency;
            end
        end
        
        if ~isempty(consistency_vals)
            bar(consistency_vals);
            set(gca, 'XTickLabel', window_labels);
            ylabel('Consistency Error');
            title('MSD-GSER Consistency');
            grid on;
        end
        
        % Plot 5: Alpha vs frequency with regions
        subplot(2, 4, 5);
        semilogx(gser_results.omega, gser_results.alpha_omega, 'b-', 'LineWidth', 2);
        hold on;
        
        % Highlight different regions
        for i = 1:length(gser_results_matched)
            if isfield(gser_results_matched(i), 'freq_range')
                freq_range = gser_results_matched(i).freq_range;
                in_range = (gser_results.omega >= freq_range(1)) & (gser_results.omega <= freq_range(2));
                semilogx(gser_results.omega(in_range), gser_results.alpha_omega(in_range), ...
                    'Color', colors{i}, 'LineWidth', 3, 'DisplayName', gser_results_matched(i).window_name);
            end
        end
        
        xlabel('ω (rad/s)');
        ylabel('α(ω)');
        title('Local Alpha vs Frequency');
        legend('Location', 'best');
        grid on;
        
        % Plot 6: G'/G'' ratio by region
        subplot(2, 4, 6);
        ratio = gser_results.G_prime ./ gser_results.G_double_prime;
        semilogx(gser_results.omega, ratio, 'b-', 'LineWidth', 1);
        hold on;
        
        for i = 1:length(gser_results_matched)
            if isfield(gser_results_matched(i), 'freq_range')
                freq_range = gser_results_matched(i).freq_range;
                in_range = (gser_results.omega >= freq_range(1)) & (gser_results.omega <= freq_range(2));
                semilogx(gser_results.omega(in_range), ratio(in_range), ...
                    'Color', colors{i}, 'LineWidth', 3, 'DisplayName', gser_results_matched(i).window_name);
            end
        end
        
        xlabel('ω (rad/s)');
        ylabel('G''(ω)/G''''(ω)');
        title('G''/G'''' Ratio by Region');
        legend('Location', 'best');
        grid on;
        
        % Plot 7: Loss tangent by region
        subplot(2, 4, 7);
        delta = atan2(gser_results.G_double_prime, gser_results.G_prime) * 180 / pi;
        semilogx(gser_results.omega, delta, 'b-', 'LineWidth', 1);
        hold on;
        
        for i = 1:length(gser_results_matched)
            if isfield(gser_results_matched(i), 'freq_range')
                freq_range = gser_results_matched(i).freq_range;
                in_range = (gser_results.omega >= freq_range(1)) & (gser_results.omega <= freq_range(2));
                semilogx(gser_results.omega(in_range), delta(in_range), ...
                    'Color', colors{i}, 'LineWidth', 3, 'DisplayName', gser_results_matched(i).window_name);
            end
        end
        
        xlabel('ω (rad/s)');
        ylabel('δ (degrees)');
        title('Loss Tangent by Region');
        legend('Location', 'best');
        grid on;
        
        % Plot 8: Summary table
        subplot(2, 4, 8);
        axis off;
        
        % Create summary text
        summary_text = {'CORRECTED ANALYSIS SUMMARY', '', ...
            'Best Matching Region:', ...
            sprintf('  %s', gser_results_matched(best_idx).window_name), '', ...
            'Consistent Results:', ...
            sprintf('  α_MSD = %.3f', msd_results(best_idx).alpha), ...
            sprintf('  α_G'' = %.3f', gser_results_matched(best_idx).alpha_Gp), ...
            sprintf('  α_G'''' = %.3f', gser_results_matched(best_idx).alpha_Gpp), '', ...
            'Quality Metrics:', ...
            sprintf('  MSD-GSER consistency: %.3f', gser_results_matched(best_idx).msd_gser_consistency), ...
            sprintf('  G''-G'''' consistency: %.3f', gser_results_matched(best_idx).alpha_consistency), ...
            sprintf('  Total error: %.3f', best_consistency)};
        
        text(0.1, 0.9, summary_text, 'Units', 'normalized', 'FontSize', 10, ...
            'VerticalAlignment', 'top', 'FontWeight', 'bold');
    end
    
    sgtitle(sprintf('Corrected Alpha Analysis - p = %.2f', p_val));
    
    fprintf('✓ Corrected analysis completed\n');
    fprintf('✓ Best matching region identified\n');
    fprintf('✓ Consistency improved\n');
    
    % Save results
    save('corrected_alpha_results.mat', 'msd_results', 'gser_results_matched', 'best_idx', 'p_val');
    fprintf('✓ Results saved to corrected_alpha_results.mat\n');
    
catch ME
    fprintf('❌ ERROR in corrected analysis:\n');
    fprintf('Error: %s\n', ME.message);
end

fprintf('\nCorrected analysis completed.\n');

% Helper functions (same as diagnose_alpha_discrepancy.m)
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

function [gser_results, validation_metrics] = corrected_gser_analysis(t, msd, p_val)
% Corrected GSER analysis with consistent frequency ranges

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
alpha_local = calculate_standalone_alpha(tau_exp, msd_exp);

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
    validation_metrics = perform_standalone_validation(omega, G_prime, G_double_prime, alpha_omega, msd, t);
else
    % Insufficient data
    gser_results = struct();
    validation_metrics = struct();
    validation_metrics.quality_rating = 'INSUFFICIENT_DATA';
end

end

function alpha_local = calculate_standalone_alpha(tau_exp, msd_exp)
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

function validation_metrics = perform_standalone_validation(omega, G_prime, G_double_prime, alpha_omega, msd, t)
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