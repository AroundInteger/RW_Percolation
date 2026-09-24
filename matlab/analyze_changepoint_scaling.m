function analyze_changepoint_scaling()
% Analyze power-law relationship between τ_cr and distance from critical point
% Investigate transition from anomalous to regular diffusion

fprintf('=== Changepoint Scaling Analysis ===\n');
fprintf('Investigating power-law relationship between τ_cr and |p - p_c''|\n\n');

% Parameters
p_c_prime = 0.6884;
p_values = [0.0000, 0.3116, 0.6884, 0.7500];
seeds = [1, 2];

% Results from our testing (τ_cr values)
tau_cr_data = struct();
tau_cr_data.p_0000 = [2.80e+03, 1.99e+04, 5.20e+03];  % seed_01, seed_02, seed_03
tau_cr_data.p_3116 = [6.96e+05, 5.79e+05];            % seed_01, seed_02
tau_cr_data.p_6884 = [3.80e+03, 6.56e+04];            % seed_01, seed_02
tau_cr_data.p_7500 = [1.94e+04, 5.50e+03];            % seed_01, seed_02

% Calculate distances from critical point
distances = abs(p_values - p_c_prime);
fprintf('Distances from critical point:\n');
for i = 1:length(p_values)
    fprintf('p = %.4f: |p - p_c''| = %.4f\n', p_values(i), distances(i));
end

% Analyze scaling relationship
fprintf('\n=== Scaling Analysis ===\n');

% Prepare data for analysis
p_analysis = [];
tau_analysis = [];
dist_analysis = [];

for i = 1:length(p_values)
    p = p_values(i);
    dist = distances(i);
    
    % Get τ_cr values for this p
    switch i
        case 1  % p = 0.0000
            tau_values = tau_cr_data.p_0000(1:2);  % Use seed_01 and seed_02
        case 2  % p = 0.3116
            tau_values = tau_cr_data.p_3116;
        case 3  % p = 0.6884
            tau_values = tau_cr_data.p_6884;
        case 4  % p = 0.7500
            tau_values = tau_cr_data.p_7500;
    end
    
    % Add to analysis arrays
    for j = 1:length(tau_values)
        p_analysis = [p_analysis, p];
        tau_analysis = [tau_analysis, tau_values(j)];
        dist_analysis = [dist_analysis, dist];
    end
end

% Log-log analysis
log_dist = log10(dist_analysis);
log_tau = log10(tau_analysis);

% Fit power law: τ_cr ∝ |p - p_c'|^ν
coeffs = polyfit(log_dist, log_tau, 1);
exponent = coeffs(1);
intercept = coeffs(2);

% Calculate R-squared
tau_pred = exponent * log_dist + intercept;
ss_res = sum((log_tau - tau_pred).^2);
ss_tot = sum((log_tau - mean(log_tau)).^2);
r_squared = 1 - ss_res/ss_tot;

fprintf('Power-law fit: τ_cr ∝ |p - p_c''|^ν\n');
fprintf('Exponent ν = %.3f\n', exponent);
fprintf('R² = %.3f\n', r_squared);
fprintf('Equation: log(τ_cr) = %.3f × log(|p - p_c''|) + %.3f\n', exponent, intercept);

% Calculate predicted values
tau_predicted = 10.^(exponent * log_dist + intercept);

% Calculate residuals
residuals = log_tau - (exponent * log_dist + intercept);
rmse = sqrt(mean(residuals.^2));

fprintf('RMSE = %.3f\n', rmse);

% Analyze by regime
fprintf('\n=== Regime Analysis ===\n');

