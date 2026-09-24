%% Dynamic Mechanical Analysis - δ(ω), G'(ω), G''(ω)
% This script evaluates and visualizes dynamic mechanical properties
% derived from MSD data using the Generalized Stokes-Einstein Relation (GSER)

clear; clc; close all;

%% Load data
fprintf('Loading MSD data...\n');
data = readtable('p_output_NEW34.csv');
p_values = [];
msd_data = [];

% Extract p-values and MSD data
for i = 1:width(data)
    col_name = data.Properties.VariableNames{i};
    if startsWith(col_name, 'MSD_')
        p_str_id = max(findstr(col_name,'_'));
        p_str = str2double(strcat('0.',col_name(p_str_id+1:end)));
        p_values = [p_values, p_str];
        msd_data = [msd_data, data.(col_name)];
    end
end

% Create time array
t = (1:height(data))';

fprintf('Loaded %d p-values\n', length(p_values));






%% plot curves

id_l = find(p_values < 1);
figure(1),loglog(t,msd_data)

n_p1 = msd_data(:,id_l)./msd_data(end,id_l);
n_p11 = (n_p1./n_p1(:,1));
n_p11 (1,:) = n_p11 (2,:);

n_p111 = ones(size(id_l));

s_id = 1:50000;


for ii = 2:numel(id_l)
    sd = n_p11(:,ii);
    n_p111(ii) = find(sd<1,1,"first");
end
figure(2),loglog(t,n_p1(:,:))
figure(3),loglog(t,n_p11(:,:))
figure(4),semilogy(p_values(id_l),n_p111,'o')



%% Analyze all p-values
fprintf('\n=== DYNAMIC MECHANICAL ANALYSIS ===\n');

% Physical parameters (adjust as needed)
temperature = 298;  % Temperature in Kelvin
particle_radius = 1e-6;  % Particle radius in meters (1 μm)

% Initialize results
results = struct();
results.p = [];
results.regime = {};
results.omega_range = [];
results.G_storage_range = [];
results.G_loss_range = [];
results.delta_range = [];
results.alpha_msd = [];

% Sort p-values for systematic analysis
[sorted_p, sort_idx] = sort(p_values);

for i = 1:length(sorted_p)
    p = sorted_p(i);
    p_idx = sort_idx(i);
    
    % Get MSD data for this p-value
    msd = msd_data(:, p_idx);
    
    % Determine regime
    p_c = 0.3116;      % Gel-point of occupied sites (lower critical point)
    p_c_prime = 0.6884; % Gel-point of unoccupied sites (upper critical point)
    
    if p < p_c
        regime = 'LIQUID';
    elseif p >= p_c && p <= p_c_prime
        regime = 'CRITICAL';
    else
        regime = 'SOLID';
    end
    
    fprintf('Analyzing p = %.4f (%s)...\n', p, regime);
    
    % Calculate dynamic moduli
    [omega, G_storage, G_loss, delta] = calculate_dynamic_moduli(t, msd, temperature, particle_radius);
    
    if ~isempty(omega)
        % Calculate MSD power-law exponent for comparison
        valid_mask = isfinite(msd) & (msd > 0) & (t > 0);
        t_valid = t(valid_mask);
        msd_valid = msd(valid_mask);
        
        if length(t_valid) > 10
            log_t = log10(t_valid);
            log_msd = log10(msd_valid);
            n_points = max(10, round(length(log_t) * 0.5));
            t_fit = log_t(end-n_points+1:end);
            msd_fit = log_msd(end-n_points+1:end);
            p_fit = polyfit(t_fit, msd_fit, 1);
            alpha_msd = p_fit(1);
        else
            alpha_msd = NaN;
        end
        
        % Store results
        results.p = [results.p, p];
        results.regime{end+1} = regime;
        results.omega_range = [results.omega_range, [min(omega); max(omega)]];
        results.G_storage_range = [results.G_storage_range, [min(G_storage); max(G_storage)]];
        results.G_loss_range = [results.G_loss_range, [min(G_loss); max(G_loss)]];
        results.delta_range = [results.delta_range, [min(delta); max(delta)]];
        results.alpha_msd = [results.alpha_msd, alpha_msd];
        
        fprintf('  ω range: %.2e - %.2e rad/s\n', min(omega), max(omega));
        fprintf('  G'' range: %.2e - %.2e Pa\n', min(G_storage), max(G_storage));
        fprintf('  G" range: %.2e - %.2e Pa\n', min(G_loss), max(G_loss));
        fprintf('  δ range: %.1f° - %.1f°\n', min(delta), max(delta));
        fprintf('  MSD α: %.3f\n', alpha_msd);
        
        % Debug: Check first few values
        if i <= 3
            fprintf('  DEBUG - First G'' values: %.2e, %.2e, %.2e Pa\n', G_storage(1:3));
            fprintf('  DEBUG - First G" values: %.2e, %.2e, %.2e Pa\n', G_loss(1:3));
        end
    else
        fprintf('  Insufficient data for analysis\n');
    end
