% analyze_critical_points.m
% Comprehensive analysis of critical percolation points
% p = 0.1, 0.3116, 0.6884, 0.8

clear; close all;

fprintf('=== CRITICAL PERCOLATION POINTS ANALYSIS ===\n');
fprintf('Analyzing MSD-G''-G''''-δ for all critical regimes\n\n');

% Critical p values
p_values = [0.1, 0.3116, 0.6884, 0.8];
p_labels = {'p = 0.1 (Below p_c)', 'p = 0.3116 (p_c)', 'p = 0.6884 (p_c'')', 'p = 0.8 (Above p_c'')'};
p_c = 0.3116;
p_c_prime = 0.6884;

% Parameters
L = 100;           % Lattice size
LW = 10000;        % Walk length
NW = 100;          % Number of walkers
seed = 42;

fprintf('Parameters: L=%d, LW=%d, NW=%d\n', L, LW, NW);
fprintf('Critical points: p_c = %.4f, p_c'' = %.4f\n\n', p_c, p_c_prime);

% Initialize results
results = struct();

for i = 1:length(p_values)
    p_val = p_values(i);
    fprintf('=== Analyzing %s ===\n', p_labels{i});
    
    % Run simulation
    [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_standalone_simulation(p_val, L, LW, NW, seed + i);
    
    % Apply GSER analysis
    [gser_results, validation_metrics] = run_standalone_gser_analysis(t, msd_lag_averaged, p_val);
    
    % Store results
    results(i).p = p_val;
    results(i).p_label = p_labels{i};
    results(i).t = t;
    results(i).msd_raw = msd_raw;
    results(i).msd_lag_averaged = msd_lag_averaged;
    results(i).gser_results = gser_results;
    results(i).validation_metrics = validation_metrics;
    results(i).trajectory_stats = trajectory_stats;
    
    % Report key findings
    fprintf('  Trajectory quality:\n');
    fprintf('    Move success rate: %.3f\n', trajectory_stats.move_success_rate);
    fprintf('    Effective diffusion: %.2e\n', trajectory_stats.eff_diffusion);
    
    if ~isempty(gser_results) && isfield(gser_results, 'omega')
        fprintf('  GSER analysis:\n');
        fprintf('    Frequency points: %d\n', length(gser_results.omega));
        fprintf('    Frequency range: %.2e to %.2e rad/s\n', min(gser_results.omega), max(gser_results.omega));
        
        if isfield(validation_metrics, 'alpha_msd')
            fprintf('    α_MSD = %.3f\n', validation_metrics.alpha_msd);
        end
        if isfield(validation_metrics, 'alpha_Gp')
            fprintf('    α_G'' = %.3f, α_G'''' = %.3f\n', validation_metrics.alpha_Gp, validation_metrics.alpha_Gpp);
        end
        if isfield(validation_metrics, 'delta_measured')
            fprintf('    δ = %.1f° (theory: %.1f°)\n', validation_metrics.delta_measured, validation_metrics.delta_theory);
        end
        if isfield(validation_metrics, 'ratio_mean')
            fprintf('    G''/G'''' = %.3f\n', validation_metrics.ratio_mean);
        end
        fprintf('    Quality: %s\n', validation_metrics.quality_rating);
    else
        fprintf('  ⚠ GSER analysis failed - insufficient data\n');
    end
    
    fprintf('\n');
end

% Create comprehensive analysis plots
create_critical_points_plots(results, p_c, p_c_prime);

% Generate analytical summary
generate_analytical_summary(results, p_c, p_c_prime);

fprintf('=== CRITICAL POINTS ANALYSIS COMPLETED ===\n');

% Save results
save('critical_points_results.mat', 'results', 'p_values', 'p_c', 'p_c_prime', 'L', 'LW', 'NW');
fprintf('Results saved to critical_points_results.mat\n');

% ============================================================================
% PLOTTING FUNCTION
% ============================================================================

function create_critical_points_plots(results, p_c, p_c_prime)
% Create comprehensive plots for critical points analysis

figure('Position', [50, 50, 1600, 1200]);

colors = {[0, 0.4470, 0.7410], [0.8500, 0.3250, 0.0980], [0.9290, 0.6940, 0.1250], [0.4940, 0.1840, 0.5560]};
line_styles = {'-', '--', ':', '-.'};

% Plot 1: MSD Comparison
subplot(3, 4, 1);
hold on;
for i = 1:length(results)
    loglog(results(i).t, results(i).msd_lag_averaged, line_styles{i}, 'Color', colors{i}, 'LineWidth', 2, 'DisplayName', results(i).p_label);
end
xlabel('Time (steps)');
ylabel('MSD');
title('MSD Comparison');
legend('Location', 'best');
grid on;

% Plot 2: G'(ω) Comparison
subplot(3, 4, 2);
hold on;
for i = 1:length(results)
    if ~isempty(results(i).gser_results) && isfield(results(i).gser_results, 'G_prime')
        omega = results(i).gser_results.omega;
        G_prime = results(i).gser_results.G_prime;
        loglog(omega, G_prime, line_styles{i}, 'Color', colors{i}, 'LineWidth', 2, 'DisplayName', results(i).p_label);
    end
end
xlabel('ω (rad/s)');
ylabel('G''(ω) (Pa)');
title('Storage Modulus G''(ω)');
legend('Location', 'best');
grid on;

% Plot 3: G''(ω) Comparison
subplot(3, 4, 3);
hold on;
for i = 1:length(results)
    if ~isempty(results(i).gser_results) && isfield(results(i).gser_results, 'G_double_prime')
        omega = results(i).gser_results.omega;
        G_double_prime = results(i).gser_results.G_double_prime;
        loglog(omega, G_double_prime, line_styles{i}, 'Color', colors{i}, 'LineWidth', 2, 'DisplayName', results(i).p_label);
    end
end
xlabel('ω (rad/s)');
ylabel('G''''(ω) (Pa)');
title('Loss Modulus G''''(ω)');
legend('Location', 'best');
grid on;

% Plot 4: Loss Tangent Comparison
subplot(3, 4, 4);
hold on;
for i = 1:length(results)
    if ~isempty(results(i).gser_results) && isfield(results(i).gser_results, 'G_prime')
        omega = results(i).gser_results.omega;
        G_prime = results(i).gser_results.G_prime;
        G_double_prime = results(i).gser_results.G_double_prime;
        delta = atan2(G_double_prime, G_prime) * 180 / pi;
        semilogx(omega, delta, line_styles{i}, 'Color', colors{i}, 'LineWidth', 2, 'DisplayName', results(i).p_label);
    end
end
xlabel('ω (rad/s)');
ylabel('δ (degrees)');
title('Loss Tangent δ(ω)');
legend('Location', 'best');
grid on;

% Plot 5: G'/G'' Ratio Comparison
subplot(3, 4, 5);
hold on;
for i = 1:length(results)
    if ~isempty(results(i).gser_results) && isfield(results(i).gser_results, 'G_prime')
        omega = results(i).gser_results.omega;
        G_prime = results(i).gser_results.G_prime;
        G_double_prime = results(i).gser_results.G_double_prime;
        ratio = G_prime ./ G_double_prime;
        semilogx(omega, ratio, line_styles{i}, 'Color', colors{i}, 'LineWidth', 2, 'DisplayName', results(i).p_label);
    end
end
xlabel('ω (rad/s)');
ylabel('G''(ω)/G''''(ω)');
title('G''/G'''' Ratio');
legend('Location', 'best');
grid on;

% Plot 6: Cole-Cole Plot
subplot(3, 4, 6);
hold on;
for i = 1:length(results)
    if ~isempty(results(i).gser_results) && isfield(results(i).gser_results, 'G_prime')
        G_prime = results(i).gser_results.G_prime;
        G_double_prime = results(i).gser_results.G_double_prime;
        plot(G_prime, G_double_prime, line_styles{i}, 'Color', colors{i}, 'LineWidth', 2, 'DisplayName', results(i).p_label);
    end
end
xlabel('G''(ω) (Pa)');
ylabel('G''''(ω) (Pa)');
title('Cole-Cole Plot');
legend('Location', 'best');
grid on;

