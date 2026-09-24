% test_fine_resolution_single.m
% Test script for fine resolution analysis with smaller parameters
% This is a quick test to verify the implementation works
% Enhanced with detailed MSD curve annotations

clear; clc; close all;

fprintf('=== Testing Fine Resolution Analysis ===\n');

% Test parameters (smaller for quick testing)
L = 500;  % Smaller lattice
LW = 1e5;  % 100K steps (faster)
NW = 2e3;  % Fewer walkers
p_c_prime = 0.6884;
transition_width = 0.05;  % Smaller transition region
resolution = 0.02;  % Coarser resolution

fprintf('Test parameters: L=%d, LW=%d, NW=%d\n', L, LW, NW);
fprintf('Transition width: ±%.2f, Resolution: %.2f\n', transition_width, resolution);

% Define p values for testing
p_min = max(0, p_c_prime - transition_width);
p_max = min(1, p_c_prime + transition_width);

p_values = [0.0, 0.1, 0.2, 0.3, 1-p_c_prime, 0.5, 0.6, p_min];
p_values = [p_values, p_min + resolution:resolution:p_max - resolution];
p_values = [p_values, p_max, 0.75, 0.8, 0.9];

p_values = unique(p_values);
p_values = p_values(p_values <= 0.95);

Np = numel(p_values);
t = (1:LW)';

fprintf('Test p values: [');
fprintf('%.3f ', p_values);
fprintf(']\n');
fprintf('Total p values: %d\n\n', Np);

% Initialize results
results = struct();
results.p_values = p_values;
results.tau_cr = zeros(1, Np);
results.alpha_opt = zeros(1, Np);
results.alpha_error = zeros(1, Np);
results.regime = cell(1, Np);
results.distance_from_critical = zeros(1, Np);
results.msd_data = cell(1, Np);
results.t_data = cell(1, Np);
results.alpha_analysis = cell(1, Np);

% Test simulation loop
for p_idx = 1:Np
    p_current = p_values(p_idx);
    
    fprintf('Test %d/%d: p = %.3f\n', p_idx, Np, p_current);
    
    % Determine regime
    if p_current < p_c_prime - 0.05
        regime = 'LIQUID';
    elseif abs(p_current - p_c_prime) < 0.05
        regime = 'CRITICAL';
    else
        regime = 'SOLID';
    end
    
    % Generate 3D lattice
    rng(p_idx);  % Different seed for each p
    R = rand(L, L, L);
    bw = R < p_current;
    
    % Find free positions
    [px, py, pz] = ind2sub([L, L, L], find(~bw));
    N_rsp = numel(px);
    
    if N_rsp < NW
        fprintf('  Warning: Only %d free positions for %d walkers\n', N_rsp, NW);
        continue;
    end
    
    % Initialize walkers
    rp = ceil(rand(NW, 1) * N_rsp);
    rsp = [px(rp), py(rp), pz(rp)];
    
    fprintf('  Running %d walkers for %d steps...\n', NW, LW);
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
    fprintf('  Simulation completed in %.2f seconds\n', runtime);
    
    % Calculate MSD
    dx = x - x(1, :);
    dy = y - y(1, :);
    dz = z - z(1, :);
    sd = dx.^2 + dy.^2 + dz.^2;
    msd = mean(sd, 2);
    
    % Store MSD data for plotting
    results.msd_data{p_idx} = msd;
    results.t_data{p_idx} = t;
    
    % Analyze α and find changepoint with detailed analysis
    [tau_cr, alpha_opt, alpha_error, alpha_analysis] = robust_local_alpha_analysis_detailed(t, msd);
    
    % Store results
    results.tau_cr(p_idx) = tau_cr;
    results.alpha_opt(p_idx) = alpha_opt;
    results.alpha_error(p_idx) = alpha_error;
    results.regime{p_idx} = regime;
    results.distance_from_critical(p_idx) = abs(p_current - p_c_prime);
    results.alpha_analysis{p_idx} = alpha_analysis;
    
    % Print summary
    if ~isnan(tau_cr)
        fprintf('  Result: τ_cr = %.2e, α = %.3f, error = %.3f (%s)\n', ...
            tau_cr, alpha_opt, alpha_error, regime);
    else
        fprintf('  Result: No changepoint found (%s)\n', regime);
    end
    
    fprintf('\n');
