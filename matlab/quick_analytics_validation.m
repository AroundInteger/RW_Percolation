function quick_analytics_validation()
% Quick validation of analytics with short walks
% Run this first before scaling to full simulations

close all; clc;

% Quick test parameters
L = 100;           % Smaller lattice for speed
LW = 2000;         % Short walks (2,000 steps)
NW = 200;          % Fewer walkers for speed
p_values = [0.1, 0.35, 0.5, 0.65];  % Focus on p < p_c' regime
seed = 42;

fprintf('=== Quick Analytics Validation ===\n');
fprintf('Parameters: L=%d, LW=%d, NW=%d\n\n', L, LW, NW);

results = struct();

for i = 1:length(p_values)
    p_val = p_values(i);
    fprintf('Testing p = %.2f\n', p_val);
    
    % Run short simulation
    [t, msd, alpha_fit] = run_quick_simulation(p_val, L, LW, NW, seed);
    
    % Store results
    results(i).p = p_val;
    results(i).t = t;
    results(i).msd = msd;
    results(i).alpha_fit = alpha_fit;
    
    % Apply GSER and validate
    [omega, G_prime, G_double_prime, validation] = validate_gser(t, msd, p_val);
    
    results(i).omega = omega;
    results(i).G_prime = G_prime;
    results(i).G_double_prime = G_double_prime;
    results(i).validation = validation;
    
    fprintf('  α_MSD = %.3f, α_G'' = %.3f, α_G'''' = %.3f\n', ...
        alpha_fit, validation.alpha_Gp, validation.alpha_Gpp);
    fprintf('  G''/G'''' ratio std = %.4f\n', validation.ratio_std);
    fprintf('  Loss tangent = %.1f° (theory: %.1f°)\n', ...
        validation.delta_deg, validation.delta_theory_deg);
    fprintf('\n');
end

% Generate summary plots
create_validation_plots(results);

% Save results for further analysis
save('quick_validation_results.mat', 'results', 'p_values', 'L', 'LW', 'NW');
fprintf('Results saved to quick_validation_results.mat\n');

end

function [t, msd, alpha_fit] = run_quick_simulation(p_val, L, LW, NW, seed)
% Run a quick random walk simulation

rng(seed + round(p_val*1000)); % Reproducible but different for each p

% Build percolation lattice with templating
L3 = L^3;
template = zeros(L, L, L);

% Simple approach - just generate random occupation
if p_val > 0
    n_occupied = round(p_val * L3);
    idx_all = 1:L3;
    idx_occupied = randsample(idx_all, n_occupied, false);
    template(idx_occupied) = 1;
end

% Find free positions
[px, py, pz] = ind2sub([L, L, L], find(~template));
N_free = numel(px);

if N_free < NW
    error('Not enough free sites for %d walkers at p=%.2f', NW, p_val);
end

% Initialize walkers
rp = randsample(N_free, NW, false);
start_positions = [px(rp), py(rp), pz(rp)];

% Run random walks
t = (1:LW)';
positions = zeros(LW, 3, NW);

for i_walk = 1:NW
    positions(:, :, i_walk) = simple_random_walk_3D(template, LW, L, start_positions(i_walk, :));
end

% Calculate MSD
msd = zeros(LW, 1);
for i_step = 1:LW
    displacements = squeeze(positions(i_step, :, :)) - squeeze(positions(1, :, :));
    squared_displacements = sum(displacements.^2, 1);
    msd(i_step) = mean(squared_displacements);
end

% Fit power law to middle section to extract alpha
mid_start = round(LW/5);
mid_end = round(4*LW/5);
log_t_mid = log10(t(mid_start:mid_end));
log_msd_mid = log10(msd(mid_start:mid_end));

fit_coeff = polyfit(log_t_mid, log_msd_mid, 1);
alpha_fit = fit_coeff(1);

end

function trajectory = simple_random_walk_3D(template, LW, L, start_pos)
% Simple 3D random walk on template
% Returns trajectory: LW x 3 matrix

trajectory = zeros(LW, 3);
current_pos = start_pos;
trajectory(1, :) = current_pos;

% Neighbor offsets (von Neumann neighborhood)
neighbors = [1,0,0; -1,0,0; 0,1,0; 0,-1,0; 0,0,1; 0,0,-1];

for step = 2:LW
    % Choose random direction
    direction = neighbors(randi(6), :);
    new_pos = current_pos + direction;
    
    % Apply periodic boundary conditions
    new_pos = mod(new_pos - 1, L) + 1;
    
    % Check if site is free
    if ~template(new_pos(1), new_pos(2), new_pos(3))
        current_pos = new_pos;
    end
    % If occupied, stay in current position
    
    trajectory(step, :) = current_pos;
end

end

function [omega, G_prime, G_double_prime, validation] = validate_gser(t, msd, p_val)
% Apply GSER and validate analytical predictions

% Parameters for unit conversion (from your paper)
l = 0.243e-6;  % lattice constant in meters
eta = 1.2e-3;  % viscosity in Pa·s
R = l/2;       % probe radius
k_B = 1.38e-23; % Boltzmann constant
T = 293.15;    % temperature in K

% Calculate zeta (lag-time constant)
D = k_B * T / (6 * pi * eta * R);  % Stokes-Einstein (3D)
zeta = l^2 / (6 * D);  % Time for MSD = l^2

% Convert to experimental units
tau_exp = t * zeta;
msd_exp = msd * l^2;

% Calculate local slope (alpha) using numerical derivative
log_tau = log10(tau_exp(2:end));
log_msd = log10(msd_exp(2:end));
alpha_local = gradient(log_msd) ./ gradient(log_tau);