% Liquid regime (p < p_c' - 0.05)
liquid_mask = p_analysis < p_c_prime - 0.05;
if any(liquid_mask)
    liquid_tau = tau_analysis(liquid_mask);
    liquid_dist = dist_analysis(liquid_mask);
    fprintf('Liquid regime (p < %.3f):\n', p_c_prime - 0.05);
    fprintf('  τ_cr range: [%.2e, %.2e]\n', min(liquid_tau), max(liquid_tau));
    fprintf('  Distance range: [%.4f, %.4f]\n', min(liquid_dist), max(liquid_dist));
    
    % Fit for liquid regime
    liquid_coeffs = polyfit(log10(liquid_dist), log10(liquid_tau), 1);
    liquid_tau_pred = liquid_coeffs(1) * log10(liquid_dist) + liquid_coeffs(2);
    liquid_ss_res = sum((log10(liquid_tau) - liquid_tau_pred).^2);
    liquid_ss_tot = sum((log10(liquid_tau) - mean(log10(liquid_tau))).^2);
    liquid_r_squared = 1 - liquid_ss_res/liquid_ss_tot;
    fprintf('  Power-law exponent: %.3f (R² = %.3f)\n', liquid_coeffs(1), liquid_r_squared);
end

% Critical regime (|p - p_c'| < 0.05)
critical_mask = abs(p_analysis - p_c_prime) < 0.05;
if any(critical_mask)
    critical_tau = tau_analysis(critical_mask);
    critical_dist = dist_analysis(critical_mask);
    fprintf('Critical regime (|p - p_c''| < 0.05):\n');
    fprintf('  τ_cr range: [%.2e, %.2e]\n', min(critical_tau), max(critical_tau));
    fprintf('  Distance range: [%.4f, %.4f]\n', min(critical_dist), max(critical_dist));
    
    if length(critical_dist) > 1
        critical_coeffs = polyfit(log10(critical_dist), log10(critical_tau), 1);
        critical_tau_pred = critical_coeffs(1) * log10(critical_dist) + critical_coeffs(2);
        critical_ss_res = sum((log10(critical_tau) - critical_tau_pred).^2);
        critical_ss_tot = sum((log10(critical_tau) - mean(log10(critical_tau))).^2);
        critical_r_squared = 1 - critical_ss_res/critical_ss_tot;
        fprintf('  Power-law exponent: %.3f (R² = %.3f)\n', critical_coeffs(1), critical_r_squared);
    else
        fprintf('  Insufficient data for fitting\n');
    end
end

% Solid regime (p > p_c' + 0.05)
solid_mask = p_analysis > p_c_prime + 0.05;
if any(solid_mask)
    solid_tau = tau_analysis(solid_mask);
    solid_dist = dist_analysis(solid_mask);
    fprintf('Solid regime (p > %.3f):\n', p_c_prime + 0.05);
    fprintf('  τ_cr range: [%.2e, %.2e]\n', min(solid_tau), max(solid_tau));
    fprintf('  Distance range: [%.4f, %.4f]\n', min(solid_dist), max(solid_dist));
    
    if length(solid_dist) > 1
        solid_coeffs = polyfit(log10(solid_dist), log10(solid_tau), 1);
        solid_tau_pred = solid_coeffs(1) * log10(solid_dist) + solid_coeffs(2);
        solid_ss_res = sum((log10(solid_tau) - solid_tau_pred).^2);
        solid_ss_tot = sum((log10(solid_tau) - mean(log10(solid_tau))).^2);
        solid_r_squared = 1 - solid_ss_res/solid_ss_tot;
        fprintf('  Power-law exponent: %.3f (R² = %.3f)\n', solid_coeffs(1), solid_r_squared);
    else
        fprintf('  Insufficient data for fitting\n');
    end
end

% Generate plots
generate_scaling_plots(p_analysis, tau_analysis, dist_analysis, exponent, intercept, r_squared, p_c_prime);

% Theoretical interpretation
fprintf('\n=== Theoretical Interpretation ===\n');
fprintf('The observed scaling τ_cr ∝ |p - p_c''|^%.3f suggests:\n', exponent);

if exponent < 0
    fprintf('• Negative exponent: τ_cr decreases as we move away from critical point\n');
    fprintf('• Faster transition to asymptotic behavior away from criticality\n');
    fprintf('• Critical slowing down near p_c''\n');
elseif exponent > 0
    fprintf('• Positive exponent: τ_cr increases as we move away from critical point\n');
    fprintf('• Slower transition to asymptotic behavior away from criticality\n');
    fprintf('• Critical acceleration near p_c''\n');
else
    fprintf('• Zero exponent: τ_cr independent of distance from critical point\n');
    fprintf('• No critical scaling in changepoint timing\n');
end

% Compare with known critical exponents
fprintf('\nComparison with known critical exponents:\n');
fprintf('• ν (correlation length): ~0.88 for 3D percolation\n');
fprintf('• z (dynamic exponent): ~2.0 for random walk on percolation clusters\n');
fprintf('• Our exponent: %.3f\n', exponent);

% Physical interpretation
fprintf('\n=== Physical Interpretation ===\n');
fprintf('The changepoint time τ_cr represents the crossover time from:\n');
fprintf('• Short-time anomalous diffusion to long-time asymptotic behavior\n');
fprintf('• This crossover is governed by the distance from criticality\n');
fprintf('• The power-law scaling reflects critical phenomena near p_c''\n');

fprintf('\n=== Analysis Complete ===\n');

end

function generate_scaling_plots(p_vals, tau_vals, dist_vals, exponent, intercept, r_squared, p_c_prime)
% Generate scaling analysis plots

figure('Position', [100, 100, 1200, 400]);

% Plot 1: τ_cr vs |p - p_c'| (log-log)
subplot(1, 3, 1);
loglog(dist_vals, tau_vals, 'bo', 'MarkerSize', 8, 'DisplayName', 'Data');
hold on;

% Fit line
dist_range = logspace(log10(min(dist_vals)), log10(max(dist_vals)), 100);
tau_fit = 10.^(exponent * log10(dist_range) + intercept);
loglog(dist_range, tau_fit, 'r-', 'LineWidth', 2, 'DisplayName', sprintf('Fit: ν = %.3f', exponent));

xlabel('|p - p_c''|');
ylabel('τ_cr');
title('Changepoint Time Scaling');
legend('Location', 'best');
grid on;

% Plot 2: Residuals
subplot(1, 3, 2);
log_dist = log10(dist_vals);
log_tau = log10(tau_vals);
tau_pred = exponent * log_dist + intercept;
residuals = log_tau - tau_pred;

plot(log_dist, residuals, 'bo', 'MarkerSize', 8);
xlabel('log(|p - p_c''|)');
ylabel('Residuals');
title('Fit Residuals');
grid on;
yline(0, 'r--', 'LineWidth', 1);

% Plot 3: τ_cr vs p with regime coloring
subplot(1, 3, 3);
hold on;

% Color by regime
liquid_mask = p_vals < p_c_prime - 0.05;
critical_mask = abs(p_vals - p_c_prime) < 0.05;
solid_mask = p_vals > p_c_prime + 0.05;

if any(liquid_mask)
    plot(p_vals(liquid_mask), tau_vals(liquid_mask), 'bo', 'MarkerSize', 8, 'DisplayName', 'Liquid');
end
if any(critical_mask)
    plot(p_vals(critical_mask), tau_vals(critical_mask), 'ro', 'MarkerSize', 8, 'DisplayName', 'Critical');
end
if any(solid_mask)
    plot(p_vals(solid_mask), tau_vals(solid_mask), 'go', 'MarkerSize', 8, 'DisplayName', 'Solid');
end

xline(p_c_prime, 'k--', 'LineWidth', 2, 'DisplayName', 'p_c''');
xlabel('p');
ylabel('τ_cr');
title('Changepoint Time by Regime');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

sgtitle(sprintf('Changepoint Scaling Analysis (R² = %.3f)', r_squared), 'FontSize', 14, 'FontWeight', 'bold');

% Save plot
saveas(gcf, 'changepoint_scaling_analysis.png');
saveas(gcf, 'changepoint_scaling_analysis.fig');
close(gcf);

fprintf('Scaling analysis plots saved\n');

end 