end

%% Create detailed visualization for selected p-values
fprintf('\n=== CREATING DETAILED VISUALIZATIONS ===\n');

% Select key p-values for detailed analysis
p_c_prime = 0.6884;
%key_p_values = [p_c_prime - 0.05, p_c_prime, p_c_prime + 0.05];
key_p_values = [1-p_c_prime, p_c_prime, 0.8];

% Find closest available p-values
available_p_values = [];
for target_p = key_p_values
    [~, closest_idx] = min(abs(sorted_p - target_p));
    available_p_values = [available_p_values, sorted_p(closest_idx)];
end

% Create detailed plots
for p = available_p_values
    p_idx = find(sorted_p == p);
    if isempty(p_idx)
        continue;
    end
    
    % Get MSD data
    msd = msd_data(:, sort_idx(p_idx));
    
    % % Determine regime
    % if p <= p_c_prime - 0.05
    %     regime = 'LIQUID';
    % elseif abs(p - p_c_prime) < 0.05
    %     regime = 'CRITICAL';
    % else
    %     regime = 'SOLID';
    % end
    % Determine regime
    if p <= p_c_prime - 0.05
        regime = 'LIQUID';
    elseif abs(p - p_c_prime) < 0.05
        regime = 'CRITICAL';
    else
        regime = 'SOLID';
    end

  % # Calculate weighted average α (weighted by R² quality)
  %   weighted_alpha = np.average(alpha_values, weights=r_squared_values)
  % 
  %   # Classify based on physical behavior
  %   if weighted_alpha > 0.8 and np.mean(r_squared_values) > 0.9:
  %       return 'liquid'
  %   elif 0.3 < weighted_alpha < 0.7 and np.mean(r_squared_values) > 0.8:
  %       return 'critical'
  %   elif weighted_alpha < 0.2 and np.mean(r_squared_values) > 0.8:
  %       return 'solid'
  %   else:
  %       # Fall back to geometric classification for unclear cases
  %       return classify_by_geometry(p_value)



    
    % Calculate dynamic moduli
    [omega, G_storage, G_loss, delta] = calculate_dynamic_moduli(t, msd, temperature, particle_radius);
    
    if isempty(omega)
        continue;
    end
    
    % Create figure
    figure('Position', [100, 100, 1400, 800]);
    
    % Plot 1: MSD vs time
    subplot(2, 3, 1);
    valid_mask = isfinite(msd) & (msd > 0) & (t > 0);
    t_valid = t(valid_mask);
    msd_valid = msd(valid_mask);
    loglog(t_valid, msd_valid, 'b-', 'LineWidth', 2);
    xlabel('Time t');
    ylabel('MSD');
    title(sprintf('MSD vs Time: p = %.4f (%s)', p, regime));
    grid on;
    
    % Plot 2: G'(ω) vs ω
    subplot(2, 3, 2);
    loglog(omega, G_storage, 'r-', 'LineWidth', 2);
    xlabel('Angular Frequency ω (rad/s)');
    ylabel('Storage Modulus G'' (Pa)');
    title('Storage Modulus vs Frequency');
    grid on;
    
    % Plot 3: G"(ω) vs ω
    subplot(2, 3, 3);
    loglog(omega, G_loss, 'g-', 'LineWidth', 2);
    xlabel('Angular Frequency ω (rad/s)');
    ylabel('Loss Modulus G" (Pa)');
    title('Loss Modulus vs Frequency');
    grid on;
    
    % Plot 4: δ(ω) vs ω
    subplot(2, 3, 4);
    semilogx(omega, delta, 'm-', 'LineWidth', 2);
    xlabel('Angular Frequency ω (rad/s)');
    ylabel('Loss Angle δ (degrees)');
    title('Loss Angle vs Frequency');
    grid on;
    ylim([0, 90]);
    
    % Plot 5: G" vs G' (Cole-Cole plot)
    subplot(2, 3, 5);
    plot(G_storage, G_loss, 'k-', 'LineWidth', 2);
    xlabel('Storage Modulus G'' (Pa)');
    ylabel('Loss Modulus G" (Pa)');
    title('Cole-Cole Plot');
    grid on;
    
    % Plot 6: |G*| vs ω
    subplot(2, 3, 6);
    G_magnitude = sqrt(G_storage.^2 + G_loss.^2);
    loglog(omega, G_magnitude, 'b-', 'LineWidth', 2);
    xlabel('Angular Frequency ω (rad/s)');
    ylabel('|G*| (Pa)');
    title('Complex Modulus Magnitude vs Frequency');
    grid on;
    
    sgtitle(sprintf('Dynamic Mechanical Analysis: p = %.4f (%s)', p, regime));
    
    % Save figure
    filename = sprintf('dynamic_mechanical_p%.4f.png', p);
    saveas(gcf, filename);
    fprintf('Saved: %s\n', filename);
    
    %close(gcf);
