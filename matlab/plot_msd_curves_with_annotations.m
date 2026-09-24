function plot_msd_curves_with_annotations()
% Plot MSD curves for all p values with annotations
% Shows changepoints, α determination regions, and power-law evidence

fprintf('=== Plotting MSD Curves with Annotations ===\n');

% Parameters
p_c_prime = 0.6884;
p_values = [0.0000, 0.3116, 0.6884, 0.7500];
seeds = [1, 2];

% Changepoint data from our analysis
tau_cr_data = struct();
tau_cr_data.p_0_0000 = [2.80e+03, 1.99e+04];  % seed_01, seed_02
tau_cr_data.p_0_3116 = [6.96e+05, 5.79e+05];  % seed_01, seed_02
tau_cr_data.p_0_6884 = [3.80e+03, 6.56e+04];  % seed_01, seed_02
tau_cr_data.p_0_7500 = [1.94e+04, 5.50e+03];  % seed_01, seed_02

% Optimal α values from our analysis
alpha_data = struct();
alpha_data.p_0_0000 = [1.000, 1.000];  % seed_01, seed_02
alpha_data.p_0_3116 = [1.000, 1.000];  % seed_01, seed_02
alpha_data.p_0_6884 = [0.500, 0.500];  % seed_01, seed_02
alpha_data.p_0_7500 = [0.001, 0.001];  % seed_01, seed_02

% Create figure
figure('Position', [100, 100, 1600, 1200]);

% Color scheme
colors = {'#1f77b4', '#ff7f0e', '#2ca02c', '#d62728'};  % Blue, Orange, Green, Red
regime_names = {'LIQUID', 'LIQUID', 'CRITICAL', 'SOLID'};

% Plot each p value
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    
    % Create subplot
    subplot(2, 2, p_idx);
    hold on;
    
    % Plot both seeds
    for seed_idx = 1:length(seeds)
        seed = seeds(seed_idx);
        
        % Load data
        data_path = sprintf('../ensemble_simulations/seed_%02d/p_%.4f/msd_results_L500_p%.4f.csv', seed, p, p);
        if exist(data_path, 'file')
            fprintf('Loading data: p = %.4f, seed = %02d\n', p, seed);
            data = readtable(data_path);
            t = data.tau;
            msd = data.msd;
            
            % Subsample for plotting (every 100th point for efficiency)
            if length(t) > 10000
                indices = 1:100:length(t);
                t_plot = t(indices);
                msd_plot = msd(indices);
            else
                t_plot = t;
                msd_plot = msd;
            end
            
            % Plot MSD curve
            plot(t_plot, msd_plot, 'Color', colors{p_idx}, 'LineWidth', 1.5, ...
                'DisplayName', sprintf('Seed %02d', seed));
            
            % Get changepoint data
            field_name = sprintf('p_%.4f', p);
            field_name = strrep(field_name, '.', '_');  % Replace dots with underscores
            tau_cr = tau_cr_data.(field_name)(seed_idx);
            alpha_opt = alpha_data.(field_name)(seed_idx);
            
            % Mark changepoint
            if tau_cr > 0
                % Find MSD value at changepoint
                [~, idx] = min(abs(t_plot - tau_cr));
                msd_cr = msd_plot(idx);
                
                % Plot changepoint
                plot(tau_cr, msd_cr, 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k', ...
                    'DisplayName', sprintf('τ_cr = %.2e', tau_cr));
                
                % Add text annotation
                text(tau_cr*1.5, msd_cr*0.7, sprintf('τ_cr = %.2e\nα = %.3f', tau_cr, alpha_opt), ...
                    'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', 'white');
            end
            
            % Add theoretical α line for comparison
            if p < p_c_prime - 0.05
                expected_alpha = 1.0;
            elseif abs(p - p_c_prime) < 0.05
                expected_alpha = 0.5;
            else
                expected_alpha = 0.0;
            end
            
            % Plot theoretical line
            t_theory = logspace(log10(min(t_plot)), log10(max(t_plot)), 100);
            msd_theory = t_theory.^expected_alpha;
            plot(t_theory, msd_theory, '--', 'Color', colors{p_idx}, 'LineWidth', 1, ...
                'DisplayName', sprintf('α = %.1f (theory)', expected_alpha));
            
        else
            fprintf('No data found: p = %.4f, seed = %02d\n', p, seed);
        end
    end
    
    % Set log-log scale
    set(gca, 'XScale', 'log', 'YScale', 'log');
    
    % Labels and title
    xlabel('Time τ');
    ylabel('MSD');
    title(sprintf('p = %.4f (%s)', p, regime_names{p_idx}));
    
    % Add regime information
    if p < p_c_prime - 0.05
        regime = 'LIQUID';
        expected_alpha = 1.0;
    elseif abs(p - p_c_prime) < 0.05
        regime = 'CRITICAL';
        expected_alpha = 0.5;
    else
        regime = 'SOLID';
        expected_alpha = 0.0;
    end
    
    % Add text box with regime info
    text(0.02, 0.98, sprintf('Regime: %s\nExpected α: %.1f\nDistance from p_c'': %.3f', ...
        regime, expected_alpha, abs(p - p_c_prime)), ...
        'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', 'white', 'EdgeColor', 'black');
    
    % Grid and legend
    grid on;
    legend('Location', 'best', 'FontSize', 8);
    
    % Set axis limits
    xlim([min(t_plot), max(t_plot)]);
    ylim([min(msd_plot), max(msd_plot)]);