% Apply GSER
omega = 1 ./ tau_exp(2:end);
alpha_omega = alpha_local;

% Calculate G* components
Gamma_term = gamma(1 + alpha_omega);
G_star_mag = k_B * T ./ (pi * msd_exp(2:end) .* Gamma_term);

% Calculate G' and G''
G_prime = G_star_mag .* cos(pi * alpha_omega / 2);
G_double_prime = G_star_mag .* sin(pi * alpha_omega / 2);

% Validation analysis
validation = struct();

% Find region with most consistent alpha (likely anomalous diffusion)
alpha_smooth = movmean(alpha_omega, 20);
alpha_std = movstd(alpha_omega, 20);
[~, stable_idx] = min(alpha_std);

% Define analysis region around most stable alpha
analysis_range = max(1, stable_idx-50):min(length(alpha_omega), stable_idx+50);

if length(analysis_range) < 10
    analysis_range = round(length(alpha_omega)/3):round(2*length(alpha_omega)/3);
end

% Extract slopes from G' and G'' in log-log space
if length(analysis_range) >= 10
    log_omega_range = log10(omega(analysis_range));
    log_Gp_range = log10(max(G_prime(analysis_range), 1e-10));
    log_Gpp_range = log10(G_double_prime(analysis_range));
    
    fit_Gp = polyfit(log_omega_range, log_Gp_range, 1);
    fit_Gpp = polyfit(log_omega_range, log_Gpp_range, 1);
    
    validation.alpha_Gp = fit_Gp(1);
    validation.alpha_Gpp = fit_Gpp(1);
else
    validation.alpha_Gp = NaN;
    validation.alpha_Gpp = NaN;
end

% Check G'/G'' ratio consistency
ratio = G_prime(analysis_range) ./ G_double_prime(analysis_range);
validation.ratio_std = std(ratio);
validation.ratio_mean = mean(ratio);

% Loss tangent analysis
alpha_mean = mean(alpha_omega(analysis_range));
validation.alpha_mean = alpha_mean;
validation.delta_theory = pi * alpha_mean / 2;
validation.delta_theory_deg = validation.delta_theory * 180 / pi;

delta_measured = atan2(G_double_prime(analysis_range), G_prime(analysis_range));
validation.delta_measured_deg = mean(delta_measured) * 180 / pi;
validation.delta_deg = validation.delta_measured_deg;

end

function create_validation_plots(results)
% Create comprehensive validation plots

figure('Position', [100, 100, 1200, 800]);

n_p = length(results);
colors = lines(n_p);

% Plot 1: MSD curves
subplot(2, 3, 1);
hold on;
for i = 1:n_p
    loglog(results(i).t, results(i).msd, 'Color', colors(i, :), 'LineWidth', 2, ...
           'DisplayName', sprintf('p = %.2f', results(i).p));
end
xlabel('τ (steps)');
ylabel('MSD');
title('MSD vs Time');
legend('Location', 'best');
grid on;

% Plot 2: G'(ω) curves
subplot(2, 3, 2);
hold on;
for i = 1:n_p
    loglog(results(i).omega, results(i).G_prime, 'Color', colors(i, :), 'LineWidth', 2, ...
           'DisplayName', sprintf('p = %.2f', results(i).p));
end
xlabel('ω (rad/s)');
ylabel('G''(ω) (Pa)');
title('Storage Modulus');
legend('Location', 'best');
grid on;

% Plot 3: G''(ω) curves
subplot(2, 3, 3);
hold on;
for i = 1:n_p
    loglog(results(i).omega, results(i).G_double_prime, '--', 'Color', colors(i, :), 'LineWidth', 2, ...
           'DisplayName', sprintf('p = %.2f', results(i).p));
end
xlabel('ω (rad/s)');
ylabel('G''''(ω) (Pa)');
title('Loss Modulus');
legend('Location', 'best');
grid on;

% Plot 4: Power law exponent comparison
subplot(2, 3, 4);
p_vals = [results.p];
alpha_msd = [results.alpha_fit];
alpha_gp = [results(1).validation.alpha_Gp, results(2).validation.alpha_Gp, ...
           results(3).validation.alpha_Gp, results(4).validation.alpha_Gp];
alpha_gpp = [results(1).validation.alpha_Gpp, results(2).validation.alpha_Gpp, ...
            results(3).validation.alpha_Gpp, results(4).validation.alpha_Gpp];

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

% Plot 5: Loss tangent
subplot(2, 3, 5);
delta_theory = [results(1).validation.delta_theory_deg, results(2).validation.delta_theory_deg, ...
               results(3).validation.delta_theory_deg, results(4).validation.delta_theory_deg];
delta_measured = [results(1).validation.delta_measured_deg, results(2).validation.delta_measured_deg, ...
                 results(3).validation.delta_measured_deg, results(4).validation.delta_measured_deg];

plot(p_vals, delta_theory, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Theory: πα/2');
hold on;
plot(p_vals, delta_measured, 's-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Measured');

xlabel('p');
ylabel('Loss tangent δ (degrees)');
title('Loss Tangent Validation');
legend('Location', 'best');
grid on;

% Plot 6: G'/G'' ratio consistency
subplot(2, 3, 6);
ratio_std = [results(1).validation.ratio_std, results(2).validation.ratio_std, ...
            results(3).validation.ratio_std, results(4).validation.ratio_std];

semilogy(p_vals, ratio_std, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('p');
ylabel('G''/G'''' ratio std dev');
title('Ratio Consistency (lower = better)');
grid on;

sgtitle('Quick Analytics Validation Results');

end