end

% Test analysis
fprintf('=== Test Analysis ===\n');

% Filter out NaN values
valid_mask = ~isnan(results.tau_cr);
valid_p = results.p_values(valid_mask);
valid_tau_cr = results.tau_cr(valid_mask);
valid_distance = results.distance_from_critical(valid_mask);

fprintf('Valid data points: %d/%d\n', sum(valid_mask), Np);

if sum(valid_mask) >= 2
    % Exclude critical point
    non_critical_mask = valid_distance > 0;
    dist_non_critical = valid_distance(non_critical_mask);
    tau_non_critical = valid_tau_cr(non_critical_mask);
    
    if length(dist_non_critical) >= 2
        % Fit power law
        log_dist = log10(dist_non_critical);
        log_tau = log10(tau_non_critical);
        
        coeffs = polyfit(log_dist, log_tau, 1);
        exponent = coeffs(1);
        
        % Calculate R²
        tau_pred = 10.^(exponent * log_dist + coeffs(2));
        ss_res = sum((tau_non_critical - tau_pred).^2);
        ss_tot = sum((tau_non_critical - mean(tau_non_critical)).^2);
        r_squared = 1 - (ss_res / ss_tot);
        
        fprintf('Test power-law exponent: ν = %.3f\n', exponent);
        fprintf('Test R² = %.3f\n', r_squared);
        fprintf('Test equation: τ_cr ∝ |p - p_c''|^{%.3f}\n', exponent);
    else
        fprintf('Insufficient data for power-law analysis\n');
    end
else
    fprintf('Insufficient valid data for analysis\n');
end

% Create comprehensive test plots with MSD curve annotations
create_detailed_msd_plots(results, p_c_prime);

fprintf('\n=== Test Complete ===\n');
fprintf('Detailed MSD plots with annotations generated.\n');

%==========================================================================

function [tau_cr, alpha_opt, alpha_error, alpha_analysis] = robust_local_alpha_analysis_detailed(t, msd)
% Robust local α analysis with detailed output for plotting

window_size = min(20, length(t) / 10);

start_idx = max(10, round(window_size / 2));
end_idx = length(t) - round(window_size / 2);

alpha_values = [];
alpha_errors = [];
tau_values = [];
r_squared_values = [];

for i = start_idx:end_idx
    window_start = max(1, i - round(window_size / 2));
    window_end = min(length(t), i + round(window_size / 2));
    
    t_window = t(window_start:window_end);
    msd_window = msd(window_start:window_end);
    
    if all(msd_window > 0)
        ln_t = log10(t_window);
        ln_msd = log10(msd_window);
        
        try
            coeffs = polyfit(ln_t, ln_msd, 1);
            alpha = coeffs(1);
            
            msd_pred = 10.^(alpha * ln_t + coeffs(2));
            ss_res = sum((msd_window - msd_pred).^2);
            ss_tot = sum((msd_window - mean(msd_window)).^2);
            
            if ss_tot > 0
                r_squared = 1 - (ss_res / ss_tot);
            else
                r_squared = 0;
            end
            
            alpha_values = [alpha_values, alpha];
            alpha_errors = [alpha_errors, 1 - r_squared];
            tau_values = [tau_values, t(i)];
            r_squared_values = [r_squared_values, r_squared];
            
        catch
            continue;
        end
    end
end

% Store detailed analysis
alpha_analysis = struct();
alpha_analysis.tau_values = tau_values;
alpha_analysis.alpha_values = alpha_values;
alpha_analysis.alpha_errors = alpha_errors;
alpha_analysis.r_squared_values = r_squared_values;

if isempty(alpha_values)
    tau_cr = NaN;
    alpha_opt = NaN;
    alpha_error = NaN;
    return;
end

good_quality = alpha_errors < 0.1;

if ~any(good_quality)
    tau_cr = NaN;
    alpha_opt = NaN;
    alpha_error = NaN;
    return;
