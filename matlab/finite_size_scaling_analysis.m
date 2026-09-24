% finite_size_scaling_analysis.m
% Finite-size scaling analysis for critical percolation behavior
% Examines how critical point behavior depends on system size

clear; close all; clc;

fprintf('=== FINITE-SIZE SCALING ANALYSIS ===\n');
fprintf('Examining critical behavior dependence on system size\n\n');

% Critical point and analysis parameters
p_c = 0.3116;  % 3D percolation threshold
p_c_prime = 0.6884;  % Apparent gel point

% System sizes to test (must be powers of 2 for efficiency)
L_values = [50, 100, 150, 200];  % Different system sizes
fprintf('System sizes: L = [%s]\n', num2str(L_values));

% p values around critical point (fine resolution)
p_range = 0.01 * (-3:1:3) + p_c;  % p = 0.2816 to 0.3416
fprintf('p range: %.4f to %.4f (Δp = ±0.03 around p_c)\n', min(p_range), max(p_range));

% Simulation parameters
LW = 10000;        % Walk length
NW = 100;          % Number of walkers
seed_base = 42;

% Initialize results structure
finite_size_results = struct();

% Run analysis for each system size
for l_idx = 1:length(L_values)
    L = L_values(l_idx);
    fprintf('\n=== ANALYZING L = %d ===\n', L);
    
    % Initialize results for this system size
    finite_size_results(l_idx).L = L;
    finite_size_results(l_idx).p_values = p_range;
    finite_size_results(l_idx).results = struct();
    
    % Run analysis for each p value
    for p_idx = 1:length(p_range)
        p_val = p_range(p_idx);
        fprintf('  Analyzing p = %.4f (p - p_c = %.4f)...\n', p_val, p_val - p_c);
        
        % Run simulation
        [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_finite_size_simulation(p_val, L, LW, NW, seed_base + l_idx*1000 + p_idx);
        
        % Apply GSER analysis
        [gser_results, validation_metrics] = run_finite_size_gser_analysis(t, msd_lag_averaged, p_val);
        
        % Store results
        finite_size_results(l_idx).results(p_idx).p = p_val;
        finite_size_results(l_idx).results(p_idx).distance_from_pc = p_val - p_c;
        finite_size_results(l_idx).results(p_idx).t = t;
        finite_size_results(l_idx).results(p_idx).msd_raw = msd_raw;
        finite_size_results(l_idx).results(p_idx).msd_lag_averaged = msd_lag_averaged;
        finite_size_results(l_idx).results(p_idx).gser_results = gser_results;
        finite_size_results(l_idx).results(p_idx).validation_metrics = validation_metrics;
        finite_size_results(l_idx).results(p_idx).trajectory_stats = trajectory_stats;
        
        % Report key findings
        if ~isempty(gser_results) && isfield(gser_results, 'omega')
            fprintf('    α_MSD = %.3f, α_G'' = %.3f, α_G'''' = %.3f, Quality: %s\n', ...
                validation_metrics.alpha_msd, validation_metrics.alpha_Gp, validation_metrics.alpha_Gpp, validation_metrics.quality_rating);
        else
            fprintf('    GSER analysis failed\n');
        end
    end
end

% Create finite-size scaling plots
create_finite_size_plots(finite_size_results, p_c);

% Generate finite-size scaling analysis
generate_finite_size_analysis(finite_size_results, p_c);

% Save results
save('finite_size_scaling_results.mat', 'finite_size_results', 'p_range', 'p_c', 'L_values', 'LW', 'NW');
fprintf('\nResults saved to finite_size_scaling_results.mat\n');

fprintf('\n=== FINITE-SIZE SCALING ANALYSIS COMPLETED ===\n');

% ============================================================================
% PLOTTING FUNCTION
% ============================================================================

function create_finite_size_plots(finite_size_results, p_c)
% Create comprehensive finite-size scaling plots

figure('Position', [50, 50, 1600, 1200]);

colors = {[0, 0.4470, 0.7410], [0.8500, 0.3250, 0.0980], [0.9290, 0.6940, 0.1250], [0.4940, 0.1840, 0.5560]};
markers = {'o', 's', '^', 'd'};

% Extract data for plotting
L_values = [finite_size_results.L];
p_values = finite_size_results(1).p_values;
distances = p_values - p_c;

% Plot 1: α_MSD vs p - p_c for different L
subplot(3, 4, 1);
hold on;
for l_idx = 1:length(L_values)
    alpha_msd_vals = zeros(size(p_values));
    for p_idx = 1:length(p_values)
        if isfield(finite_size_results(l_idx).results(p_idx), 'validation_metrics')
            vm = finite_size_results(l_idx).results(p_idx).validation_metrics;
            if isfield(vm, 'alpha_msd')
                alpha_msd_vals(p_idx) = vm.alpha_msd;
            end
        end
    end
    plot(distances, alpha_msd_vals, [markers{l_idx}, '-'], 'Color', colors{l_idx}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', sprintf('L = %d', L_values(l_idx)));
end
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('α_MSD');
title('α_MSD vs p - p_c (Finite-Size Scaling)');
legend('Location', 'best');
grid on;

% Plot 2: α_G' vs p - p_c for different L
subplot(3, 4, 2);
hold on;
for l_idx = 1:length(L_values)
    alpha_gp_vals = zeros(size(p_values));
    for p_idx = 1:length(p_values)
        if isfield(finite_size_results(l_idx).results(p_idx), 'validation_metrics')
            vm = finite_size_results(l_idx).results(p_idx).validation_metrics;
            if isfield(vm, 'alpha_Gp')
                alpha_gp_vals(p_idx) = vm.alpha_Gp;
            end
        end
    end
    plot(distances, alpha_gp_vals, [markers{l_idx}, '-'], 'Color', colors{l_idx}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', sprintf('L = %d', L_values(l_idx)));
end
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('α_G''');
title('α_G'' vs p - p_c (Finite-Size Scaling)');
legend('Location', 'best');
grid on;

% Plot 3: α_G'' vs p - p_c for different L
subplot(3, 4, 3);
hold on;
for l_idx = 1:length(L_values)
    alpha_gpp_vals = zeros(size(p_values));
    for p_idx = 1:length(p_values)
        if isfield(finite_size_results(l_idx).results(p_idx), 'validation_metrics')
            vm = finite_size_results(l_idx).results(p_idx).validation_metrics;
            if isfield(vm, 'alpha_Gpp')
                alpha_gpp_vals(p_idx) = vm.alpha_Gpp;
            end
        end
    end
    plot(distances, alpha_gpp_vals, [markers{l_idx}, '-'], 'Color', colors{l_idx}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', sprintf('L = %d', L_values(l_idx)));
end
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('α_G''''');
title('α_G'''' vs p - p_c (Finite-Size Scaling)');
legend('Location', 'best');
grid on;

% Plot 4: Quality assessment vs p - p_c for different L
subplot(3, 4, 4);
hold on;
for l_idx = 1:length(L_values)
    quality_scores = zeros(size(p_values));
    for p_idx = 1:length(p_values)
        if isfield(finite_size_results(l_idx).results(p_idx), 'validation_metrics')
            vm = finite_size_results(l_idx).results(p_idx).validation_metrics;
            switch vm.quality_rating
                case 'EXCELLENT', quality_scores(p_idx) = 4;
                case 'GOOD', quality_scores(p_idx) = 3;
                case 'ACCEPTABLE', quality_scores(p_idx) = 2;
                case 'POOR', quality_scores(p_idx) = 1;
                otherwise, quality_scores(p_idx) = 0;
            end
        end
    end
    plot(distances, quality_scores, [markers{l_idx}, '-'], 'Color', colors{l_idx}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', sprintf('L = %d', L_values(l_idx)));
end
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('Quality Score');
title('Quality vs p - p_c (Finite-Size Scaling)');
set(gca, 'YTick', [0, 1, 2, 3, 4]);
set(gca, 'YTickLabel', {'None', 'Poor', 'Acceptable', 'Good', 'Excellent'});
legend('Location', 'best');
grid on;

% Plot 5: G'/G'' ratio vs p - p_c for different L
subplot(3, 4, 5);
hold on;
for l_idx = 1:length(L_values)
    ratio_vals = zeros(size(p_values));
    for p_idx = 1:length(p_values)
        if isfield(finite_size_results(l_idx).results(p_idx), 'validation_metrics')
            vm = finite_size_results(l_idx).results(p_idx).validation_metrics;
            if isfield(vm, 'ratio_mean')
                ratio_vals(p_idx) = vm.ratio_mean;
            end
        end
    end
    plot(distances, ratio_vals, [markers{l_idx}, '-'], 'Color', colors{l_idx}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', sprintf('L = %d', L_values(l_idx)));
end
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('G''/G'''' Ratio');
title('G''/G'''' vs p - p_c (Finite-Size Scaling)');
legend('Location', 'best');
grid on;

% Plot 6: Loss tangent δ vs p - p_c for different L
subplot(3, 4, 6);
hold on;
for l_idx = 1:length(L_values)
    delta_vals = zeros(size(p_values));
    for p_idx = 1:length(p_values)
        if isfield(finite_size_results(l_idx).results(p_idx), 'validation_metrics')
            vm = finite_size_results(l_idx).results(p_idx).validation_metrics;
            if isfield(vm, 'delta_measured')
                delta_vals(p_idx) = vm.delta_measured;
            end
        end
    end
    plot(distances, delta_vals, [markers{l_idx}, '-'], 'Color', colors{l_idx}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', sprintf('L = %d', L_values(l_idx)));
end
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('δ (°)');
title('δ vs p - p_c (Finite-Size Scaling)');
legend('Location', 'best');
grid on;

% Plot 7: Success rate vs p - p_c for different L
subplot(3, 4, 7);
hold on;
for l_idx = 1:length(L_values)
    success_vals = zeros(size(p_values));
    for p_idx = 1:length(p_values)
        ts = finite_size_results(l_idx).results(p_idx).trajectory_stats;
        success_vals(p_idx) = ts.move_success_rate;
    end
    plot(distances, success_vals, [markers{l_idx}, '-'], 'Color', colors{l_idx}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', sprintf('L = %d', L_values(l_idx)));
end
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('Success Rate');
title('Success Rate vs p - p_c (Finite-Size Scaling)');
legend('Location', 'best');
grid on;

% Plot 8: Effective diffusion vs p - p_c for different L
subplot(3, 4, 8);
hold on;
for l_idx = 1:length(L_values)
    eff_diff_vals = zeros(size(p_values));
    for p_idx = 1:length(p_values)
        ts = finite_size_results(l_idx).results(p_idx).trajectory_stats;
        eff_diff_vals(p_idx) = ts.eff_diffusion;
    end
    semilogy(distances, eff_diff_vals, [markers{l_idx}, '-'], 'Color', colors{l_idx}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', sprintf('L = %d', L_values(l_idx)));
end
xline(0, '--k', 'LineWidth', 2, 'DisplayName', 'p_c');
xlabel('p - p_c');
ylabel('Effective Diffusion');
title('Effective Diffusion vs p - p_c (Finite-Size Scaling)');
legend('Location', 'best');
grid on;

% Plot 9: Critical region width vs system size
subplot(3, 4, 9);
critical_widths = zeros(size(L_values));
for l_idx = 1:length(L_values)
    % Find critical region (quality <= POOR)
    critical_indices = [];
    for p_idx = 1:length(p_values)
        if isfield(finite_size_results(l_idx).results(p_idx), 'validation_metrics')
            vm = finite_size_results(l_idx).results(p_idx).validation_metrics;
            if strcmp(vm.quality_rating, 'POOR')
                critical_indices = [critical_indices, p_idx];
            end
        end
    end
    
    if ~isempty(critical_indices)
        critical_distances = distances(critical_indices);
        critical_widths(l_idx) = max(critical_distances) - min(critical_distances);
    else
        critical_widths(l_idx) = 0;
    end
end

plot(L_values, critical_widths, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('System Size L');
ylabel('Critical Region Width');
title('Critical Region Width vs System Size');
grid on;

% Plot 10: Quality at p_c vs system size
subplot(3, 4, 10);
pc_quality_scores = zeros(size(L_values));
for l_idx = 1:length(L_values)
    % Find p = p_c (distance = 0)
    pc_idx = find(abs(distances) < 1e-6);
    if ~isempty(pc_idx)
        vm = finite_size_results(l_idx).results(pc_idx).validation_metrics;
        switch vm.quality_rating
            case 'EXCELLENT', pc_quality_scores(l_idx) = 4;
            case 'GOOD', pc_quality_scores(l_idx) = 3;
            case 'ACCEPTABLE', pc_quality_scores(l_idx) = 2;
            case 'POOR', pc_quality_scores(l_idx) = 1;
            otherwise, pc_quality_scores(l_idx) = 0;
        end
    end
end

plot(L_values, pc_quality_scores, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('System Size L');
ylabel('Quality at p_c');
title('Quality at p_c vs System Size');
set(gca, 'YTick', [0, 1, 2, 3, 4]);
set(gca, 'YTickLabel', {'None', 'Poor', 'Acceptable', 'Good', 'Excellent'});
grid on;

% Plot 11: α_MSD at p_c vs system size
subplot(3, 4, 11);
pc_alpha_msd = zeros(size(L_values));
for l_idx = 1:length(L_values)
    pc_idx = find(abs(distances) < 1e-6);
    if ~isempty(pc_idx)
        vm = finite_size_results(l_idx).results(pc_idx).validation_metrics;
        if isfield(vm, 'alpha_msd')
            pc_alpha_msd(l_idx) = vm.alpha_msd;
        end
    end
end

plot(L_values, pc_alpha_msd, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('System Size L');
ylabel('α_MSD at p_c');
title('α_MSD at p_c vs System Size');
grid on;

% Plot 12: Summary
subplot(3, 4, 12);
summary_text = sprintf(['Finite-Size Scaling\n\n' ...
                       'System Sizes: %s\n' ...
                       'p Range: ±%.3f\n' ...
                       'Critical Point: %.4f\n\n' ...
                       'Key Questions:\n' ...
                       '• Does critical region\n  shrink with L?\n' ...
                       '• Does quality improve\n  with L?\n' ...
                       '• Do exponents converge\n  to infinite size?'], ...
                       num2str(L_values), max(abs(distances)), p_c);
text(0.1, 0.5, summary_text, 'Units', 'normalized', 'FontSize', 10);
axis off;

sgtitle('Finite-Size Scaling Analysis: Critical Percolation Behavior');

end

function generate_finite_size_analysis(finite_size_results, p_c)
% Generate finite-size scaling analysis

fprintf('\n=== FINITE-SIZE SCALING ANALYSIS ===\n\n');

L_values = [finite_size_results.L];
p_values = finite_size_results(1).p_values;
distances = p_values - p_c;

% Extract data for analysis
alpha_msd_data = zeros(length(L_values), length(p_values));
alpha_gp_data = zeros(length(L_values), length(p_values));
alpha_gpp_data = zeros(length(L_values), length(p_values));
quality_data = zeros(length(L_values), length(p_values));
success_data = zeros(length(L_values), length(p_values));

for l_idx = 1:length(L_values)
    for p_idx = 1:length(p_values)
        vm = finite_size_results(l_idx).results(p_idx).validation_metrics;
        ts = finite_size_results(l_idx).results(p_idx).trajectory_stats;
        
        if isfield(vm, 'alpha_msd'), alpha_msd_data(l_idx, p_idx) = vm.alpha_msd; end
        if isfield(vm, 'alpha_Gp'), alpha_gp_data(l_idx, p_idx) = vm.alpha_Gp; end
        if isfield(vm, 'alpha_Gpp'), alpha_gpp_data(l_idx, p_idx) = vm.alpha_Gpp; end
        success_data(l_idx, p_idx) = ts.move_success_rate;
        
        switch vm.quality_rating
            case 'EXCELLENT', quality_data(l_idx, p_idx) = 4;
            case 'GOOD', quality_data(l_idx, p_idx) = 3;
            case 'ACCEPTABLE', quality_data(l_idx, p_idx) = 2;
            case 'POOR', quality_data(l_idx, p_idx) = 1;
            otherwise, quality_data(l_idx, p_idx) = 0;
        end
    end
end

% Analysis 1: Critical region width scaling
fprintf('1. Critical Region Width Scaling:\n');
critical_widths = zeros(size(L_values));
for l_idx = 1:length(L_values)
    critical_indices = find(quality_data(l_idx, :) <= 1);
    if ~isempty(critical_indices)
        critical_distances = distances(critical_indices);
        critical_widths(l_idx) = max(critical_distances) - min(critical_distances);
        fprintf('   L = %d: Critical width = %.4f\n', L_values(l_idx), critical_widths(l_idx));
    else
        fprintf('   L = %d: No critical region identified\n', L_values(l_idx));
    end
end

% Analysis 2: Quality at p_c scaling
fprintf('\n2. Quality at p_c Scaling:\n');
pc_idx = find(abs(distances) < 1e-6);
if ~isempty(pc_idx)
    for l_idx = 1:length(L_values)
        quality_score = quality_data(l_idx, pc_idx);
        switch quality_score
            case 4, quality_str = 'EXCELLENT';
            case 3, quality_str = 'GOOD';
            case 2, quality_str = 'ACCEPTABLE';
            case 1, quality_str = 'POOR';
            otherwise, quality_str = 'NONE';
        end
        fprintf('   L = %d: Quality = %s\n', L_values(l_idx), quality_str);
    end
end

% Analysis 3: Exponent convergence
fprintf('\n3. Exponent Convergence at p_c:\n');
if ~isempty(pc_idx)
    fprintf('   α_MSD: ');
    for l_idx = 1:length(L_values)
        fprintf('%.3f ', alpha_msd_data(l_idx, pc_idx));
    end
    fprintf('\n');
    
    fprintf('   α_G'': ');
    for l_idx = 1:length(L_values)
        fprintf('%.3f ', alpha_gp_data(l_idx, pc_idx));
    end
    fprintf('\n');
    
    fprintf('   α_G'''': ');
    for l_idx = 1:length(L_values)
        fprintf('%.3f ', alpha_gpp_data(l_idx, pc_idx));
    end
    fprintf('\n');
end

% Analysis 4: Success rate scaling
fprintf('\n4. Success Rate at p_c:\n');
if ~isempty(pc_idx)
    for l_idx = 1:length(L_values)
        fprintf('   L = %d: %.3f\n', L_values(l_idx), success_data(l_idx, pc_idx));
    end
end

% Analysis 5: Finite-size scaling predictions
fprintf('\n5. Finite-Size Scaling Predictions:\n');
fprintf('   • Critical region width should scale as L^(-1/ν)\n');
fprintf('   • Quality should improve with increasing L\n');
fprintf('   • Exponents should converge to infinite-size values\n');
fprintf('   • Success rate should be independent of L\n');

% Analysis 6: Recommendations
fprintf('\n6. Recommendations:\n');
fprintf('   • Use L ≥ 200 for reliable critical point analysis\n');
fprintf('   • Implement ensemble averaging across multiple realizations\n');
fprintf('   • Consider finite-size scaling corrections\n');
fprintf('   • Extrapolate to infinite system size\n');

end

% ============================================================================
% HELPER FUNCTIONS (copied from analyze_critical_transition.m)
% ============================================================================

function [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_finite_size_simulation(p_val, L, LW, NW, seed)
% Run simulation with both raw and lag-averaged MSD calculation

rng(seed + round(p_val*10000));

% Build percolation lattice
template = create_finite_size_lattice(p_val, L);

% Initialize walkers
start_positions = initialize_finite_size_walkers(template, L, NW);

% Run random walks
[positions, trajectory_stats] = run_finite_size_walks(template, LW, L, start_positions);

% Calculate both types of MSD
t = (1:LW)';

% Raw MSD (simple displacement from start)
msd_raw = calculate_finite_size_raw_msd(positions);

% Lag-averaged MSD (following Moschakis 2013)
msd_lag_averaged = calculate_finite_size_lag_msd(positions, LW, NW);

end

function template = create_finite_size_lattice(p_val, L)
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

end

function start_positions = initialize_finite_size_walkers(template, L, NW)
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

function [positions, trajectory_stats] = run_finite_size_walks(template, LW, L, start_positions)
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

function msd_raw = calculate_finite_size_raw_msd(positions)
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

function msd_lag_averaged = calculate_finite_size_lag_msd(positions, LW, NW)
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

function [gser_results, validation_metrics] = run_finite_size_gser_analysis(t, msd, p_val)
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
alpha_local = calculate_finite_size_alpha(tau_exp, msd_exp);

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
    validation_metrics = perform_finite_size_validation(omega, G_prime, G_double_prime, alpha_omega, msd, t);
else
    % Insufficient data
    gser_results = struct();
    validation_metrics = struct();
    validation_metrics.quality_rating = 'INSUFFICIENT_DATA';
end

end

function alpha_local = calculate_finite_size_alpha(tau_exp, msd_exp)
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

function validation_metrics = perform_finite_size_validation(omega, G_prime, G_double_prime, alpha_omega, msd, t)
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