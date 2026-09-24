function simple_msd_test()
% Simple test to validate MSD calculation and lag-time averaging
% This is a streamlined version to avoid complex dependencies

close all; clc;

fprintf('=== Simple MSD Validation Test ===\n\n');

% Test parameters
L = 100;            % Small lattice for quick testing
LW = 10000;         % Short walks
NW = 200;           % Few walkers
p_values = [0.1, 0.5];  % Just two test cases
seed = 42;

results = struct();

for i = 1:length(p_values)
    p_val = p_values(i);
    fprintf('Testing p = %.1f\n', p_val);
    
    % Run simple simulation
    [t, msd_raw, msd_avg, sim_info] = run_simple_simulation(p_val, L, LW, NW, seed);
    
    % Analyze results
    analysis = analyze_simple_results(t, msd_raw, msd_avg, p_val);
    
    % Store results
    results(i).p = p_val;
    results(i).t = t;
    results(i).msd_raw = msd_raw;
    results(i).msd_avg = msd_avg;
    results(i).sim_info = sim_info;
    results(i).analysis = analysis;
    
    % Report findings
    fprintf('  MSD quality improvement: %.1fx noise reduction\n', analysis.noise_reduction);
    fprintf('  Power law exponent: %.3f\n', analysis.alpha);
    fprintf('  GSER analysis: %s\n', analysis.gser_status);
    fprintf('\n');
end

% Create simple plots
create_simple_plots(results);

