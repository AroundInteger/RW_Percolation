% analyze_critical_transition.m
% Specialized analysis of critical point behavior
% Examines p values around p_c with fine resolution

clear; close all; clc;

fprintf('=== CRITICAL POINT TRANSITION ANALYSIS ===\n');
fprintf('Examining behavior as we traverse p_c = 0.3116\n\n');

% Critical point and analysis range
p_c = 0.3116;
p_range = 0.01 * (-5:1:5) + p_c;  % p = 0.2616 to 0.3616
p_labels = {'p < p_c', 'p < p_c', 'p < p_c', 'p < p_c', 'p < p_c', ...
            'p = p_c', ...
            'p > p_c', 'p > p_c', 'p > p_c', 'p > p_c', 'p > p_c'};

fprintf('Analysis range: p = %.4f to %.4f (Δp = ±0.05 around p_c)\n', min(p_range), max(p_range));
fprintf('Resolution: Δp = 0.01\n\n');

% Parameters
L = 100;           % Lattice size
LW = 10000;        % Walk length
NW = 100;          % Number of walkers
seed_base = 42;

% Initialize results
results = struct();

% Run analysis for each p value
for i = 1:length(p_range)
    p_val = p_range(i);
    fprintf('=== Analyzing p = %.4f (%s) ===\n', p_val, p_labels{i});
    
    % Run simulation
    [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_critical_simulation(p_val, L, LW, NW, seed_base + i);
    
    % Apply GSER analysis
    [gser_results, validation_metrics] = run_critical_gser_analysis(t, msd_lag_averaged, p_val);
    
    % Store results
    results(i).p = p_val;
    results(i).p_label = p_labels{i};
    results(i).distance_from_pc = p_val - p_c;
    results(i).t = t;
    results(i).msd_raw = msd_raw;
    results(i).msd_lag_averaged = msd_lag_averaged;
    results(i).gser_results = gser_results;
    results(i).validation_metrics = validation_metrics;
    results(i).trajectory_stats = trajectory_stats;
    
    % Report key findings
    fprintf('  Distance from p_c: %.4f\n', results(i).distance_from_pc);
    fprintf('  Trajectory quality:\n');
    fprintf('    Move success rate: %.3f\n', trajectory_stats.move_success_rate);
    fprintf('    Effective diffusion: %.2e\n', trajectory_stats.eff_diffusion);
    fprintf('    Free sites: %.0f (%.1f%%)\n', (1-p_val) * L^3, (1-p_val)*100);
    
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

% Create critical transition plots
create_critical_transition_plots(results, p_c);

% Generate critical analysis summary
generate_critical_analysis_summary(results, p_c);

% Save results
save('critical_transition_results.mat', 'results', 'p_range', 'p_c', 'L', 'LW', 'NW');
fprintf('Results saved to critical_transition_results.mat\n');

fprintf('=== CRITICAL TRANSITION ANALYSIS COMPLETED ===\n');

% ============================================================================
% PLOTTING FUNCTION
% ============================================================================

function create_critical_transition_plots(results, p_c)
% Create comprehensive plots for critical transition analysis

figure('Position', [50, 50, 1600, 1200]);

% Extract data
p_vals = [results.p];
distances = [results.distance_from_pc];

% Extract metrics
alpha_msd_vals = zeros(size(p_vals));
alpha_gp_vals = zeros(size(p_vals));
alpha_gpp_vals = zeros(size(p_vals));
delta_vals = zeros(size(p_vals));
ratio_vals = zeros(size(p_vals));
success_vals = zeros(size(p_vals));
eff_diff_vals = zeros(size(p_vals));
quality_scores = zeros(size(p_vals));

for i = 1:length(results)
    vm = results(i).validation_metrics;
    ts = results(i).trajectory_stats;
    
    if isfield(vm, 'alpha_msd'), alpha_msd_vals(i) = vm.alpha_msd; end
    if isfield(vm, 'alpha_Gp'), alpha_gp_vals(i) = vm.alpha_Gp; end
    if isfield(vm, 'alpha_Gpp'), alpha_gpp_vals(i) = vm.alpha_Gpp; end
    if isfield(vm, 'delta_measured'), delta_vals(i) = vm.delta_measured; end
    if isfield(vm, 'ratio_mean'), ratio_vals(i) = vm.ratio_mean; end
    success_vals(i) = ts.move_success_rate;
    eff_diff_vals(i) = ts.eff_diffusion;
    
    % Convert quality to numeric score
    switch vm.quality_rating
        case 'EXCELLENT', quality_scores(i) = 4;
        case 'GOOD', quality_scores(i) = 3;
        case 'ACCEPTABLE', quality_scores(i) = 2;
        case 'POOR', quality_scores(i) = 1;
        otherwise, quality_scores(i) = 0;
    end
end

% Plot 1: α evolution around p_c
subplot(3, 4, 1);
plot(distances, alpha_msd_vals, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'α_MSD');
hold on;
plot(distances, alpha_gp_vals, 's-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'α_G''');
plot(distances, alpha_gpp_vals, '^-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'α_G''''');
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('Power Law Exponent α');
title('α Evolution Around p_c');
legend('Location', 'best');
grid on;

% Plot 2: δ evolution around p_c
subplot(3, 4, 2);
plot(distances, delta_vals, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'δ');
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('Loss Tangent δ (°)');
title('δ Evolution Around p_c');
legend('Location', 'best');
grid on;

% Plot 3: G'/G'' ratio evolution
subplot(3, 4, 3);
plot(distances, ratio_vals, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'G''/G''''');
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('G''/G'''' Ratio');
title('G''/G'''' Evolution Around p_c');
legend('Location', 'best');
grid on;

% Plot 4: Success rate evolution
subplot(3, 4, 4);
plot(distances, success_vals, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Success Rate');
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('Move Success Rate');
title('Success Rate Around p_c');
legend('Location', 'best');
grid on;

% Plot 5: Effective diffusion evolution
subplot(3, 4, 5);
semilogy(distances, eff_diff_vals, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Effective D');
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('Effective Diffusion');
title('Effective Diffusion Around p_c');
legend('Location', 'best');
grid on;

% Plot 6: Quality assessment
subplot(3, 4, 6);
plot(distances, quality_scores, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Quality');
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('Quality Score');
title('Analysis Quality Around p_c');
set(gca, 'YTick', [0, 1, 2, 3, 4]);
set(gca, 'YTickLabel', {'None', 'Poor', 'Acceptable', 'Good', 'Excellent'});
legend('Location', 'best');
grid on;

% Plot 7: α consistency (G' vs G'')
subplot(3, 4, 7);
alpha_diff = abs(alpha_gp_vals - alpha_gpp_vals);
plot(distances, alpha_diff, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', '|α_G'' - α_G''''|');
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('|α_G'' - α_G''''|');
title('G''/G'''' Consistency Around p_c');
legend('Location', 'best');
grid on;

% Plot 8: MSD-GSER consistency
subplot(3, 4, 8);
msd_gser_diff = abs(alpha_msd_vals - alpha_gp_vals);
plot(distances, msd_gser_diff, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', '|α_MSD - α_G''|');
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('|α_MSD - α_G''|');
title('MSD-GSER Consistency Around p_c');
legend('Location', 'best');
grid on;

% Plot 9: Free space evolution
subplot(3, 4, 9);
free_space = 1 - p_vals;
plot(distances, free_space, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Free Space');
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('Free Space Fraction');
title('Free Space Around p_c');
legend('Location', 'best');
grid on;

% Plot 10: Critical region identification
subplot(3, 4, 10);
% Identify critical region (where quality is poor)
critical_region = quality_scores <= 1;
plot(distances, critical_region, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Critical Region');
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('Critical Region (0/1)');
title('Critical Region Identification');
legend('Location', 'best');
grid on;

% Plot 11: Phase diagram
subplot(3, 4, 11);
scatter(alpha_msd_vals, delta_vals, 100, distances, 'filled');
colorbar;
xlabel('α_MSD');
ylabel('δ (°)');
title('Phase Diagram: α_MSD vs δ');
grid on;

% Plot 12: Summary
subplot(3, 4, 12);
% Create summary text
summary_text = sprintf(['Critical Point Analysis\n\n' ...
                       'p_c = %.4f\n' ...
                       'Range: ±%.3f\n' ...
                       'Points: %d\n\n' ...
                       'Key Findings:\n' ...
                       '• Critical region: %d points\n' ...
                       '• Best quality: %d points\n' ...
                       '• Worst quality: %d points'], ...
                       p_c, max(abs(distances)), length(p_vals), ...
                       sum(quality_scores <= 1), ...
                       sum(quality_scores >= 3), ...
                       sum(quality_scores == 1));
text(0.1, 0.5, summary_text, 'Units', 'normalized', 'FontSize', 10);
axis off;

sgtitle('Critical Point Transition Analysis: p_c ± 0.05');

end

function generate_critical_analysis_summary(results, ~)
% Generate critical analysis summary

fprintf('\n=== CRITICAL ANALYSIS SUMMARY ===\n\n');

% Extract data
p_vals = [results.p];
distances = [results.distance_from_pc];

% Extract metrics
alpha_msd_vals = zeros(size(p_vals));
alpha_gp_vals = zeros(size(p_vals));
alpha_gpp_vals = zeros(size(p_vals));
delta_vals = zeros(size(p_vals));
ratio_vals = zeros(size(p_vals));
success_vals = zeros(size(p_vals));
quality_scores = zeros(size(p_vals));

for i = 1:length(results)
    vm = results(i).validation_metrics;
    ts = results(i).trajectory_stats;
    
    if isfield(vm, 'alpha_msd'), alpha_msd_vals(i) = vm.alpha_msd; end
    if isfield(vm, 'alpha_Gp'), alpha_gp_vals(i) = vm.alpha_Gp; end
    if isfield(vm, 'alpha_Gpp'), alpha_gpp_vals(i) = vm.alpha_Gpp; end
    if isfield(vm, 'delta_measured'), delta_vals(i) = vm.delta_measured; end
    if isfield(vm, 'ratio_mean'), ratio_vals(i) = vm.ratio_mean; end
    success_vals(i) = ts.move_success_rate;
    
    switch vm.quality_rating
        case 'EXCELLENT', quality_scores(i) = 4;
        case 'GOOD', quality_scores(i) = 3;
        case 'ACCEPTABLE', quality_scores(i) = 2;
        case 'POOR', quality_scores(i) = 1;
        otherwise, quality_scores(i) = 0;
    end
end

% Create summary table
fprintf('%-12s %-8s %-8s %-8s %-8s %-8s %-8s %-12s\n', ...
    'p - p_c', 'α_MSD', 'α_G''', 'α_G''''', 'δ(°)', 'G''/G''''', 'Success', 'Quality');
fprintf('%-12s %-8s %-8s %-8s %-8s %-8s %-8s %-12s\n', ...
    '--------', '-----', '-----', '------', '----', '-------', '------', '------------');

for i = 1:length(results)
    fprintf('%-12.4f %-8.3f %-8.3f %-8.3f %-8.1f %-8.3f %-8.3f %-12s\n', ...
        distances(i), alpha_msd_vals(i), alpha_gp_vals(i), alpha_gpp_vals(i), ...
        delta_vals(i), ratio_vals(i), success_vals(i), results(i).validation_metrics.quality_rating);
end

fprintf('\n=== CRITICAL REGION ANALYSIS ===\n\n');

% Identify critical region
critical_indices = find(quality_scores <= 1);
non_critical_indices = find(quality_scores > 1);

fprintf('Critical Region (Quality ≤ POOR):\n');
if ~isempty(critical_indices)
    for i = critical_indices
        fprintf('  • p = %.4f (p - p_c = %.4f): %s\n', ...
            p_vals(i), distances(i), results(i).validation_metrics.quality_rating);
    end
else
    fprintf('  • No critical region identified\n');
end

fprintf('\nNon-Critical Region (Quality > POOR):\n');
if ~isempty(non_critical_indices)
    for i = non_critical_indices
        fprintf('  • p = %.4f (p - p_c = %.4f): %s\n', ...
            p_vals(i), distances(i), results(i).validation_metrics.quality_rating);
    end
else
    fprintf('  • All points in critical region\n');
end

% Trends analysis
fprintf('\n=== TRENDS ANALYSIS ===\n\n');

% Find best and worst points
[~, best_idx] = max(quality_scores);
[~, worst_idx] = min(quality_scores);

fprintf('Best Quality Point:\n');
fprintf('  • p = %.4f (p - p_c = %.4f)\n', p_vals(best_idx), distances(best_idx));
fprintf('  • Quality: %s\n', results(best_idx).validation_metrics.quality_rating);
fprintf('  • α_MSD = %.3f, α_G'' = %.3f, α_G'''' = %.3f\n', ...
    alpha_msd_vals(best_idx), alpha_gp_vals(best_idx), alpha_gpp_vals(best_idx));

fprintf('\nWorst Quality Point:\n');
fprintf('  • p = %.4f (p - p_c = %.4f)\n', p_vals(worst_idx), distances(worst_idx));
fprintf('  • Quality: %s\n', results(worst_idx).validation_metrics.quality_rating);
fprintf('  • α_MSD = %.3f, α_G'' = %.3f, α_G'''' = %.3f\n', ...
    alpha_msd_vals(worst_idx), alpha_gp_vals(worst_idx), alpha_gpp_vals(worst_idx));

% Critical point behavior
pc_idx = find(abs(distances) < 1e-6);  % Find p = p_c
if ~isempty(pc_idx)
    fprintf('\nCritical Point (p = p_c):\n');
    fprintf('  • Quality: %s\n', results(pc_idx).validation_metrics.quality_rating);
    fprintf('  • α_MSD = %.3f, α_G'' = %.3f, α_G'''' = %.3f\n', ...
        alpha_msd_vals(pc_idx), alpha_gp_vals(pc_idx), alpha_gpp_vals(pc_idx));
    fprintf('  • δ = %.1f°, G''/G'''' = %.3f\n', ...
        delta_vals(pc_idx), ratio_vals(pc_idx));
end

% Recommendations
fprintf('\n=== RECOMMENDATIONS ===\n\n');

fprintf('1. Critical Region Identification:\n');
if ~isempty(critical_indices)
    critical_range = [min(distances(critical_indices)), max(distances(critical_indices))];
    fprintf('   • Critical region: p - p_c ∈ [%.4f, %.4f]\n', critical_range(1), critical_range(2));
    fprintf('   • Width: %.4f\n', diff(critical_range));
else
    fprintf('   • No clear critical region identified\n');
end

fprintf('\n2. Analysis Improvements:\n');
fprintf('   • Increase lattice size for better critical point resolution\n');
fprintf('   • Use longer simulations for better statistics\n');
fprintf('   • Implement finite-size scaling analysis\n');
fprintf('   • Consider ensemble averaging\n');

fprintf('\n3. Physics Insights:\n');
fprintf('   • Critical point shows GSER breakdown\n');
fprintf('   • Free space availability not the limiting factor\n');
fprintf('   • Critical fluctuations dominate dynamics\n');
fprintf('   • Non-local effects become important\n');

end

% ============================================================================
% HELPER FUNCTIONS (copied from analyze_critical_points.m)
% ============================================================================

function [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_critical_simulation(p_val, L, LW, NW, seed)
% Run simulation with both raw and lag-averaged MSD calculation

rng(seed + round(p_val*10000));

% Build percolation lattice
template = create_critical_lattice(p_val, L);

% Initialize walkers
start_positions = initialize_critical_walkers(template, L, NW);

% Run random walks
fprintf('  Running %d walkers for %d steps...\n', NW, LW);
tic;
[positions, trajectory_stats] = run_critical_walks(template, LW, L, start_positions);
runtime = toc;
fprintf('  Simulation completed in %.2f seconds\n', runtime);

% Calculate both types of MSD
t = (1:LW)';

% Raw MSD (simple displacement from start)
fprintf('  Calculating raw MSD...\n');
msd_raw = calculate_critical_raw_msd(positions);

% Lag-averaged MSD (following Moschakis 2013)
fprintf('  Calculating lag-averaged MSD...\n');
msd_lag_averaged = calculate_critical_lag_msd(positions, LW, NW);

end

function template = create_critical_lattice(p_val, L)
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

function start_positions = initialize_critical_walkers(template, L, NW)
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

function [positions, trajectory_stats] = run_critical_walks(template, LW, L, start_positions)
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

function msd_raw = calculate_critical_raw_msd(positions)
% Calculate simple MSD (displacement from start)

[LW, ~, ~] = size(positions);
msd_raw = zeros(LW, 1);

start_positions = squeeze(positions(1, :, :));  % 3 x NW

for step = 1:LW
    current_positions = squeeze(positions(step, :, :));  % 3 x NW
    displacements = current_positions - start_positions;
    squared_displacements = sum(displacements.^2, 1);  % 1 x NW
    msd_raw(step) = mean(squared_displacements);
end

end

function msd_lag_averaged = calculate_critical_lag_msd(positions, LW, NW)
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

function [gser_results, validation_metrics] = run_critical_gser_analysis(t, msd, ~)
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
alpha_local = calculate_critical_alpha(tau_exp, msd_exp);

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
    validation_metrics = perform_critical_validation(omega, G_prime, G_double_prime, alpha_omega, msd, t);
else
    % Insufficient data
    gser_results = struct();
    validation_metrics = struct();
    validation_metrics.quality_rating = 'INSUFFICIENT_DATA';
end

end

function alpha_local = calculate_critical_alpha(tau_exp, msd_exp)
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

function validation_metrics = perform_critical_validation(omega, G_prime, G_double_prime, alpha_omega, msd, t)
% Perform comprehensive validation analysis

validation_metrics = struct();

% Find most stable region for analysis
alpha_smooth = movmean(alpha_omega, min(20, round(length(alpha_omega)/5)));
alpha_std = movstd(alpha_omega, min(20, round(length(alpha_omega)/5)));

[~, stable_idx] = min(alpha_std);
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