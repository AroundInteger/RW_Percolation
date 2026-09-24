function RW3D_fine_resolution_full_spectrum(realization_id, save_individual_files)
% RW3D_fine_resolution_full_spectrum.m
% Full p-spectrum MSD generation with fine resolution in transition region
% Using templating approach for efficiency
% 
% Usage: 
%   RW3D_fine_resolution_full_spectrum(1, true)  % Realization 1, save individual files
%   RW3D_fine_resolution_full_spectrum(2, false) % Realization 2, save only summary
%
% Parameters:
%   L = 500 (lattice size)
%   LW = 1e6 (1M steps)
%   NW = 2e3 (2000 walkers)
%   p_c' = 0.6884 (critical point)
%   Fine resolution: 0.01 in transition region p_c' ± 0.08

if nargin < 1
    realization_id = 1;
end
if nargin < 2
    save_individual_files = true;
end

% Parameters
L = 500;
L3 = L^3;
LW = 1e6;  % 1M steps
NW = 2e3;  % 2000 walkers
p_c_prime = 0.6884;
transition_width = 0.08;
resolution = 0.01;

% Define p values with fine resolution in transition region
p_min = max(0, p_c_prime - transition_width);
p_max = min(1, p_c_prime + transition_width);

% Create p values
p_values = [];

% Coarse resolution outside transition region
p_values = [p_values, 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6];
p_values = [p_values, p_min];

% Fine resolution in transition region
p_values = [p_values, p_min + resolution:resolution:p_max - resolution];
p_values = [p_values, p_max];

% Coarse resolution beyond transition region
p_values = [p_values, 0.75, 0.8, 0.85, 0.9];

p_values = unique(p_values);  % Remove duplicates
p_values = p_values(p_values <= 0.95);  % Avoid p = 1.0

Np = numel(p_values);
t = (1:LW)';

% Set random seed for reproducibility
rng(realization_id);

fprintf('=== RW3D Fine Resolution Full Spectrum ===\n');
fprintf('Realization ID: %d\n', realization_id);
fprintf('Critical point: p_c'' = %.4f\n', p_c_prime);
fprintf('Transition width: ±%.2f\n', transition_width);
fprintf('Resolution: %.2f\n', resolution);
fprintf('Parameters: L=%d, LW=%d, NW=%d\n', L, LW, NW);
fprintf('Total p values: %d\n', Np);
fprintf('p range: [%.4f, %.4f]\n', min(p_values), max(p_values));
fprintf('p values: [');
fprintf('%.4f ', p_values);
fprintf(']\n\n');

% Initialize results storage
results = struct();
results.p_values = p_values;
results.tau_cr = zeros(1, Np);
results.alpha_opt = zeros(1, Np);
results.alpha_error = zeros(1, Np);
results.regime = cell(1, Np);
results.distance_from_critical = zeros(1, Np);
results.realization_id = realization_id;
results.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

