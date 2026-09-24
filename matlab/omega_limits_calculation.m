%% Back-of-the-Envelope Calculation: Limits on ω
% This script calculates the frequency limits based on our MSD data range

clear; clc;

%% Physical parameters from paper
kB = 1.380649e-23;  % Boltzmann constant (J/K)
T = 293;            % Temperature (20°C = 293K)
l = 0.243e-6;       % Lattice constant (0.243 μm)
zeta = 6.4e-3;      % Time constant (6.4 ms)

%% MSD data range
fprintf('=== MSD DATA RANGE ===\n');
fprintf('Loading MSD data to determine time range...\n');

data = readtable('p_output_NEW34.csv');
msd_sample = data.MSD_0;  % Use p=0 data
t_star = (1:(length(msd_sample)))';  % Start from t* = 1, not 0
msd_sample = msd_sample(1:end);  % Exclude t* = 0

fprintf('MSD data points: %d\n', length(msd_sample));
fprintf('Time range: t* = %d to %d steps\n', t_star(1), t_star(end));
fprintf('MSD range: %.3f to %.3f (dimensionless)\n', min(msd_sample), max(msd_sample));

%% Convert to physical units
fprintf('\n=== PHYSICAL TIME RANGE ===\n');
t_min_physical = t_star(1) * zeta;  % Minimum physical time
t_max_physical = t_star(end) * zeta;  % Maximum physical time

fprintf('Physical time range:\n');
fprintf('  t_min = %.2e s (%.2f ms)\n', t_min_physical, t_min_physical*1000);
fprintf('  t_max = %.2e s (%.2f s)\n', t_max_physical, t_max_physical);

%% Calculate frequency limits
fprintf('\n=== FREQUENCY LIMITS ===\n');
omega_min = 1 / t_max_physical;  % Minimum frequency
omega_max = 1 / t_min_physical;  % Maximum frequency

fprintf('Frequency limits:\n');
fprintf('  ω_min = %.2e rad/s (%.2e Hz)\n', omega_min, omega_min/(2*pi));
fprintf('  ω_max = %.2e rad/s (%.2e Hz)\n', omega_max, omega_max/(2*pi));

%% Test different scaling factors
fprintf('\n=== SCALING ANALYSIS ===\n');
scaling_factors = [1, 10, 100, 1000, 10000, 100000, 1e6, 1e7, 1e8, 1e9, 1e10];

fprintf('%-12s %-15s %-15s %-15s %-15s\n', 'Scale', 't_min (s)', 't_max (s)', 'ω_min (rad/s)', 'ω_max (rad/s)');
fprintf('%-12s %-15s %-15s %-15s %-15s\n', '-----', '---------', '---------', '------------', '------------');

for i = 1:length(scaling_factors)
    scale = scaling_factors(i);
    zeta_scaled = zeta * scale;
    
    t_min_scaled = t_star(1) * zeta_scaled;
    t_max_scaled = t_star(end) * zeta_scaled;
    omega_min_scaled = 2*pi / t_max_scaled;
    omega_max_scaled = 2*pi / t_min_scaled;
    
    fprintf('%-12.0e %-15.2e %-15.2e %-15.2e %-15.2e\n', ...
            scale, t_min_scaled, t_max_scaled, omega_min_scaled, omega_max_scaled);
end

%% Recommended frequency range for rheology
fprintf('\n=== RECOMMENDED FREQUENCY RANGE ===\n');
fprintf('Typical rheological measurements:\n');
fprintf('  ω ≈ 0.1 to 100 rad/s\n');
fprintf('  f ≈ 0.016 to 16 Hz\n');

% Find scaling factor that gives reasonable frequency range
target_omega_min = 0.1;  % rad/s
target_omega_max = 100;  % rad/s

fprintf('\nTo achieve ω = %.1f to %.0f rad/s:\n', target_omega_min, target_omega_max);

for i = 1:length(scaling_factors)
    scale = scaling_factors(i);
    zeta_scaled = zeta * scale;
    
    t_min_scaled = t_star(1) * zeta_scaled;
    t_max_scaled = t_star(end) * zeta_scaled;
    omega_min_scaled = 2*pi / t_max_scaled;
    omega_max_scaled = 2*pi / t_min_scaled;
    
    if omega_min_scaled <= target_omega_min && omega_max_scaled >= target_omega_max
        fprintf('  Scale = %.0e: ω = %.2e to %.2e rad/s ✓\n', ...
                scale, omega_min_scaled, omega_max_scaled);
    else
        fprintf('  Scale = %.0e: ω = %.2e to %.2e rad/s ✗\n', ...
                scale, omega_min_scaled, omega_max_scaled);
    end
end

%% MSD interpolation limits
fprintf('\n=== MSD INTERPOLATION LIMITS ===\n');
fprintf('For reliable interpolation, τ should be within our data range.\n');

% Test interpolation at ω = 1 rad/s
omega_test = 1.0;  % rad/s
fprintf('\nTesting MSD interpolation at ω = %.1f rad/s:\n', omega_test);

fprintf('%-12s %-15s %-15s %-15s\n', 'Scale', 'τ = 1/ω (s)', 'In range?', 'MSD(τ) (m²)');
fprintf('%-12s %-15s %-15s %-15s\n', '-----', '----------', '---------', '----------');

for i = 1%:length(scaling_factors)
    scale = scaling_factors(i);
    zeta_scaled = zeta * scale;
    
    tau_test = 1/omega_test;
    t_min_scaled = t_star(1) * zeta_scaled;
    t_max_scaled = t_star(end) * zeta_scaled;
    
    in_range = (tau_test >= t_min_scaled && tau_test <= t_max_scaled);
    
    % Interpolate MSD
    t_physical = t_star * zeta_scaled;
    msd_physical = msd_sample * (l^2);
    
    if in_range
        msd_tau = interp1(t_physical, msd_physical, tau_test, 'linear');
    else
        msd_tau = msd_physical(end);  % Use last value if out of range
    end
    
    if in_range
        range_str = 'Yes';
    else
        range_str = 'No';
    end
    fprintf('%-12.0e %-15.2e %-15s %-15.2e\n', ...
            scale, tau_test, range_str, msd_tau);
end

fprintf('\n=== CONCLUSION ===\n');
fprintf('This analysis shows the frequency limits based on our MSD data range\n');
fprintf('and how scaling affects the interpolation reliability.\n'); 