% Plot 7: α Evolution with p
subplot(3, 4, 7);
p_vals = [results.p];
alpha_msd = zeros(size(p_vals));
alpha_gp = zeros(size(p_vals));
alpha_gpp = zeros(size(p_vals));

for i = 1:length(results)
    if isfield(results(i), 'validation_metrics')
        if isfield(results(i).validation_metrics, 'alpha_msd')
            alpha_msd(i) = results(i).validation_metrics.alpha_msd;
        end
        if isfield(results(i).validation_metrics, 'alpha_Gp')
            alpha_gp(i) = results(i).validation_metrics.alpha_Gp;
        end
        if isfield(results(i).validation_metrics, 'alpha_Gpp')
            alpha_gpp(i) = results(i).validation_metrics.alpha_Gpp;
        end
    end
end

plot(p_vals, alpha_msd, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'α_MSD');
hold on;
plot(p_vals, alpha_gp, 's-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'α_G''');
plot(p_vals, alpha_gpp, '^-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'α_G''''');
xline(p_c, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xline(p_c_prime, '--k', 'LineWidth', 2, 'DisplayName', 'p_c''');
xlabel('p');
ylabel('Power Law Exponent α');
title('α Evolution with p');
legend('Location', 'best');
grid on;

% Plot 8: δ Evolution with p
subplot(3, 4, 8);
delta_measured = zeros(size(p_vals));
delta_theory = zeros(size(p_vals));

for i = 1:length(results)
    if isfield(results(i), 'validation_metrics')
        if isfield(results(i).validation_metrics, 'delta_measured')
            delta_measured(i) = results(i).validation_metrics.delta_measured;
        end
        if isfield(results(i).validation_metrics, 'delta_theory')
            delta_theory(i) = results(i).validation_metrics.delta_theory;
        end
    end
end

plot(p_vals, delta_measured, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'δ_measured');
hold on;
plot(p_vals, delta_theory, 's--', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'δ_theory');
xline(p_c, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xline(p_c_prime, '--k', 'LineWidth', 2, 'DisplayName', 'p_c''');
xlabel('p');
ylabel('Loss Tangent δ (degrees)');
title('δ Evolution with p');
legend('Location', 'best');
grid on;

% Plot 9: G'/G'' Ratio Evolution
subplot(3, 4, 9);
ratio_mean = zeros(size(p_vals));

for i = 1:length(results)
    if isfield(results(i), 'validation_metrics') && isfield(results(i).validation_metrics, 'ratio_mean')
        ratio_mean(i) = results(i).validation_metrics.ratio_mean;
    end
end

plot(p_vals, ratio_mean, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'G''/G''''');
xline(p_c, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xline(p_c_prime, '--k', 'LineWidth', 2, 'DisplayName', 'p_c''');
xlabel('p');
ylabel('G''/G'''' Ratio');
title('G''/G'''' Evolution with p');
legend('Location', 'best');
grid on;

% Plot 10: Move Success Rate
subplot(3, 4, 10);
success_rates = zeros(size(p_vals));
for i = 1:length(results)
    success_rates(i) = results(i).trajectory_stats.move_success_rate;
end

plot(p_vals, success_rates, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Success Rate');
xline(p_c, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xline(p_c_prime, '--k', 'LineWidth', 2, 'DisplayName', 'p_c''');
xlabel('p');
ylabel('Move Success Rate');
title('Trajectory Success Rate');
legend('Location', 'best');
grid on;

% Plot 11: Effective Diffusion
subplot(3, 4, 11);
eff_diffusion = zeros(size(p_vals));
for i = 1:length(results)
    eff_diffusion(i) = results(i).trajectory_stats.eff_diffusion;
end

semilogy(p_vals, eff_diffusion, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Effective D');
xline(p_c, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xline(p_c_prime, '--k', 'LineWidth', 2, 'DisplayName', 'p_c''');
xlabel('p');
ylabel('Effective Diffusion');
title('Effective Diffusion Coefficient');
legend('Location', 'best');
grid on;

% Plot 12: Quality Assessment
subplot(3, 4, 12);
quality_scores = zeros(size(p_vals));
for i = 1:length(results)
    if isfield(results(i), 'validation_metrics') && isfield(results(i).validation_metrics, 'quality_rating')
        switch results(i).validation_metrics.quality_rating
            case 'EXCELLENT'
                quality_scores(i) = 4;
            case 'GOOD'
                quality_scores(i) = 3;
            case 'ACCEPTABLE'
                quality_scores(i) = 2;
            case 'POOR'
                quality_scores(i) = 1;
            otherwise
                quality_scores(i) = 0;
        end
    end
end

bar(p_vals, quality_scores);
xlabel('p');
ylabel('Quality Score');
title('Analysis Quality Assessment');
set(gca, 'YTick', [0, 1, 2, 3, 4]);
set(gca, 'YTickLabel', {'None', 'Poor', 'Acceptable', 'Good', 'Excellent'});
grid on;

sgtitle('Critical Percolation Points Analysis: MSD-G''-G''''-δ');

end

function generate_analytical_summary(results, p_c, p_c_prime)
% Generate analytical summary of results

fprintf('\n=== ANALYTICAL SUMMARY ===\n');
fprintf('Critical Points Analysis Results\n\n');

% Create summary table
fprintf('%-15s %-8s %-8s %-8s %-8s %-8s %-8s %-8s\n', 'p', 'α_MSD', 'α_G''', 'α_G''''', 'δ(°)', 'G''/G''''', 'Success', 'Quality');
fprintf('%-15s %-8s %-8s %-8s %-8s %-8s %-8s %-8s\n', '---', '-----', '-----', '------', '----', '-------', '------', '------');

for i = 1:length(results)
    p_val = results(i).p;
    p_label = results(i).p_label;
    
    % Extract values
    alpha_msd = NaN;
    alpha_gp = NaN;
    alpha_gpp = NaN;
    delta = NaN;
    ratio = NaN;
    success_rate = results(i).trajectory_stats.move_success_rate;
    quality = 'N/A';
    
    if isfield(results(i), 'validation_metrics')
        vm = results(i).validation_metrics;
        if isfield(vm, 'alpha_msd'), alpha_msd = vm.alpha_msd; end
        if isfield(vm, 'alpha_Gp'), alpha_gp = vm.alpha_Gp; end
        if isfield(vm, 'alpha_Gpp'), alpha_gpp = vm.alpha_Gpp; end
        if isfield(vm, 'delta_measured'), delta = vm.delta_measured; end
        if isfield(vm, 'ratio_mean'), ratio = vm.ratio_mean; end
        if isfield(vm, 'quality_rating'), quality = vm.quality_rating; end
    end
    
    fprintf('%-15s %-8.3f %-8.3f %-8.3f %-8.1f %-8.3f %-8.3f %-8s\n', ...
        sprintf('%.4f', p_val), alpha_msd, alpha_gp, alpha_gpp, delta, ratio, success_rate, quality);
end

fprintf('\n=== KEY INSIGHTS ===\n');

% Analyze trends
fprintf('1. Percolation Regimes:\n');
fprintf('   • p = 0.1 (below p_c): Free diffusion regime\n');
fprintf('   • p = 0.3116 (p_c): Critical percolation threshold\n');
fprintf('   • p = 0.6884 (p_c''): Apparent gel point\n');
fprintf('   • p = 0.8 (above p_c''): High percolation regime\n\n');

fprintf('2. Expected Trends:\n');
fprintf('   • α should decrease with increasing p\n');
fprintf('   • δ should decrease with increasing p\n');
fprintf('   • G''/G'''' should increase with increasing p\n');
fprintf('   • Success rate should decrease with increasing p\n\n');

fprintf('3. Analytical Relationships:\n');
fprintf('   • α_MSD ≈ α_G'' ≈ α_G'''' (consistency check)\n');
fprintf('   • δ = πα/2 (theoretical relationship)\n');
fprintf('   • G''/G'''' = cot(πα/2) (theoretical relationship)\n\n');

fprintf('4. Quality Assessment:\n');
for i = 1:length(results)
    if isfield(results(i), 'validation_metrics') && isfield(results(i).validation_metrics, 'quality_rating')
        fprintf('   • %s: %s\n', results(i).p_label, results(i).validation_metrics.quality_rating);
    end
end

end

% ============================================================================
% HELPER FUNCTIONS (copied from standalone_validation_test.m)
% ============================================================================

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

function [gser_results, validation_metrics] = run_standalone_gser_analysis(t, msd, p_val)
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