% Create output directory
output_dir = sprintf('fine_resolution_realization_%d', realization_id);
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Main simulation loop
for p_idx = 1:Np
    p_current = p_values(p_idx);
    
    fprintf('Progress: %d/%d (%.1f%%)\n', p_idx, Np, p_idx/Np*100);
    fprintf('Running simulation: p = %.4f\n', p_current);
    
    % Determine regime
    if p_current < p_c_prime - 0.05
        regime = 'LIQUID';
    elseif abs(p_current - p_c_prime) < 0.05
        regime = 'CRITICAL';
    else
        regime = 'SOLID';
    end
    
    fprintf('Regime: %s\n', regime);
    
    % --- Templating logic ---
    % Build up the template for this p_idx
    base_template = zeros(L, L, L);
    for i_p = 2:p_idx
        current_occupied = sum(base_template(:));
        target_occupied = round(p_values(i_p) * L3);
        additional_needed = target_occupied - current_occupied;
        if additional_needed > 0
            unoccupied = ~base_template;
            idx_unocc = find(unoccupied);
            selected = idx_unocc(randperm(length(idx_unocc), additional_needed));
            base_template(selected) = 1;
        end
    end
    bw = base_template;
    
    % Find free positions
    [px, py, pz] = ind2sub([L, L, L], find(~bw));
    N_rsp = numel(px);
    if N_rsp < NW
        error('Not enough free sites for walkers at p=%.4f (only %d available, need %d)', p_current, N_rsp, NW);
    end
    
    % Initialize walkers at random free positions
    rp = ceil(rand(NW, 1) * N_rsp);
    rsp = [px(rp), py(rp), pz(rp)];
    
    fprintf('Running %d walkers for %d steps...\n', NW, LW);
    tic;
    
    % Run random walks
    x = zeros(LW, NW); 
    y = x; 
    z = x;
    
    parfor i_rw = 1:NW
        [xyz, ~] = RW3D_P_SP(bw, LW, L, rsp(i_rw,:), [20, 5]);
        x(:, i_rw) = xyz(:, 1);
        y(:, i_rw) = xyz(:, 2);
        z(:, i_rw) = xyz(:, 3);
    end
    
    runtime = toc;
    fprintf('Simulation completed in %.2f seconds\n', runtime);
    
    % Calculate MSD
    dx = x - x(1, :);
    dy = y - y(1, :);
    dz = z - z(1, :);
    sd = dx.^2 + dy.^2 + dz.^2;
    msd = mean(sd, 2);
    
    % Analyze α and find changepoint using robust method
    [tau_cr, alpha_opt, alpha_error] = robust_local_alpha_analysis(t, msd);
    
    % Store results
    results.tau_cr(p_idx) = tau_cr;
    results.alpha_opt(p_idx) = alpha_opt;
    results.alpha_error(p_idx) = alpha_error;
    results.regime{p_idx} = regime;
    results.distance_from_critical(p_idx) = abs(p_current - p_c_prime);
    
    % Print summary
    if ~isnan(tau_cr)
        fprintf('  p = %.4f (%s): τ_cr = %.2e, α = %.3f, error = %.3f\n', ...
            p_current, regime, tau_cr, alpha_opt, alpha_error);
    else
        fprintf('  p = %.4f (%s): No changepoint found\n', p_current, regime);
    end
    
    % Save individual file if requested
    if save_individual_files
        % Save MSD data
        msd_filename = sprintf('%s/msd_results_L%d_p%.4f.csv', output_dir, L, p_current);
        msd_table = table(t, msd, 'VariableNames', {'tau', 'msd'});
        writetable(msd_table, msd_filename);
        
        % Save full trajectory data (optional - can be large)
        % traj_filename = sprintf('%s/trajectory_L%d_p%.4f.mat', output_dir, L, p_current);
        % save(traj_filename, 't', 'msd', 'x', 'y', 'z', 'bw', 'p_current', 'L', 'LW', 'NW', 'runtime');
    end
    
    fprintf('Job %d completed successfully!\n\n', p_idx);
end

% Save comprehensive results
results_filename = sprintf('%s/fine_resolution_results_realization_%d.mat', output_dir, realization_id);
save(results_filename, 'results', 'p_values', 'p_c_prime', 'L', 'LW', 'NW');

% Save CSV version for Python compatibility
csv_filename = sprintf('%s/fine_resolution_results_realization_%d.csv', output_dir, realization_id);
results_table = table(results.p_values', results.tau_cr', results.alpha_opt', results.alpha_error', ...
    results.regime', results.distance_from_critical', ...
    'VariableNames', {'p_values', 'tau_cr', 'alpha_opt', 'alpha_error', 'regime', 'distance_from_critical'});
writetable(results_table, csv_filename);

fprintf('=== Analysis Complete ===\n');
fprintf('Results saved to: %s\n', results_filename);
fprintf('CSV saved to: %s\n', csv_filename);

% Analyze power-law relationship
analyze_power_law_results(results, p_c_prime);

% Generate summary plots
plot_fine_resolution_results(results, p_c_prime, realization_id, output_dir);

end

function [tau_cr, alpha_opt, alpha_error] = robust_local_alpha_analysis(t, msd)
% Robust local α analysis matching the successful method
% Returns changepoint time, optimal α, and α error

window_size = min(20, length(t) / 10);  % Same as successful method

