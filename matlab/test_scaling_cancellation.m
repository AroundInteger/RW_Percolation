%% Test Scaling Cancellation
% This script tests whether ζ factors cancel out in the τ to ω conversion

clear; clc;

%% Physical parameters
kB = 1.380649e-23;  % Boltzmann constant (J/K)
T = 293;            % Temperature (20°C = 293K)
l = 0.243e-6;       % Lattice constant (0.243 μm)
zeta = 6.4e-3;      % Time constant (6.4 ms)

%% Test different scaling factors
scaling_factors = [1, 10, 100, 1000, 10000];

fprintf('=== TESTING ζ CANCELLATION ===\n');
fprintf('%-12s %-12s %-12s %-12s %-12s\n', 'Scale', 'ζ (s)', 'τ (s)', 'ω (rad/s)', 'G* (Pa)');
fprintf('%-12s %-12s %-12s %-12s %-12s\n', '-----', '-----', '-----', '-----', '-----');

% Use a simple test case
msd_lattice = 1.0;  % Dimensionless MSD value
tau_star = 100;     % Dimensionless time
alpha = 1.0;        % Liquid regime

for i = 1:length(scaling_factors)
    scale = scaling_factors(i);
    zeta_scaled = zeta * scale;
    
    % Convert to physical units
    tau = zeta_scaled * tau_star;
    msd_physical = msd_lattice * (l^2);
    omega = 1/tau;
    
    % Calculate G* using GSER
    gamma_factor = gamma(1 + alpha);
    G_magnitude = kB * T / (pi * msd_physical * gamma_factor);
    
    fprintf('%-12.0e %-12.2e %-12.2e %-12.2e %-12.2e\n', ...
            scale, zeta_scaled, tau, omega, G_magnitude);
end

fprintf('\n=== ANALYSIS ===\n');
fprintf('If ζ cancels out, G* should be the same for all scaling factors.\n');
fprintf('If G* changes with scaling, there is no cancellation.\n');

%% Test with actual MSD data
fprintf('\n=== TESTING WITH ACTUAL MSD DATA ===\n');

% Load a small sample of MSD data
data = readtable('p_output_NEW34.csv');
msd_sample = data.MSD_0(1:10);  % First 10 values
t_sample = (0:9)';  % Time steps

fprintf('MSD sample (first 10 values):\n');
for i = 1:length(msd_sample)
    fprintf('t*=%d: MSD*=%f\n', t_sample(i), msd_sample(i));
end

% Test interpolation at different time scales
omega_test = 1.0;  % rad/s
fprintf('\nTesting MSD interpolation at ω = %.1f rad/s:\n', omega_test);

for i = 1:length(scaling_factors)
    scale = scaling_factors(i);
    zeta_scaled = zeta * scale;
    
    % Convert to physical units
    t_physical = t_sample * zeta_scaled;
    msd_physical = msd_sample * (l^2);
    
    % Interpolate MSD at τ = 1/ω
    tau_test = 1/omega_test;
    
    if tau_test <= t_physical(end)
        msd_tau = interp1(t_physical, msd_physical, tau_test, 'linear', 'extrap');
    else
        msd_tau = msd_physical(end);
    end
    
    % Calculate G*
    gamma_factor = gamma(1 + alpha);
    G_magnitude = kB * T / (pi * msd_tau * gamma_factor);
    
    fprintf('Scale=%.0e: τ=%.2e s, MSD(τ)=%.2e m², G*=%.2e Pa\n', ...
            scale, tau_test, msd_tau, G_magnitude);
end

fprintf('\n=== CONCLUSION ===\n');
fprintf('This test shows whether the ζ scaling factors cancel out\n');
fprintf('in the τ to ω conversion and MSD interpolation.\n'); 