end

% Add overall title
sgtitle('MSD Curves with Changepoint Annotations', 'FontSize', 16, 'FontWeight', 'bold');

% Save plot
saveas(gcf, 'msd_curves_with_annotations.png');
saveas(gcf, 'msd_curves_with_annotations.fig');
fprintf('MSD curves plot saved\n');

% Create power-law relationship plot
figure('Position', [100, 100, 1200, 800]);

% Prepare data for power-law analysis
p_analysis = [];
tau_analysis = [];
dist_analysis = [];
alpha_analysis = [];

for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    dist = abs(p - p_c_prime);
    
    % Skip critical point for scaling analysis
    if dist == 0
        continue;
    end
    
    % Get τ_cr values for this p
    switch p_idx
        case 1  % p = 0.0000
            tau_values = tau_cr_data.p_0_0000;
            alpha_values = alpha_data.p_0_0000;
        case 2  % p = 0.3116
            tau_values = tau_cr_data.p_0_3116;
            alpha_values = alpha_data.p_0_3116;
        case 4  % p = 0.7500
            tau_values = tau_cr_data.p_0_7500;
            alpha_values = alpha_data.p_0_7500;
    end
    
    % Add to analysis arrays
    for j = 1:length(tau_values)
        p_analysis = [p_analysis, p];
        tau_analysis = [tau_analysis, tau_values(j)];
        dist_analysis = [dist_analysis, dist];
        alpha_analysis = [alpha_analysis, alpha_values(j)];
    end
end

% Create subplots for power-law analysis
subplot(2, 2, 1);
loglog(dist_analysis, tau_analysis, 'bo', 'MarkerSize', 10, 'DisplayName', 'Data');
hold on;

% Fit power law
log_dist = log10(dist_analysis);
log_tau = log10(tau_analysis);
coeffs = polyfit(log_dist, log_tau, 1);
exponent = coeffs(1);
intercept = coeffs(2);

% Plot fit
dist_range = logspace(log10(min(dist_analysis)), log10(max(dist_analysis)), 100);
tau_fit = 10.^(exponent * log10(dist_range) + intercept);
loglog(dist_range, tau_fit, 'r-', 'LineWidth', 2, 'DisplayName', sprintf('Fit: ν = %.3f', exponent));

xlabel('|p - p_c''|');
ylabel('τ_cr');
title('Power-Law Relationship: τ_cr vs |p - p_c''|');
legend('Location', 'best');
grid on;

% Add critical point
critical_tau = [tau_cr_data.p_0_6884];
critical_dist = 0.001;  % Small value for visualization
loglog(critical_dist, mean(critical_tau), 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r', ...
    'DisplayName', 'Critical Point');

subplot(2, 2, 2);
plot(p_analysis, alpha_analysis, 'bo', 'MarkerSize', 10, 'DisplayName', 'Optimal α');
hold on;

% Add critical point
plot(p_c_prime, 0.5, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'DisplayName', 'Critical Point');

% Add theoretical lines
p_theory = [0, 0.3116, 0.6884, 0.75];
alpha_theory = [1.0, 1.0, 0.5, 0.0];
plot(p_theory, alpha_theory, 'k--', 'LineWidth', 2, 'DisplayName', 'Theoretical');

xlabel('p');
ylabel('α');
title('α Values vs p');
legend('Location', 'best');
grid on;
ylim([-0.1, 1.1]);

subplot(2, 2, 3);
% Show τ_cr vs p with regime coloring
hold on;

% Color by regime
liquid_mask = p_analysis < p_c_prime - 0.05;
solid_mask = p_analysis > p_c_prime + 0.05;

if any(liquid_mask)
    plot(p_analysis(liquid_mask), tau_analysis(liquid_mask), 'bo', 'MarkerSize', 10, 'DisplayName', 'Liquid');
end
plot(p_c_prime, mean(critical_tau), 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'DisplayName', 'Critical');
if any(solid_mask)
    plot(p_analysis(solid_mask), tau_analysis(solid_mask), 'go', 'MarkerSize', 10, 'DisplayName', 'Solid');
end

xline(p_c_prime, 'k--', 'LineWidth', 2, 'DisplayName', 'p_c''');
xlabel('p');
ylabel('τ_cr');
title('τ_cr vs p (Regime Coloring)');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

subplot(2, 2, 4);
% Show residuals
tau_pred = exponent * log_dist + intercept;
residuals = log_tau - tau_pred;

plot(log_dist, residuals, 'bo', 'MarkerSize', 10);
xlabel('log(|p - p_c''|)');
ylabel('Residuals');
title('Fit Residuals');
grid on;
yline(0, 'r--', 'LineWidth', 1);

sgtitle('Power-Law Analysis Summary', 'FontSize', 16, 'FontWeight', 'bold');

% Save power-law plot
% saveas(gcf, 'power_law_analysis_summary.fig');
% saveas(gcf, 'power_law_analysis_summary.png');
% fprintf('Power-law analysis plot saved\n');

% Print summary
fprintf('\n=== Summary ===\n');
fprintf('Power-law exponent: ν = %.3f\n', exponent);
fprintf('Equation: τ_cr ∝ |p - p_c''|^%.3f\n', exponent);
fprintf('R² = %.3f\n', 1 - sum(residuals.^2)/sum((log_tau - mean(log_tau)).^2));

fprintf('\n=== Analysis Complete ===\n');

end 