% Remove first few points to avoid zero MSD
start_idx = max(10, round(window_size / 2));
end_idx = length(t) - round(window_size / 2);

alpha_values = [];
alpha_errors = [];
tau_values = [];

for i = start_idx:end_idx
    % Define window
    window_start = max(1, i - round(window_size / 2));
    window_end = min(length(t), i + round(window_size / 2));
    
    t_window = t(window_start:window_end);
    msd_window = msd(window_start:window_end);
    
    % Check if all MSD values are positive
    if all(msd_window > 0)
        % Fit power law
        ln_t = log10(t_window);
        ln_msd = log10(msd_window);
        
        try
            coeffs = polyfit(ln_t, ln_msd, 1);
            alpha = coeffs(1);
            
            % Calculate R² for quality assessment
            msd_pred = 10.^(alpha * ln_t + coeffs(2));
            ss_res = sum((msd_window - msd_pred).^2);
            ss_tot = sum((msd_window - mean(msd_window)).^2);
            
            % Avoid division by zero
            if ss_tot > 0
                r_squared = 1 - (ss_res / ss_tot);
            else
                r_squared = 0;
            end
            
            alpha_values = [alpha_values, alpha];
            alpha_errors = [alpha_errors, 1 - r_squared];  % Use (1 - R²) as error measure
            tau_values = [tau_values, t(i)];
            
        catch
            % Skip this point if fitting fails
            continue;
        end
    end
end

% Find changepoint based on α analysis
if isempty(alpha_values)
    tau_cr = NaN;
    alpha_opt = NaN;
    alpha_error = NaN;
    return;
end

% Find points with good quality (low error)
good_quality = alpha_errors < 0.1;

if ~any(good_quality)
    tau_cr = NaN;
    alpha_opt = NaN;
    alpha_error = NaN;
    return;
end

% Use the first point with good quality as changepoint
first_good_idx = find(good_quality, 1);
tau_cr = tau_values(first_good_idx);
alpha_opt = alpha_values(first_good_idx);
alpha_error = alpha_errors(first_good_idx);

end

function analyze_power_law_results(results, p_c_prime)
% Analyze power-law relationship between τ_cr and distance from critical point

fprintf('\n=== Power-Law Analysis ===\n');

% Filter out NaN values
valid_mask = ~isnan(results.tau_cr);
valid_p = results.p_values(valid_mask);
valid_tau_cr = results.tau_cr(valid_mask);
valid_distance = results.distance_from_critical(valid_mask);

if sum(valid_mask) < 2
    fprintf('Insufficient valid data for power-law analysis\n');
    return;
end

% Exclude critical point (distance = 0)
non_critical_mask = valid_distance > 0;
dist_non_critical = valid_distance(non_critical_mask);
tau_non_critical = valid_tau_cr(non_critical_mask);

if length(dist_non_critical) < 2
    fprintf('Insufficient data for power-law analysis (excluding critical point)\n');
    return;
end

% Fit power law
log_dist = log10(dist_non_critical);
log_tau = log10(tau_non_critical);

coeffs = polyfit(log_dist, log_tau, 1);
exponent = coeffs(1);
intercept = coeffs(2);

% Calculate R²
tau_pred = 10.^(exponent * log_dist + intercept);
ss_res = sum((tau_non_critical - tau_pred).^2);
ss_tot = sum((tau_non_critical - mean(tau_non_critical)).^2);
r_squared = 1 - (ss_res / ss_tot);

fprintf('Power-law exponent: ν = %.3f\n', exponent);
fprintf('R² = %.3f\n', r_squared);
fprintf('Equation: τ_cr ∝ |p - p_c''|^{%.3f}\n', exponent);

% Regime analysis
fprintf('\nRegime distribution:\n');
regimes = unique(results.regime);
for i = 1:length(regimes)
    regime = regimes{i};
    count = sum(strcmp(results.regime, regime));
    fprintf('  %s: %d points\n', regime, count);
end