end

first_good_idx = find(good_quality, 1);
tau_cr = tau_values(first_good_idx);
alpha_opt = alpha_values(first_good_idx);
alpha_error = alpha_errors(first_good_idx);

end

function create_detailed_msd_plots(results, p_c_prime)
% Create detailed MSD plots with comprehensive annotations

% Filter out NaN values
valid_mask = ~isnan(results.tau_cr);
valid_p = results.p_values(valid_mask);
valid_tau_cr = results.tau_cr(valid_mask);
valid_alpha = results.alpha_opt(valid_mask);
valid_error = results.alpha_error(valid_mask);
valid_regime = results.regime(valid_mask);
valid_distance = results.distance_from_critical(valid_mask);

if sum(valid_mask) == 0
    fprintf('No valid data for plotting\n');
    return;
end

% Create main figure with MSD curves and annotations
figure('Position', [100, 100, 1400, 1000]);

% Determine number of subplots (one for each valid p value)
num_plots = sum(valid_mask);
cols = ceil(sqrt(num_plots));
rows = ceil(num_plots / cols);

% Colors for different regimes
colors = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, {'blue', 'red', 'green'});

% Plot MSD curves with annotations for each p value
plot_idx = 1;
for i = 1:length(results.p_values)
    if valid_mask(i)
        subplot(rows, cols, plot_idx);
        
        p_current = results.p_values(i);
        regime = results.regime{i};
        tau_cr = results.tau_cr(i);
        alpha_opt = results.alpha_opt(i);
        alpha_error = results.alpha_error(i);
        distance = results.distance_from_critical(i);
        
        % Get MSD data
        t_data = results.t_data{i};
        msd_data = results.msd_data{i};
        alpha_analysis = results.alpha_analysis{i};
        
        % Plot MSD curve
        loglog(t_data, msd_data, 'b-', 'LineWidth', 1.5);
        hold on;
        
        % Add theoretical lines based on regime
        if strcmp(regime, 'LIQUID')
            % Normal diffusion: MSD ∝ t
            theoretical_line = t_data;
            loglog(t_data, theoretical_line, '--b', 'LineWidth', 1);alpha(0.7)
            theoretical_alpha = 1.0;
        elseif strcmp(regime, 'CRITICAL')
            % Anomalous diffusion: MSD ∝ t^0.5
            theoretical_line = t_data.^0.5;
            loglog(t_data, theoretical_line, '--r', 'LineWidth', 1);alpha(0.7)
            theoretical_alpha = 0.5;
        else % SOLID
            % Arrested diffusion: MSD ∝ t^0
            theoretical_line = ones(size(t_data));
            loglog(t_data, theoretical_line, '--g', 'LineWidth', 1);alpha(0.7)
            theoretical_alpha = 0.0;
        end
        
        % Mark changepoint if found
        if ~isnan(tau_cr)
            % Find closest time index
            [~, tau_idx] = min(abs(t_data - tau_cr));
            loglog(tau_cr, msd_data(tau_idx), 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
            
            % Add arrow and annotation
            arrow([tau_cr/2, msd_data(tau_idx)/2], [tau_cr, msd_data(tau_idx)], 'Color', 'k', 'LineWidth', 2);
            text(tau_cr*1.5, msd_data(tau_idx)/2, sprintf('τ_cr = %.1e\nα = %.3f', tau_cr, alpha_opt), ...
                'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', 'white');
        end
        
        % Add α analysis regions if available
        if ~isempty(alpha_analysis) && isfield(alpha_analysis, 'tau_values')
            % Plot α values along the curve
            scatter(alpha_analysis.tau_values, msd_data(1:length(alpha_analysis.tau_values)), ...
                20, alpha_analysis.alpha_values, 'filled', 'MarkerFaceAlpha', 0.6);
            
            % Add colorbar for α values
            colormap(gca, 'jet');
            c = colorbar;
            c.Label.String = 'α values';
            caxis([0, 1]);
        end
        
        % Add regime information box
        regime_text = sprintf('%s\np = %.3f\n|p-p_c''| = %.3f\nExpected α = %.1f', ...
            regime, p_current, distance, theoretical_alpha);
        text(0.02, 0.98, regime_text, 'Units', 'normalized', ...
            'VerticalAlignment', 'top', 'FontSize', 9, 'FontWeight', 'bold', ...
            'BackgroundColor', 'white', 'EdgeColor', colors(regime), 'LineWidth', 1);
        
        % Add quality indicator
        if ~isnan(alpha_error)
            if alpha_error < 0.05
                quality = 'EXCELLENT';
                quality_color = 'green';
            elseif alpha_error < 0.1
                quality = 'GOOD';
                quality_color = 'orange';
            else
                quality = 'POOR';
                quality_color = 'red';
            end
            
            text(0.98, 0.02, sprintf('Quality: %s\nError: %.3f', quality, alpha_error), ...
                'Units', 'normalized', 'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'right', 'FontSize', 8, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', quality_color, 'LineWidth', 1);
        end
        
        xlabel('Time t');
        ylabel('MSD(t)');
        title(sprintf('p = %.3f (%s)', p_current, regime));
        grid on;
        
        % Set axis limits
        xlim([min(t_data), max(t_data)]);
        ylim([min(msd_data), max(msd_data)]);
        
        plot_idx = plot_idx + 1;
    end
end

sgtitle(sprintf('Detailed MSD Curves with Annotations (p_c'' = %.4f)', p_c_prime), 'FontSize', 14, 'FontWeight', 'bold');

% Create summary analysis plots
figure('Position', [100, 100, 1200, 800]);

% Plot 1: τ_cr vs p
subplot(2, 3, 1);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    semilogy(valid_p(i), valid_tau_cr(i), 'o', 'Color', color, 'MarkerSize', 8, 'MarkerFaceColor', color);
    hold on;
end

xline(p_c_prime, '--k', 'LineWidth', 2, 'Label', 'p_c''');
xlabel('p');
ylabel('τ_cr');
title('Changepoint Time vs p');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;

% Plot 2: Power-law relationship
subplot(2, 3, 2);
non_critical_mask = valid_distance > 0;
dist_non_critical = valid_distance(non_critical_mask);
tau_non_critical = valid_tau_cr(non_critical_mask);

if length(dist_non_critical) >= 2
    loglog(dist_non_critical, tau_non_critical, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
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
subplot(2, 3, 3);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    plot(valid_p(i), valid_alpha(i), 'o', 'Color', color, 'MarkerSize', 8, 'MarkerFaceColor', color);
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
subplot(2, 3, 4);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    semilogy(valid_p(i), valid_error(i), 'o', 'Color', color, 'MarkerSize', 8, 'MarkerFaceColor', color);
    hold on;
end

yline(0.1, '--k', 'Alpha', 0.5, 'Label', 'Quality threshold');
xline(p_c_prime, '--k', 'LineWidth', 2, 'Label', 'p_c''');

xlabel('p');
ylabel('α Error (1 - R²)');
title('α Quality vs p');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;

% Plot 5: τ_cr vs distance from critical point
subplot(2, 3, 5);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    semilogy(valid_distance(i), valid_tau_cr(i), 'o', 'Color', color, 'MarkerSize', 8, 'MarkerFaceColor', color);
    hold on;
end

xlabel('|p - p_c''|');
ylabel('τ_cr');
title('τ_cr vs Distance from Critical Point');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;

% Plot 6: α vs distance from critical point
subplot(2, 3, 6);
for i = 1:length(valid_p)
    regime = valid_regime{i};
    color = colors(regime);
    plot(valid_distance(i), valid_alpha(i), 'o', 'Color', color, 'MarkerSize', 8, 'MarkerFaceColor', color);
    hold on;
end

xlabel('|p - p_c''|');
ylabel('α');
title('α vs Distance from Critical Point');
legend('LIQUID', 'CRITICAL', 'SOLID', 'Location', 'best');
grid on;
ylim([-0.1, 1.1]);

sgtitle('Fine Resolution Test Analysis Summary', 'FontSize', 14, 'FontWeight', 'bold');

end 