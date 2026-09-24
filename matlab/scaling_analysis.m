%% Scaling Analysis: p = [0, p_c', 1]
% This script analyzes the scaling issue by focusing on three key p-values
% where we have clear theoretical expectations for α and G* values

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
        % Extract p-value from column name (e.g., MSD_0.6884 -> 0.6884)
        p_str = extractAfter(col_name, 'MSD_');
        p_val = str2double(p_str);
        if ~isnan(p_val)
            p_values = [p_values, p_val];
            msd_data = [msd_data, data.(col_name)];
        end
    end
end

% Create time array
t = (1:height(data))';

fprintf('Loaded %d p-values\n', length(p_values));
fprintf('P-value range: %.4f to %.4f\n', min(p_values), max(p_values));

%% Focus on key p-values: [0, p_c', 1]
p_c_prime = 0.6884;  % Upper critical point

% Find closest available p-values
target_p = [0, p_c_prime, 1];
selected_p = [];
selected_msd = [];
selected_indices = [];

for i = 1:length(target_p)
    [~, idx] = min(abs(p_values - target_p(i)));
    selected_p(i) = p_values(idx);
    selected_msd(:, i) = msd_data(:, idx);
    selected_indices(i) = idx;
    fprintf('Target p = %.4f, closest available p = %.4f\n', target_p(i), selected_p(i));
end

%% Physical parameters from paper
kB = 1.380649e-23;  % Boltzmann constant (J/K)
T = 293;            % Temperature (20°C = 293K)
eta = 1.2e-3;       % Viscosity (1.2×10⁻³ Pa·s, blood plasma)
l = 0.243e-6;       % Lattice constant (0.243 μm)
R = l/2;            % Probe particle radius (l/2)
d = 3;              % Dimension

% Calculate diffusion coefficient and time constant
D = kB * T / (2 * d * eta * R);  % Diffusion coefficient
zeta_calculated = l^2 / (2 * D * d);  % Calculated time constant
zeta_paper = 6.4e-3;  % Paper's value

fprintf('\n=== PHYSICAL PARAMETERS ===\n');
fprintf('Lattice constant l: %.2e m\n', l);
fprintf('Particle radius R: %.2e m\n', R);
fprintf('Temperature T: %.0f K\n', T);
fprintf('Viscosity η: %.2e Pa·s\n', eta);
fprintf('Diffusion coefficient D: %.2e m²/s\n', D);
fprintf('ζ calculated: %.2f ms\n', zeta_calculated*1000);
fprintf('ζ from paper: %.2f ms\n', zeta_paper*1000);
fprintf('Ratio (paper/calculated): %.2f\n', zeta_paper/zeta_calculated);

%% Analyze each p-value with theoretical α
fprintf('\n=== SCALING ANALYSIS (THEORETICAL α) ===\n');

for i = 1:length(selected_p)
    p = selected_p(i);
    msd = selected_msd(:, i);
    
    fprintf('\n--- p = %.4f ---\n', p);
    
    % Use theoretical α values
    if p == 0
        regime = 'LIQUID';
        alpha_theoretical = 1.0;
        delta_expected = 90;  % degrees
    elseif abs(p - p_c_prime) < 0.01
        regime = 'CRITICAL';
        alpha_theoretical = 0.53;
        delta_expected = 45;  % degrees
    else
        regime = 'SOLID';
        alpha_theoretical = 0.0;
        delta_expected = 0;   % degrees
    end
    
    fprintf('Regime: %s\n', regime);
    fprintf('Theoretical α: %.2f\n', alpha_theoretical);
    fprintf('Expected δ: %.0f°\n', delta_expected);
    
    % Analyze MSD data
    valid_mask = isfinite(msd) & (msd > 0) & (t > 0);
    t_valid = t(valid_mask);
    msd_valid = msd(valid_mask);
    
    if length(t_valid) < 10
        fprintf('Insufficient data for analysis\n');
        continue;
    end
    
    % Test different scaling factors
    scaling_factors = [1, 10, 100, 1000, 10000, 100000, 1e6, 1e7, 1e8, 1e9, 1e10];
    
    fprintf('\nScaling analysis:\n');
    fprintf('%-12s %-12s %-12s %-12s %-12s %-12s\n', 'Scale', 'ζ (s)', 'G* (Pa)', 'G'' (Pa)', 'G" (Pa)', 'δ (°)');
    fprintf('%-12s %-12s %-12s %-12s %-12s %-12s\n', '-----', '-----', '-----', '-----', '-----', '-----');
    
    for j = 1:length(scaling_factors)
        scale = scaling_factors(j);
        zeta = zeta_paper * scale;
        
        % Convert to physical units
        t_physical = t_valid * zeta;
        msd_physical = msd_valid * (l^2);
        
        % Use a representative frequency (ω = 1 rad/s)
        omega_test = 1.0;  % rad/s
        tau_test = 1/omega_test;
        
        % Interpolate MSD at this time scale
        if tau_test <= t_physical(end)
            msd_tau = interp1(t_physical, msd_physical, tau_test, 'linear', 'extrap');
        else
            msd_tau = msd_physical(end);
        end
        
        % Ensure MSD is reasonable
        msd_tau = max(msd_physical(1), min(msd_physical(end), msd_tau));
        
        % Calculate G* using GSER with theoretical α
        gamma_factor = gamma(1 + alpha_theoretical);
        G_magnitude = kB * T / (pi * msd_tau * gamma_factor);
        G_storage = G_magnitude * cos(pi * alpha_theoretical / 2);
        G_loss = G_magnitude * sin(pi * alpha_theoretical / 2);
        
        % Calculate loss angle
        if G_storage > 0
            delta = atan2(G_loss, G_storage) * 180/pi;
        else
            delta = 90;
        end
        
        fprintf('%-12.0e %-12.2e %-12.2e %-12.2e %-12.2e %-12.1f\n', ...
                scale, zeta, G_magnitude, G_storage, G_loss, delta);
    end
    
    % Find scaling factor that gives reasonable G* values (10⁻³ to 10² Pa)
    fprintf('\nRecommended scaling analysis:\n');
    fprintf('For G* ≈ 1 Pa (typical rheological measurement):\n');
    
    % Calculate required scaling factor
    target_G = 1.0;  % Pa
    msd_representative = msd_physical(round(end/2));  % Use middle of data
    gamma_factor = gamma(1 + alpha_theoretical);
    required_zeta = (kB * T) / (pi * msd_representative * gamma_factor * target_G);
    required_scale = required_zeta / zeta_paper;
    
    fprintf('Required ζ: %.2e s\n', required_zeta);
    fprintf('Required scale factor: %.2e\n', required_scale);
    
    % Check if this gives reasonable time scales
    t_max_physical = t_valid(end) * required_zeta;
    fprintf('Max physical time: %.2e s (%.2f hours)\n', t_max_physical, t_max_physical/3600);
end

fprintf('\n=== ANALYSIS COMPLETE ===\n'); 