% α analysis by regime
fprintf('\nα analysis by regime:\n');
for i = 1:length(regimes)
    regime = regimes{i};
    regime_mask = strcmp(results.regime, regime) & valid_mask;
    if sum(regime_mask) > 0
        alpha_mean = mean(results.alpha_opt(regime_mask));
        alpha_std = std(results.alpha_opt(regime_mask));
        fprintf('  %s: α = %.3f ± %.3f (n=%d)\n', regime, alpha_mean, alpha_std, sum(regime_mask));
    end
end

end

function plot_fine_resolution_results(results, p_c_prime, realization_id, output_dir)
% Generate summary plots

fprintf('\n=== Generating Plots ===\n');

% Filter out NaN values
valid_mask = ~isnan(results.tau_cr);
valid_p = results.p_values(valid_mask);
valid_tau_cr = results.tau_cr(valid_mask);
valid_alpha = results.alpha_opt(valid_mask);
valid_error = results.alpha_error(valid_mask);
valid_regime = results.regime(valid_mask);

if sum(valid_mask) == 0
    fprintf('No valid data for plotting\n');
    return;
end

% Create figure
figure('Position', [100, 100, 1200, 900]);

% Plot 1: τ_cr vs p
subplot(2, 2, 1);
colors = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, {'blue', 'red', 'green'});

for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    semilogy(valid_p(i), valid_tau_cr(i), 'o', 'Color', color, 'MarkerSize', 6);
    hold on;
end

xline(p_c_prime, '--k', 'LineWidth', 2, 'Label', 'p_c''');
xlabel('p');
ylabel('τ_cr');
title('Changepoint Time vs p (Fine Resolution)');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;

% Plot 2: Power-law relationship
subplot(2, 2, 2);
valid_distance = abs(valid_p - p_c_prime);
non_critical_mask = valid_distance > 0;
dist_non_critical = valid_distance(non_critical_mask);
tau_non_critical = valid_tau_cr(non_critical_mask);

if length(dist_non_critical) > 1
    loglog(dist_non_critical, tau_non_critical, 'bo', 'MarkerSize', 6);
    hold on;
    
    % Fit and plot power law
    log_dist = log10(dist_non_critical);
    log_tau = log10(tau_non_critical);
    coeffs = polyfit(log_dist, log_tau, 1);
    exponent = coeffs(1);
    
    dist_range = logspace(log10(min(dist_non_critical)), log10(max(dist_non_critical)), 100);
    tau_fit = 10.^(exponent * log10(dist_range) + coeffs(2));
    loglog(dist_range, tau_fit, 'r-', 'LineWidth', 2);
    
    legend('Data', sprintf('Fit: ν = %.3f', exponent), 'Location', 'best');
end

xlabel('|p - p_c''|');
ylabel('τ_cr');
title('Power-Law Relationship');
grid on;

% Plot 3: α vs p
subplot(2, 2, 3);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    plot(valid_p(i), valid_alpha(i), 'o', 'Color', color, 'MarkerSize', 6);
    hold on;
end

% Add theoretical lines
yline(1.0, '--b', 'Alpha', 0.5, 'Label', 'α = 1.0 (Liquid)');
yline(0.5, '--r', 'Alpha', 0.5, 'Label', 'α = 0.5 (Critical)');
yline(0.0, '--g', 'Alpha', 0.5, 'Label', 'α = 0.0 (Solid)');
xline(p_c_prime, '--k', 'LineWidth', 2, 'Label', 'p_c''');

xlabel('p');
ylabel('α');
title('Optimal α vs p');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;
ylim([-0.1, 1.1]);

% Plot 4: α error vs p
subplot(2, 2, 4);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    semilogy(valid_p(i), valid_error(i), 'o', 'Color', color, 'MarkerSize', 6);
    hold on;
end

yline(0.1, '--k', 'Alpha', 0.5, 'Label', 'Quality threshold');
xline(p_c_prime, '--k', 'LineWidth', 2, 'Label', 'p_c''');

xlabel('p');
ylabel('α Error (1 - R²)');
title('α Quality vs p');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;

sgtitle(sprintf('Fine Resolution Analysis - Realization %d', realization_id));

% Save plot
plot_filename = sprintf('%s/fine_resolution_analysis_realization_%d.png', output_dir, realization_id);
saveas(gcf, plot_filename, 'png');
fprintf('Plot saved to: %s\n', plot_filename);

end 