fprintf('=== Simple Test Complete ===\n');
fprintf('Check the plots to verify:\n');
fprintf('1. Lag-averaged MSD is smoother than raw MSD\n');
fprintf('2. Power law regions are clearly identifiable\n');
fprintf('3. G'' and G'''' follow expected scaling\n\n');

end

function [t, msd_raw, msd_avg, sim_info] = run_simple_simulation(p_val, L, LW, NW, seed)
% Simple simulation without complex dependencies

rng(seed + round(p_val*100));

% Create simple percolation lattice
L3 = L^3;
occupied = false(L, L, L);
if p_val > 0
    n_occupied = round(p_val * L3);
    occupied_indices = randsample(L3, n_occupied);
    occupied(occupied_indices) = true;
end

% Find free sites
free_sites = find(~occupied);
n_free = length(free_sites);

if n_free < NW
    error('Not enough free sites: need %d, have %d', NW, n_free);
end

% Initialize walkers
walker_indices = randsample(n_free, NW);
[start_x, start_y, start_z] = ind2sub([L, L, L], free_sites(walker_indices));

% Run walks
fprintf('  Running %d walkers for %d steps... ', NW, LW);
tic;

% Store all positions
positions = zeros(LW, 3, NW);
for walker = 1:NW
    positions(:, :, walker) = simple_walk(occupied, [start_x(walker), start_y(walker), start_z(walker)], LW, L);
end

runtime = toc;
fprintf('done (%.2f sec)\n', runtime);

% Calculate MSDs
t = (1:LW)';

% Raw MSD (displacement from start)
fprintf('  Calculating raw MSD... ');
msd_raw = zeros(LW, 1);
for step = 1:LW
    displacements = squeeze(positions(step, :, :)) - squeeze(positions(1, :, :));
    msd_raw(step) = mean(sum(displacements.^2, 1));
end
fprintf('done\n');

% Lag-averaged MSD
fprintf('  Calculating lag-averaged MSD... ');
msd_avg = calculate_lag_averaged_msd_simple(positions, LW, NW);
fprintf('done\n');

% Simulation info
sim_info.runtime = runtime;
sim_info.n_free_sites = n_free;
sim_info.occupation_fraction = sum(occupied(:)) / L3;

end

function trajectory = simple_walk(occupied, start_pos, LW, L)
% Simple 3D random walk

trajectory = zeros(LW, 3);
current_pos = start_pos;
trajectory(1, :) = current_pos;

% Neighbor directions
directions = [1,0,0; -1,0,0; 0,1,0; 0,-1,0; 0,0,1; 0,0,-1];

for step = 2:LW
    % Try to move
    direction = directions(randi(6), :);
    new_pos = current_pos + direction;
    
    % Periodic boundaries
    new_pos = mod(new_pos - 1, L) + 1;
    
    % Check if free
    if ~occupied(new_pos(1), new_pos(2), new_pos(3))
        current_pos = new_pos;
    end
    
    trajectory(step, :) = current_pos;
end

end

function msd_avg = calculate_lag_averaged_msd_simple(positions, LW, NW)
% Simple lag-averaged MSD calculation

max_pairs = min(500, LW-1);  % Limit for speed
msd_avg = zeros(LW, 1);

for tau = 1:LW
    all_sq_displacements = [];
    
    for walker = 1:NW
        % How many pairs can we get for this tau?
        n_pairs = min(max_pairs, LW - tau);
        
        for pair = 1:n_pairs
            t_start = pair;
            t_end = t_start + tau;
            
            if t_end <= LW
                displacement = positions(t_end, :, walker) - positions(t_start, :, walker);
                all_sq_displacements(end+1) = sum(displacement.^2);
            end
        end
    end
    
    if ~isempty(all_sq_displacements)
        msd_avg(tau) = mean(all_sq_displacements);
    end
end

end

function analysis = analyze_simple_results(t, msd_raw, msd_avg, p_val)
% Simple analysis of results

analysis = struct();

% Compare noise levels
% Calculate derivative variability as noise metric
if length(t) > 20
    valid_range = 10:(length(t)-10);
    
    log_t = log10(t(valid_range));
    log_msd_raw = log10(max(msd_raw(valid_range), 1e-10));
    log_msd_avg = log10(max(msd_avg(valid_range), 1e-10));
    
    % Calculate derivatives
    deriv_raw = gradient(log_msd_raw) ./ gradient(log_t);
    deriv_avg = gradient(log_msd_avg) ./ gradient(log_t);
    
    % Noise metrics
    noise_raw = std(deriv_raw);
    noise_avg = std(deriv_avg);
    
    analysis.noise_reduction = noise_raw / max(noise_avg, 1e-6);
    
    % Extract power law exponent from middle section
    mid_range = round(length(log_t)/3):round(2*length(log_t)/3);
    if length(mid_range) > 5
        fit_coeffs = polyfit(log_t(mid_range), log_msd_avg(mid_range), 1);
        analysis.alpha = fit_coeffs(1);
    else
        analysis.alpha = 1;
    end
    
    % Try simple GSER
    try
        [G_prime, G_double_prime] = simple_gser(t, msd_avg, analysis.alpha);
        if ~isempty(G_prime) && ~isempty(G_double_prime)
            analysis.gser_status = 'SUCCESS';
            analysis.G_prime = G_prime;
            analysis.G_double_prime = G_double_prime;
        else
            analysis.gser_status = 'FAILED';
        end
    catch
        analysis.gser_status = 'ERROR';
    end
    
else
    analysis.noise_reduction = 1;
    analysis.alpha = 1;
    analysis.gser_status = 'INSUFFICIENT_DATA';
end

end

function [G_prime, G_double_prime] = simple_gser(t, msd, alpha)
% Simple GSER application

% Physical constants (from your paper)
l = 0.243e-6;  % m
eta = 1.2e-3;  % Pa*s
R = l/2;       % m
k_B = 1.38e-23; % J/K
T = 293.15;    % K

% Unit conversion
D = k_B * T / (6 * pi * eta * R);
zeta = l^2 / (6 * D);

% Convert to experimental units
tau_exp = t * zeta;
msd_exp = msd * l^2;

% Apply GSER for middle section
valid_range = round(length(t)/4):round(3*length(t)/4);
if length(valid_range) > 10
    tau_gser = tau_exp(valid_range);
    msd_gser = msd_exp(valid_range);
    
    omega = 1 ./ tau_gser;
    
    % Use constant alpha for simplicity
    alpha_const = alpha;
    
    % GSER formulas
    G_star_mag = k_B * T ./ (pi * msd_gser * gamma(1 + alpha_const));
    G_prime = G_star_mag * cos(pi * alpha_const / 2);
    G_double_prime = G_star_mag * sin(pi * alpha_const / 2);
else
    G_prime = [];
    G_double_prime = [];
end

end

function create_simple_plots(results)
% Create simple validation plots

figure('Position', [100, 100, 1000, 600]);

n_results = length(results);
colors = lines(n_results);

% Plot 1: MSD comparison
subplot(2, 3, 1);
hold on;
for i = 1:n_results
    r = results(i);
    loglog(r.t, r.msd_raw, ':', 'Color', colors(i, :), 'LineWidth', 1);
    loglog(r.t, r.msd_avg, '-', 'Color', colors(i, :), 'LineWidth', 2, ...
           'DisplayName', sprintf('p = %.1f', r.p));
end
xlabel('τ (steps)');
ylabel('MSD');
title('MSD: Raw (:) vs Lag-averaged (-)');
legend('Location', 'best');
grid on;

% Plot 2: Power law exponents
subplot(2, 3, 2);
p_vals = [results.p];
alphas = [results.analysis];
alpha_values = [alphas.alpha];

plot(p_vals, alpha_values, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
hold on;
plot(p_vals, ones(size(p_vals)), 'k--', 'LineWidth', 1);
xlabel('p');
ylabel('Power law exponent α');
title('MSD Power Law Exponents');
grid on;

% Plot 3: Noise reduction
subplot(2, 3, 3);
noise_reductions = [alphas.noise_reduction];
bar(p_vals, noise_reductions);
xlabel('p');
ylabel('Noise reduction factor');
title('Benefit of Lag-averaging');
grid on;

% Plot 4-6: GSER results if available
for i = 1:n_results
    subplot(2, 3, 3+i);
    r = results(i);
    
    if strcmp(r.analysis.gser_status, 'SUCCESS')
        % Plot G' and G''
        omega = 1 ./ (r.t * 6.4e-3);  % Simple omega calculation
        mid_range = round(length(r.t)/4):round(3*length(r.t)/4);
        
        if length(mid_range) <= length(r.analysis.G_prime)
            loglog(omega(mid_range), r.analysis.G_prime, 'b-', 'LineWidth', 2, 'DisplayName', 'G''');
            hold on;
            loglog(omega(mid_range), r.analysis.G_double_prime, 'r--', 'LineWidth', 2, 'DisplayName', 'G''''');
            xlabel('ω (rad/s)');
            ylabel('G'', G'''' (Pa)');
            title(sprintf('GSER: p = %.1f', r.p));
            legend('Location', 'best');
            grid on;
        end
    else
        text(0.5, 0.5, sprintf('GSER: %s', r.analysis.gser_status), ...
             'HorizontalAlignment', 'center', 'Units', 'normalized');
        title(sprintf('p = %.1f', r.p));
    end
end

sgtitle('Simple MSD Validation Results');

end