end

%% Create summary plots
fprintf('\n=== CREATING SUMMARY PLOTS ===\n');

if ~isempty(results.p)
    % Create summary figure
    figure('Position', [200, 200, 1400, 900]);
    
    % Ensure regime data is in cell array format
    regime_data = results.regime;
    
    % Convert to cell array if needed
    if ~iscell(regime_data)
        regime_data = cellstr(regime_data);
    end
    
    % Plot 1: δ vs p with transition region annotation
    subplot(2, 3, 1);
    colors = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, {'blue', 'red', 'green'});
    unique_regimes = unique(regime_data);
    
    % Calculate average δ for each p-value
    delta_avg = mean(results.delta_range, 1)';
    
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        scatter(results.p(mask), delta_avg(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    
    % Add transition region annotation
    p_c = 0.3116;      % Gel-point of occupied sites (lower critical point)
    p_c_prime = 0.6884; % Gel-point of unoccupied sites (upper critical point)
    
    % Shade critical region
    ylim_current = ylim;
    patch([p_c, p_c_prime, p_c_prime, p_c], ...
          [ylim_current(1), ylim_current(1), ylim_current(2), ylim_current(2)], ...
          'red', 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'DisplayName', 'Critical Region');
    
    % Add vertical lines for critical points
    xline(p_c, 'b--', 'LineWidth', 2, 'DisplayName', sprintf('p_c = %.4f', p_c));
    xline(p_c_prime, 'g--', 'LineWidth', 2, 'DisplayName', sprintf('p_c'' = %.4f', p_c_prime));
    
    xlabel('p');
    ylabel('Average Loss Angle δ (degrees)');
    title('Loss Angle vs p with Critical Region');
    legend('Location', 'best');
    grid on;
    ylim([0, 90]);
    
    % Plot 2: G' vs p (log-log)
    subplot(2, 3, 2);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        % Extract the range data correctly for masked indices
        G_storage_ranges = results.G_storage_range(:, mask);
        G_storage_avg = mean(G_storage_ranges, 1)';  % Average across frequency range for each p
        scatter(results.p(mask), G_storage_avg, 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('Average G'' (Pa)');
    title('Storage Modulus vs p');
    legend('Location', 'best');
    set(gca, 'YScale', 'log');
    grid on;
    
    % Plot 3: G" vs p (log-log)
    subplot(2, 3, 3);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        % Extract the range data correctly for masked indices
        G_loss_ranges = results.G_loss_range(:, mask);
        G_loss_avg = mean(G_loss_ranges, 1)';  % Average across frequency range for each p
        scatter(results.p(mask), G_loss_avg, 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('Average G" (Pa)');
    title('Loss Modulus vs p');
    legend('Location', 'best');
    set(gca, 'YScale', 'log');
    grid on;
    
    % Plot 4: α vs p
    subplot(2, 3, 4);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        scatter(results.p(mask), results.alpha_msd(mask), 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('MSD Power Law Exponent α');
    title('MSD α vs p');
    legend('Location', 'best');
    grid on;
    
    % Plot 5: G"/G' vs p
    subplot(2, 3, 5);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        % Extract the range data correctly for masked indices
        G_storage_ranges = results.G_storage_range(:, mask);
        G_loss_ranges = results.G_loss_range(:, mask);
        G_storage_avg = mean(G_storage_ranges, 1)';  % Average across frequency range for each p
        G_loss_avg = mean(G_loss_ranges, 1)';  % Average across frequency range for each p
        G_ratio = G_loss_avg ./ G_storage_avg;
        scatter(results.p(mask), G_ratio, 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('G"/G'' Ratio');
    title('Loss/Storage Modulus Ratio vs p');
    legend('Location', 'best');
    grid on;
    
    % Plot 6: Frequency range vs p
    subplot(2, 3, 6);
    for i = 1:length(unique_regimes)
        regime = unique_regimes{i};
        mask = strcmp(regime_data, regime);
        % Extract the range data correctly for masked indices
        omega_ranges = results.omega_range(:, mask);
        omega_span = omega_ranges(2, :) - omega_ranges(1, :);  % max - min
        scatter(results.p(mask), omega_span', 50, colors(regime), 'filled', 'DisplayName', regime);
        hold on;
    end
    xlabel('p');
    ylabel('Frequency Range Span (rad/s)');
    title('Frequency Range vs p');
    legend('Location', 'best');
    set(gca, 'YScale', 'log');
    grid on;
    
    sgtitle('Dynamic Mechanical Analysis Summary');
    
    % Save summary plot
    %saveas(gcf, 'dynamic_mechanical_summary.png');
    %fprintf('Summary plot saved to: dynamic_mechanical_summary.png\n');
end

%% Save results
fprintf('\n=== SAVING RESULTS ===\n');

if ~isempty(results.p)
    % Ensure all arrays are column vectors and have the same length
    n_results = length(results.p);
    
    % Convert to column vectors and ensure consistent dimensions
    p_col = results.p(:);
    regime_col = results.regime(:);
    omega_min_col = results.omega_range(1, :)';
    omega_max_col = results.omega_range(2, :)';
    G_storage_min_col = results.G_storage_range(1, :)';
    G_storage_max_col = results.G_storage_range(2, :)';
    G_loss_min_col = results.G_loss_range(1, :)';
    G_loss_max_col = results.G_loss_range(2, :)';
    delta_min_col = results.delta_range(1, :)';
    delta_max_col = results.delta_range(2, :)';
    alpha_msd_col = results.alpha_msd(:);
    
    % Create results table
    results_table = table(p_col, regime_col, ...
                         omega_min_col, omega_max_col, ...
                         G_storage_min_col, G_storage_max_col, ...
                         G_loss_min_col, G_loss_max_col, ...
                         delta_min_col, delta_max_col, ...
                         alpha_msd_col, ...
                         'VariableNames', {'p', 'regime', 'omega_min', 'omega_max', ...
                         'G_storage_min', 'G_storage_max', 'G_loss_min', 'G_loss_max', ...
                         'delta_min', 'delta_max', 'alpha_msd'});
    
    % Save to file
    %writetable(results_table, 'dynamic_mechanical_results.csv');
    fprintf('Results saved to: dynamic_mechanical_results.csv\n');
    
    %% Display summary
    fprintf('\n=== SUMMARY ===\n');
    fprintf('Total p-values analyzed: %d\n', length(sorted_p));
    fprintf('Successful analyses: %d\n', height(results_table));
    
    fprintf('\nLoss angle δ statistics:\n');
    delta_avg = mean(results.delta_range, 1)';  % Changed to row-wise mean
    fprintf('  Mean: %.1f°\n', mean(delta_avg));
    fprintf('  Median: %.1f°\n', median(delta_avg));
    fprintf('  Range: %.1f° - %.1f°\n', min(delta_avg), max(delta_avg));
    
    fprintf('\nStorage modulus G'' statistics:\n');
    G_storage_avg = mean(results.G_storage_range, 1)';  % Changed to row-wise mean
    fprintf('  Mean: %.2e Pa\n', mean(G_storage_avg));
    fprintf('  Median: %.2e Pa\n', median(G_storage_avg));
    fprintf('  Range: %.2e - %.2e Pa\n', min(G_storage_avg), max(G_storage_avg));
    
    fprintf('\nLoss modulus G" statistics:\n');
    G_loss_avg = mean(results.G_loss_range, 1)';  % Changed to row-wise mean
    fprintf('  Mean: %.2e Pa\n', mean(G_loss_avg));
    fprintf('  Median: %.2e Pa\n', median(G_loss_avg));
    fprintf('  Range: %.2e - %.2e Pa\n', min(G_loss_avg), max(G_loss_avg));
else
    fprintf('No successful analyses found.\n');
end

fprintf('\nAnalysis complete!\n'); 

%% Dynamic Mechanical Analysis Functions

function [omega, G_storage, G_loss, delta] = calculate_dynamic_moduli(t, msd, temperature, particle_radius)
    % Calculate dynamic moduli using Generalized Stokes-Einstein Relation (GSER)
    % Inputs:
    %   t: time array
    %   msd: mean squared displacement
    %   temperature: temperature in Kelvin
    %   particle_radius: particle radius in meters
    
    % Physical constants
    kB = 1.380649e-23;  % Boltzmann constant (J/K)
    
    % Filter valid data
    valid_mask = isfinite(msd) & (msd > 0) & (t > 0);
    t_valid = t(valid_mask);
    msd_valid = msd(valid_mask);
    
    if length(t_valid) < 10
        omega = [];
        G_storage = [];
        G_loss = [];
        delta = [];
        return;
    end
    
    % Calculate frequency domain (angular frequency)
    % Use more reasonable frequency range based on the paper's methodology
    % Convert dimensionless time to physical time first
    l = 0.243e-6;       % Lattice constant (0.243 μm)
    eta = 1.2e-3;       % Viscosity (1.2×10⁻³ Pa·s, blood plasma)
    R = l/2;            % Probe particle radius (l/2)
    d = 3;              % Dimension
    D = kB * temperature / (2 * d * eta * R);  % Diffusion coefficient
    zeta_calculated = l^2 / (2 * D * d);  % Calculated time constant
    
    % Use the paper's exact value of 6.4 ms
    zeta_base = 6.4e-3;  % 6.4 ms from paper
    
    % No scaling applied after t*=0 fix
    zeta = zeta_base;
    
    % Convert dimensionless time to physical time
    t_physical = t_valid * zeta;
    
    % Use frequencies corresponding to times from 0.1×t_min to t_max
    omega_min = 2*pi / (t_physical(end));
    omega_max = 2*pi / (0.1 * t_physical(1));
    
    % Ensure reasonable frequency range (0.1 to 100 rad/s)
    omega_min = max(0.1, omega_min);
    omega_max = min(100, omega_max);
    
    omega = logspace(log10(omega_min), log10(omega_max), 50);
    
    % Initialize arrays
    G_storage = zeros(size(omega));
    G_loss = zeros(size(omega));
    delta = zeros(size(omega));
    
    % Calculate complex modulus for each frequency
    for i = 1:length(omega)
        w = omega(i);
        
        % Calculate G*(ω) using GSER
        G_complex = calculate_G_complex(t_valid, msd_valid, w, temperature, particle_radius);
        
        % Extract real and imaginary parts
        G_storage(i) = real(G_complex);
        G_loss(i) = imag(G_complex);
        
        % Calculate loss angle δ(ω) = arctan(G''/G')
        if G_storage(i) > 0
            delta(i) = atan2(G_loss(i), G_storage(i)) * 180/pi;  % Convert to degrees
        else
            delta(i) = 90;  % Default to 90° if G' is zero
        end
    end
end

function G_complex = calculate_G_complex(t, msd, omega, temperature, particle_radius)
    % Calculate complex modulus G*(ω) using Generalized Stokes-Einstein Relation (GSER)
    % Following the paper's methodology with proper unit conversion
    
    % Physical parameters from the paper
    kB = 1.380649e-23;  % Boltzmann constant (J/K)
    T = 293;            % Temperature (20°C = 293K)
    eta = 1.2e-3;       % Viscosity (1.2×10⁻³ Pa·s, blood plasma)
    l = 0.243e-6;       % Lattice constant (0.243 μm)
    R = l/2;            % Probe particle radius (l/2)
    
    % Calculate time constant ζ from Stokes-Einstein relation
    % ζ = l²/(2Dd) where D = kBT/(2dηR) and d=3 for 3D
    % This is the mean time for MSD = l² in a Newtonian liquid
    d = 3;  % Dimension
    D = kB * T / (2 * d * eta * R);  % Diffusion coefficient
    zeta_calculated = l^2 / (2 * D * d);  % Calculated time constant
    
    % Use the paper's exact value of 6.4 ms
    zeta_base = 6.4e-3;  % 6.4 ms from paper
    
    % No scaling applied after t*=0 fix
    zeta = zeta_base;
    
    % Convert dimensionless units to physical units
    % τ = ζτ* and r² = l²r*²
    t_physical = t * zeta;  % Convert dimensionless time to seconds
    msd_physical = msd * (l^2);  % Convert dimensionless MSD to m²
    
    % Find power-law exponent α from MSD data
    log_t = log10(t_physical);
    log_msd = log10(msd_physical);
    
    if length(log_t) > 10
        % Use last 50% of data for power-law fit
        n_points = max(10, round(length(log_t) * 0.5));
        t_fit = log_t(end-n_points+1:end);
        msd_fit = log_msd(end-n_points+1:end);
        
        % Fit power law: log(MSD) = α * log(t) + b
        p_fit = polyfit(t_fit, msd_fit, 1);
        alpha = p_fit(1);
        b = p_fit(2);
        
        % Calculate R²
        msd_pred = alpha * t_fit + b;
        ss_res = sum((msd_fit - msd_pred).^2);
        ss_tot = sum((msd_fit - mean(msd_fit)).^2);
        r2 = 1 - (ss_res / ss_tot);
        
        % Ensure α is reasonable (0.01 to 2.0)
        alpha = max(0.01, min(2.0, alpha));
    else
        alpha = 1.0; % Default to normal diffusion
        r2 = 0.8;
    end
    
    % Calculate MSD at the time scale corresponding to ω
    % Use interpolation instead of extrapolation to avoid huge values
    tau = 1/omega;  % Time scale corresponding to frequency
    
    if tau <= t_physical(end)
        % Interpolate MSD at this time scale
        msd_tau = interp1(t_physical, msd_physical, tau, 'linear', 'extrap');
    else
        % If tau is beyond our data range, use the last MSD value
        msd_tau = msd_physical(end);
    end
    
    % Ensure MSD is reasonable (not too large or small)
    msd_tau = max(msd_physical(1), min(msd_physical(end), msd_tau));
    
    % Calculate Gamma function Γ(1 + α(ω))
    gamma_euler = 0.5772156649;
    if alpha < 0.1
        gamma_factor = 1 + alpha * gamma_euler;
    else
        gamma_factor = gamma(1 + alpha);
    end
    
    % Calculate complex modulus using GSER from paper
    % |G*(ω)| = kBT / (π⟨r²(τ)⟩Γ(1 + α(ω)))
    G_magnitude = kB * T / (pi * msd_tau * gamma_factor);
    
    % Calculate G'(ω) and G"(ω) from magnitude and phase
    % G'(ω) = |G*(ω)|cos(πα(ω)/2)
    % G"(ω) = |G*(ω)|sin(πα(ω)/2)
    G_storage = G_magnitude * cos(pi * alpha / 2);
    G_loss = G_magnitude * sin(pi * alpha / 2);
    
    G_complex = G_storage + 1i * G_loss;
    
    % Debug output for first calculation
    if omega == omega(1)
        fprintf('Debug GSER calculation (paper ζ):\n');
        fprintf('  Lattice constant l: %.2e m\n', l);
        fprintf('  ζ calculated: %.2f ms\n', zeta_calculated*1000);
        fprintf('  ζ from paper: %.2f ms\n', zeta_base*1000);
        fprintf('  Time constant ζ: %.2e s\n', zeta);
        fprintf('  Diffusion coefficient D: %.2e m²/s\n', D);
        fprintf('  MSD (dimensionless): %.2e\n', msd(1));
        fprintf('  MSD (physical): %.2e m²\n', msd_physical(1));
        fprintf('  τ = 1/ω: %.2e s\n', tau);
        fprintf('  MSD(τ) (physical): %.2e m²\n', msd_tau);
        fprintf('  α: %.3f (R² = %.3f)\n', alpha, r2);
        fprintf('  Γ(1+α): %.3f\n', gamma_factor);
        fprintf('  ω: %.2e rad/s\n', omega);
        fprintf('  |G*|: %.2e Pa\n', G_magnitude);
        fprintf('  G'': %.2e Pa\n', G_storage);
        fprintf('  G": %.2e Pa\n', G_loss);
        
        % Additional scaling debug
        fprintf('  Scaling factors:\n');
        fprintf('    l² = %.2e m²\n', l^2);
        fprintf('    ζ = %.2e s\n', zeta);
        fprintf('    kBT = %.2e J\n', kB * T);
        fprintf('    π = %.2f\n', pi);
    end
end