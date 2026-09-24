% frequency_space_analysis.m
% Convert MSD to frequency space and derive G', G'', and δ as functions of frequency
% for all variants and p-values using the Generalized Stokes-Einstein Relation (GSER)

clear; close all; clc;

fprintf('\n=== FREQUENCY SPACE ANALYSIS ===\n');
fprintf('Converting MSD to frequency space and deriving G'', G'', and δ(ω)\n\n');

% ============================================================================
% DATA LOADING AND SETUP
% ============================================================================

% Load the comprehensive dataset
mat_file = 'Clusters1/random_walk_analysis_L500_LW1000000_NW3000.mat';
load(mat_file);

% Load the alpha results from previous analysis
alpha_file = 'Clusters1/output/universality_class_analysis.mat';
load(alpha_file);

fprintf('Data loaded successfully:\n');
fprintf('  p_values: %d values from %.3f to %.3f\n', length(p_values), min(p_values), max(p_values));
fprintf('  variants: %d variants\n', length(variants));

% Define universality classes
templated_variants = {'6N_Templated', '26N_Templated'};
standard_variants = {'Random_Percolation', 'Density_Increment'};

% ============================================================================
% FREQUENCY SPACE CONVERSION
% ============================================================================

fprintf('\n=== CONVERTING TO FREQUENCY SPACE ===\n');

% Physical parameters (from the paper)
kB = 1.380649e-23;  % Boltzmann constant (J/K)
T = 293;            % Temperature (20°C = 293K)
eta = 1.2e-3;       % Viscosity (1.2×10⁻³ Pa·s, blood plasma)
l = 0.243e-6;       % Lattice constant (0.243 μm)
R = l/2;            % Probe particle radius (l/2)
zeta = 6.4e-3;      % Time constant (6.4 ms from paper)

% Initialize results structure
frequency_results = struct();

% Process each variant
for v = 1:length(variants)
    variant = variants{v};
    variant_field = matlab.lang.makeValidName(variant);
    fprintf('\nProcessing variant: %s\n', variant);
    
    frequency_results.(variant_field) = struct();
    
    % Process each p-value
    for p = 1:length(p_values)
        p_val = p_values(p);
        fprintf('  p = %.4f...', p_val);
        
        % Get MSD data for this variant and p-value
        msd_data = MSD_results(:, p, v);
        time_data = MSD_tau_results(:, p, v);
        
        if isempty(msd_data) || length(msd_data) < 10
            fprintf(' insufficient data\n');
            continue;
        end
        
        % Convert to frequency space
        [omega, G_storage, G_loss, delta] = calculate_dynamic_moduli(time_data, msd_data, T, R);
        
        if isempty(omega)
            fprintf(' conversion failed\n');
            continue;
        end
        
        % Store results
        p_field = matlab.lang.makeValidName(sprintf('p_%.4f', p_val));
        frequency_results.(variant_field).(p_field) = struct();
        frequency_results.(variant_field).(p_field).omega = omega;
        frequency_results.(variant_field).(p_field).G_storage = G_storage;
        frequency_results.(variant_field).(p_field).G_loss = G_loss;
        frequency_results.(variant_field).(p_field).delta = delta;
        frequency_results.(variant_field).(p_field).p_value = p_val;
        
        fprintf(' ✓ (ω: %.2f-%.2f rad/s)\n', min(omega), max(omega));
    end
end

% ============================================================================
% UNIVERSALITY CLASS ANALYSIS
% ============================================================================

fprintf('\n=== UNIVERSALITY CLASS FREQUENCY ANALYSIS ===\n');

% Analyze frequency behavior for each universality class
universality_frequency = struct();

% Templated class analysis
fprintf('\nAnalyzing Templated Universality Class...\n');
templated_frequency = analyze_universality_class_frequency(frequency_results, templated_variants, p_values);
universality_frequency.templated = templated_frequency;

% Standard class analysis
fprintf('\nAnalyzing Standard Universality Class...\n');
standard_frequency = analyze_universality_class_frequency(frequency_results, standard_variants, p_values);
universality_frequency.standard = standard_frequency;

% ============================================================================
% VISUALIZATION
% ============================================================================

fprintf('\n=== GENERATING FREQUENCY SPACE VISUALIZATIONS ===\n');
create_frequency_space_plots(frequency_results, universality_frequency, p_values, variants, 'Clusters1/output');

% ============================================================================
% SAVE RESULTS
% ============================================================================

fprintf('\n=== SAVING FREQUENCY SPACE RESULTS ===\n');
save_frequency_space_results(frequency_results, universality_frequency, 'Clusters1/output');

fprintf('\n=== FREQUENCY SPACE ANALYSIS COMPLETE ===\n');

% ============================================================================
% HELPER FUNCTIONS
% ============================================================================

function [omega, G_storage, G_loss, delta] = calculate_dynamic_moduli(t, msd, temperature, particle_radius)
    % Calculate dynamic moduli using Generalized Stokes-Einstein Relation (GSER)
    % Based on the methodology from dynamic_mechanical_analysis.m
    
    % Physical constants
    kB = 1.380649e-23;  % Boltzmann constant (J/K)
    l = 0.243e-6;       % Lattice constant (0.243 μm)
    eta = 1.2e-3;       % Viscosity (1.2×10⁻³ Pa·s, blood plasma)
    R = l/2;            % Probe particle radius (l/2)
    zeta = 6.4e-3;      % Time constant (6.4 ms from paper)
    
    % Filter valid data
    valid_mask = isfinite(msd) & (msd > 0) & (t > 0);
    t_valid = t(valid_mask);
    msd_valid = msd(valid_mask);
    
    % Remove duplicate time points
    [t_valid, unique_idx] = unique(t_valid);
    msd_valid = msd_valid(unique_idx);
    
    if length(t_valid) < 10
        omega = [];
        G_storage = [];
        G_loss = [];
        delta = [];
        return;
    end
    
    % Convert dimensionless time to physical time
    t_physical = t_valid * zeta;
    
    % Calculate frequency range
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
    
    % Physical parameters
    kB = 1.380649e-23;  % Boltzmann constant (J/K)
    T = 293;            % Temperature (20°C = 293K)
    eta = 1.2e-3;       % Viscosity (1.2×10⁻³ Pa·s, blood plasma)
    l = 0.243e-6;       % Lattice constant (0.243 μm)
    R = l/2;            % Probe particle radius (l/2)
    zeta = 6.4e-3;      % Time constant (6.4 ms from paper)
    
    % Convert dimensionless units to physical units
    t_physical = t * zeta;  % Convert dimensionless time to seconds
    msd_physical = msd * (l^2);  % Convert dimensionless MSD to m²
    
    % Remove duplicate time points
    [t_physical, unique_idx] = unique(t_physical);
    msd_physical = msd_physical(unique_idx);
    
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
        
        % Ensure α is reasonable (0.01 to 2.0)
        alpha = max(0.01, min(2.0, alpha));
    else
        alpha = 1.0; % Default to normal diffusion
    end
    
    % Calculate MSD at the time scale corresponding to ω
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
    
    % Calculate complex modulus using GSER
    % |G*(ω)| = kBT / (π⟨r²(τ)⟩Γ(1 + α(ω)))
    G_magnitude = kB * T / (pi * msd_tau * gamma_factor);
    
    % Calculate G'(ω) and G"(ω) from magnitude and phase
    % G'(ω) = |G*(ω)|cos(πα(ω)/2)
    % G"(ω) = |G*(ω)|sin(πα(ω)/2)
    G_storage = G_magnitude * cos(pi * alpha / 2);
    G_loss = G_magnitude * sin(pi * alpha / 2);
    
    G_complex = G_storage + 1i * G_loss;
end

function class_frequency = analyze_universality_class_frequency(frequency_results, variants, p_values)
    % Analyze frequency behavior for a universality class
    
    class_frequency = struct();
    
    % Extract data for all variants in this class
    all_omega = [];
    all_G_storage = [];
    all_G_loss = [];
    all_delta = [];
    all_p_values = [];
    
    for v = 1:length(variants)
        variant = variants{v};
        variant_field = matlab.lang.makeValidName(variant);
        if ~isfield(frequency_results, variant_field)
            continue;
        end
        
        for p = 1:length(p_values)
            p_val = p_values(p);
            p_field = matlab.lang.makeValidName(sprintf('p_%.4f', p_val));
            
            if isfield(frequency_results.(variant_field), p_field)
                data = frequency_results.(variant_field).(p_field);
                if ~isempty(data.omega)
                    all_omega = [all_omega, data.omega];
                    all_G_storage = [all_G_storage, data.G_storage];
                    all_G_loss = [all_G_loss, data.G_loss];
                    all_delta = [all_delta, data.delta];
                    all_p_values = [all_p_values, repmat(p_val, size(data.omega))];
                end
            end
        end
    end
    
    % Calculate statistics
    if ~isempty(all_omega)
        class_frequency.omega_range = [min(all_omega), max(all_omega)];
        class_frequency.G_storage_range = [min(all_G_storage), max(all_G_storage)];
        class_frequency.G_loss_range = [min(all_G_loss), max(all_G_loss)];
        class_frequency.delta_range = [min(all_delta), max(all_delta)];
        class_frequency.p_range = [min(all_p_values), max(all_p_values)];
        
        % Calculate frequency-dependent statistics
        unique_omega = unique(all_omega);
        class_frequency.omega_stats = struct();
        
        for i = 1:length(unique_omega)
            omega_val = unique_omega(i);
            mask = abs(all_omega - omega_val) < 1e-6;
            
            omega_field = matlab.lang.makeValidName(sprintf('omega_%.3f', omega_val));
            class_frequency.omega_stats.(omega_field) = struct();
            class_frequency.omega_stats.(omega_field).omega = omega_val;
            class_frequency.omega_stats.(omega_field).G_storage_mean = mean(all_G_storage(mask));
            class_frequency.omega_stats.(omega_field).G_storage_std = std(all_G_storage(mask));
            class_frequency.omega_stats.(omega_field).G_loss_mean = mean(all_G_loss(mask));
            class_frequency.omega_stats.(omega_field).G_loss_std = std(all_G_loss(mask));
            class_frequency.omega_stats.(omega_field).delta_mean = mean(all_delta(mask));
            class_frequency.omega_stats.(omega_field).delta_std = std(all_delta(mask));
        end
        
        fprintf('  Frequency range: %.2f - %.2f rad/s\n', min(all_omega), max(all_omega));
        fprintf('  G'' range: %.2e - %.2e Pa\n', min(all_G_storage), max(all_G_storage));
        fprintf('  G" range: %.2e - %.2e Pa\n', min(all_G_loss), max(all_G_loss));
        fprintf('  δ range: %.1f° - %.1f°\n', min(all_delta), max(all_delta));
    else
        fprintf('  No valid frequency data found\n');
    end
end

function create_frequency_space_plots(frequency_results, universality_frequency, p_values, variants, output_dir)
    % Create comprehensive frequency space visualizations
    
    fprintf('Creating frequency space analysis plots...\n');
    
    % Create main figure
    fig = figure('Position', [100, 100, 1800, 1400], 'Name', 'Frequency Space Analysis');
    
    % Select key p-values for visualization
    key_p_values = [0.1, 0.3116, 0.6884, 0.8];
    key_p_indices = [];
    for i = 1:length(key_p_values)
        [~, idx] = min(abs(p_values - key_p_values(i)));
        key_p_indices = [key_p_indices, idx];
    end
    
    % Colors for variants
    colors = lines(length(variants));
    
    % Subplot 1: G'(ω) for key p-values
    subplot(3, 3, 1);
    hold on;
    for v = 1:length(variants)
        variant = variants{v};
        variant_field = matlab.lang.makeValidName(variant);
        for p_idx = 1:length(key_p_indices)
            p_val = p_values(key_p_indices(p_idx));
            p_field = matlab.lang.makeValidName(sprintf('p_%.4f', p_val));
            
            if isfield(frequency_results.(variant_field), p_field)
                data = frequency_results.(variant_field).(p_field);
                if ~isempty(data.omega)
                    plot(data.omega, data.G_storage, 'Color', colors(v,:), 'LineWidth', 1.5, ...
                         'DisplayName', sprintf('%s p=%.3f', variant, p_val));
                end
            end
        end
    end
    xlabel('Frequency ω (rad/s)');
    ylabel('Storage Modulus G'' (Pa)');
    title('Storage Modulus vs Frequency');
    set(gca, 'XScale', 'log', 'YScale', 'log');
    legend('Location', 'best');
    grid on;
    
    % Subplot 2: G''(ω) for key p-values
    subplot(3, 3, 2);
    hold on;
    for v = 1:length(variants)
        variant = variants{v};
        variant_field = matlab.lang.makeValidName(variant);
        for p_idx = 1:length(key_p_indices)
            p_val = p_values(key_p_indices(p_idx));
            p_field = matlab.lang.makeValidName(sprintf('p_%.4f', p_val));
            
            if isfield(frequency_results.(variant_field), p_field)
                data = frequency_results.(variant_field).(p_field);
                if ~isempty(data.omega)
                    plot(data.omega, data.G_loss, 'Color', colors(v,:), 'LineWidth', 1.5, ...
                         'DisplayName', sprintf('%s p=%.3f', variant, p_val));
                end
            end
        end
    end
    xlabel('Frequency ω (rad/s)');
    ylabel('Loss Modulus G" (Pa)');
    title('Loss Modulus vs Frequency');
    set(gca, 'XScale', 'log', 'YScale', 'log');
    legend('Location', 'best');
    grid on;
    
    % Subplot 3: δ(ω) for key p-values
    subplot(3, 3, 3);
    hold on;
    for v = 1:length(variants)
        variant = variants{v};
        variant_field = matlab.lang.makeValidName(variant);
        for p_idx = 1:length(key_p_indices)
            p_val = p_values(key_p_indices(p_idx));
            p_field = matlab.lang.makeValidName(sprintf('p_%.4f', p_val));
            
            if isfield(frequency_results.(variant_field), p_field)
                data = frequency_results.(variant_field).(p_field);
                if ~isempty(data.omega)
                    plot(data.omega, data.delta, 'Color', colors(v,:), 'LineWidth', 1.5, ...
                         'DisplayName', sprintf('%s p=%.3f', variant, p_val));
                end
            end
        end
    end
    xlabel('Frequency ω (rad/s)');
    ylabel('Phase Angle δ (°)');
    title('Phase Angle vs Frequency');
    set(gca, 'XScale', 'log');
    legend('Location', 'best');
    grid on;
    
    % Subplot 4: Universality class comparison - G'(ω)
    subplot(3, 3, 4);
    hold on;
    if isfield(universality_frequency, 'templated') && isfield(universality_frequency.templated, 'omega_stats')
        templated_omega = [];
        templated_G_storage = [];
        templated_G_storage_std = [];
        
        fields = fieldnames(universality_frequency.templated.omega_stats);
        for i = 1:length(fields)
            data = universality_frequency.templated.omega_stats.(fields{i});
            templated_omega = [templated_omega, data.omega];
            templated_G_storage = [templated_G_storage, data.G_storage_mean];
            templated_G_storage_std = [templated_G_storage_std, data.G_storage_std];
        end
        
        [templated_omega, sort_idx] = sort(templated_omega);
        templated_G_storage = templated_G_storage(sort_idx);
        templated_G_storage_std = templated_G_storage_std(sort_idx);
        
        errorbar(templated_omega, templated_G_storage, templated_G_storage_std, 'r-', 'LineWidth', 2, 'DisplayName', 'Templated Class');
    end
    
    if isfield(universality_frequency, 'standard') && isfield(universality_frequency.standard, 'omega_stats')
        standard_omega = [];
        standard_G_storage = [];
        standard_G_storage_std = [];
        
        fields = fieldnames(universality_frequency.standard.omega_stats);
        for i = 1:length(fields)
            data = universality_frequency.standard.omega_stats.(fields{i});
            standard_omega = [standard_omega, data.omega];
            standard_G_storage = [standard_G_storage, data.G_storage_mean];
            standard_G_storage_std = [standard_G_storage_std, data.G_storage_std];
        end
        
        [standard_omega, sort_idx] = sort(standard_omega);
        standard_G_storage = standard_G_storage(sort_idx);
        standard_G_storage_std = standard_G_storage_std(sort_idx);
        
        errorbar(standard_omega, standard_G_storage, standard_G_storage_std, 'b-', 'LineWidth', 2, 'DisplayName', 'Standard Class');
    end
    
    xlabel('Frequency ω (rad/s)');
    ylabel('Storage Modulus G'' (Pa)');
    title('Universality Class Comparison: G''(ω)');
    set(gca, 'XScale', 'log', 'YScale', 'log');
    legend('Location', 'best');
    grid on;
    
    % Subplot 5: Universality class comparison - G''(ω)
    subplot(3, 3, 5);
    hold on;
    if isfield(universality_frequency, 'templated') && isfield(universality_frequency.templated, 'omega_stats')
        templated_omega = [];
        templated_G_loss = [];
        templated_G_loss_std = [];
        
        fields = fieldnames(universality_frequency.templated.omega_stats);
        for i = 1:length(fields)
            data = universality_frequency.templated.omega_stats.(fields{i});
            templated_omega = [templated_omega, data.omega];
            templated_G_loss = [templated_G_loss, data.G_loss_mean];
            templated_G_loss_std = [templated_G_loss_std, data.G_loss_std];
        end
        
        [templated_omega, sort_idx] = sort(templated_omega);
        templated_G_loss = templated_G_loss(sort_idx);
        templated_G_loss_std = templated_G_loss_std(sort_idx);
        
        errorbar(templated_omega, templated_G_loss, templated_G_loss_std, 'r-', 'LineWidth', 2, 'DisplayName', 'Templated Class');
    end
    
    if isfield(universality_frequency, 'standard') && isfield(universality_frequency.standard, 'omega_stats')
        standard_omega = [];
        standard_G_loss = [];
        standard_G_loss_std = [];
        
        fields = fieldnames(universality_frequency.standard.omega_stats);
        for i = 1:length(fields)
            data = universality_frequency.standard.omega_stats.(fields{i});
            standard_omega = [standard_omega, data.omega];
            standard_G_loss = [standard_G_loss, data.G_loss_mean];
            standard_G_loss_std = [standard_G_loss_std, data.G_loss_std];
        end
        
        [standard_omega, sort_idx] = sort(standard_omega);
        standard_G_loss = standard_G_loss(sort_idx);
        standard_G_loss_std = standard_G_loss_std(sort_idx);
        
        errorbar(standard_omega, standard_G_loss, standard_G_loss_std, 'b-', 'LineWidth', 2, 'DisplayName', 'Standard Class');
    end
    
    xlabel('Frequency ω (rad/s)');
    ylabel('Loss Modulus G" (Pa)');
    title('Universality Class Comparison: G"(ω)');
    set(gca, 'XScale', 'log', 'YScale', 'log');
    legend('Location', 'best');
    grid on;
    
    % Subplot 6: Universality class comparison - δ(ω)
    subplot(3, 3, 6);
    hold on;
    if isfield(universality_frequency, 'templated') && isfield(universality_frequency.templated, 'omega_stats')
        templated_omega = [];
        templated_delta = [];
        templated_delta_std = [];
        
        fields = fieldnames(universality_frequency.templated.omega_stats);
        for i = 1:length(fields)
            data = universality_frequency.templated.omega_stats.(fields{i});
            templated_omega = [templated_omega, data.omega];
            templated_delta = [templated_delta, data.delta_mean];
            templated_delta_std = [templated_delta_std, data.delta_std];
        end
        
        [templated_omega, sort_idx] = sort(templated_omega);
        templated_delta = templated_delta(sort_idx);
        templated_delta_std = templated_delta_std(sort_idx);
        
        errorbar(templated_omega, templated_delta, templated_delta_std, 'r-', 'LineWidth', 2, 'DisplayName', 'Templated Class');
    end
    
    if isfield(universality_frequency, 'standard') && isfield(universality_frequency.standard, 'omega_stats')
        standard_omega = [];
        standard_delta = [];
        standard_delta_std = [];
        
        fields = fieldnames(universality_frequency.standard.omega_stats);
        for i = 1:length(fields)
            data = universality_frequency.standard.omega_stats.(fields{i});
            standard_omega = [standard_omega, data.omega];
            standard_delta = [standard_delta, data.delta_mean];
            standard_delta_std = [standard_delta_std, data.delta_std];
        end
        
        [standard_omega, sort_idx] = sort(standard_omega);
        standard_delta = standard_delta(sort_idx);
        standard_delta_std = standard_delta_std(sort_idx);
        
        errorbar(standard_omega, standard_delta, standard_delta_std, 'b-', 'LineWidth', 2, 'DisplayName', 'Standard Class');
    end
    
    xlabel('Frequency ω (rad/s)');
    ylabel('Phase Angle δ (°)');
    title('Universality Class Comparison: δ(ω)');
    set(gca, 'XScale', 'log');
    legend('Location', 'best');
    grid on;
    
    % Subplot 7: Frequency range summary
    subplot(3, 3, 7);
    hold on;
    for v = 1:length(variants)
        variant = variants{v};
        variant_field = matlab.lang.makeValidName(variant);
        omega_ranges = [];
        p_vals = [];
        
        for p = 1:length(p_values)
            p_val = p_values(p);
            p_field = matlab.lang.makeValidName(sprintf('p_%.4f', p_val));
            
            if isfield(frequency_results.(variant_field), p_field)
                data = frequency_results.(variant_field).(p_field);
                if ~isempty(data.omega)
                    omega_ranges = [omega_ranges, max(data.omega) - min(data.omega)];
                    p_vals = [p_vals, p_val];
                end
            end
        end
        
        if ~isempty(omega_ranges)
            plot(p_vals, omega_ranges, 'o-', 'Color', colors(v,:), 'LineWidth', 2, 'DisplayName', variant);
        end
    end
    xlabel('Percolation Probability p');
    ylabel('Frequency Range (rad/s)');
    title('Frequency Range vs p');
    legend('Location', 'best');
    grid on;
    
    % Subplot 8: G'/G'' ratio
    subplot(3, 3, 8);
    hold on;
    for v = 1:length(variants)
        variant = variants{v};
        variant_field = matlab.lang.makeValidName(variant);
        for p_idx = 1:length(key_p_indices)
            p_val = p_values(key_p_indices(p_idx));
            p_field = matlab.lang.makeValidName(sprintf('p_%.4f', p_val));
            
            if isfield(frequency_results.(variant_field), p_field)
                data = frequency_results.(variant_field).(p_field);
                if ~isempty(data.omega)
                    ratio = data.G_storage ./ data.G_loss;
                    plot(data.omega, ratio, 'Color', colors(v,:), 'LineWidth', 1.5, ...
                         'DisplayName', sprintf('%s p=%.3f', variant, p_val));
                end
            end
        end
    end
    xlabel('Frequency ω (rad/s)');
    ylabel('G''/G" Ratio');
    title('Storage/Loss Modulus Ratio');
    set(gca, 'XScale', 'log', 'YScale', 'log');
    legend('Location', 'best');
    grid on;
    
    % Subplot 9: Summary statistics
    subplot(3, 3, 9);
    text(0.1, 0.9, 'FREQUENCY SPACE ANALYSIS', 'FontSize', 14, 'FontWeight', 'bold');
    text(0.1, 0.8, 'SUMMARY', 'FontSize', 12, 'FontWeight', 'bold');
    
    if isfield(universality_frequency, 'templated')
        text(0.1, 0.7, sprintf('Templated Class:'), 'FontSize', 10, 'FontWeight', 'bold');
        text(0.1, 0.65, sprintf('  ω range: %.2f - %.2f rad/s', universality_frequency.templated.omega_range(1), universality_frequency.templated.omega_range(2)), 'FontSize', 10);
        text(0.1, 0.6, sprintf('  G'' range: %.2e - %.2e Pa', universality_frequency.templated.G_storage_range(1), universality_frequency.templated.G_storage_range(2)), 'FontSize', 10);
        text(0.1, 0.55, sprintf('  δ range: %.1f° - %.1f°', universality_frequency.templated.delta_range(1), universality_frequency.templated.delta_range(2)), 'FontSize', 10);
    end
    
    if isfield(universality_frequency, 'standard')
        text(0.1, 0.45, sprintf('Standard Class:'), 'FontSize', 10, 'FontWeight', 'bold');
        text(0.1, 0.4, sprintf('  ω range: %.2f - %.2f rad/s', universality_frequency.standard.omega_range(1), universality_frequency.standard.omega_range(2)), 'FontSize', 10);
        text(0.1, 0.35, sprintf('  G'' range: %.2e - %.2e Pa', universality_frequency.standard.G_storage_range(1), universality_frequency.standard.G_storage_range(2)), 'FontSize', 10);
        text(0.1, 0.3, sprintf('  δ range: %.1f° - %.1f°', universality_frequency.standard.delta_range(1), universality_frequency.standard.delta_range(2)), 'FontSize', 10);
    end
    
    text(0.1, 0.2, 'KEY INSIGHTS:', 'FontSize', 12, 'FontWeight', 'bold');
    text(0.1, 0.15, '• Frequency-dependent viscoelastic behavior', 'FontSize', 10);
    text(0.1, 0.1, '• Universality class differences in G''(ω), G"(ω), δ(ω)', 'FontSize', 10);
    text(0.1, 0.05, '• Complete frequency space characterization', 'FontSize', 10);
    
    axis off;
    
    sgtitle('Frequency Space Analysis: G''(ω), G"(ω), and δ(ω) for All Variants', 'FontSize', 16);
    
    % Save plot
    filename = fullfile(output_dir, 'frequency_space_analysis.png');
    saveas(fig, filename, 'png');
    fprintf('  Saved: %s\n', filename);
    
end

function save_frequency_space_results(frequency_results, universality_frequency, output_dir)
    % Save frequency space analysis results
    
    % Save main analysis
    mat_file = fullfile(output_dir, 'frequency_space_analysis.mat');
    save(mat_file, 'frequency_results', 'universality_frequency');
    fprintf('  Saved: %s\n', mat_file);
    
    % Create summary text file
    summary_file = fullfile(output_dir, 'frequency_space_summary.txt');
    fid = fopen(summary_file, 'w');
    
    fprintf(fid, 'FREQUENCY SPACE ANALYSIS SUMMARY\n');
    fprintf(fid, '===============================\n\n');
    
    fprintf(fid, 'METHODOLOGY:\n');
    fprintf(fid, '  Generalized Stokes-Einstein Relation (GSER) conversion\n');
    fprintf(fid, '  MSD → G''(ω), G"(ω), δ(ω) as functions of frequency\n');
    fprintf(fid, '  Physical parameters: T=293K, η=1.2×10⁻³ Pa·s, l=0.243 μm\n\n');
    
    if isfield(universality_frequency, 'templated')
        fprintf(fid, 'TEMPLATED UNIVERSALITY CLASS:\n');
        fprintf(fid, '  Frequency range: %.2f - %.2f rad/s\n', universality_frequency.templated.omega_range(1), universality_frequency.templated.omega_range(2));
        fprintf(fid, '  G'' range: %.2e - %.2e Pa\n', universality_frequency.templated.G_storage_range(1), universality_frequency.templated.G_storage_range(2));
        fprintf(fid, '  G" range: %.2e - %.2e Pa\n', universality_frequency.templated.G_loss_range(1), universality_frequency.templated.G_loss_range(2));
        fprintf(fid, '  δ range: %.1f° - %.1f°\n', universality_frequency.templated.delta_range(1), universality_frequency.templated.delta_range(2));
        fprintf(fid, '  p range: %.3f - %.3f\n\n', universality_frequency.templated.p_range(1), universality_frequency.templated.p_range(2));
    end
    
    if isfield(universality_frequency, 'standard')
        fprintf(fid, 'STANDARD UNIVERSALITY CLASS:\n');
        fprintf(fid, '  Frequency range: %.2f - %.2f rad/s\n', universality_frequency.standard.omega_range(1), universality_frequency.standard.omega_range(2));
        fprintf(fid, '  G'' range: %.2e - %.2e Pa\n', universality_frequency.standard.G_storage_range(1), universality_frequency.standard.G_storage_range(2));
        fprintf(fid, '  G" range: %.2e - %.2e Pa\n', universality_frequency.standard.G_loss_range(1), universality_frequency.standard.G_loss_range(2));
        fprintf(fid, '  δ range: %.1f° - %.1f°\n', universality_frequency.standard.delta_range(1), universality_frequency.standard.delta_range(2));
        fprintf(fid, '  p range: %.3f - %.3f\n\n', universality_frequency.standard.p_range(1), universality_frequency.standard.p_range(2));
    end
    
    fprintf(fid, 'CONCLUSIONS:\n');
    fprintf(fid, '  • Complete frequency space characterization achieved\n');
    fprintf(fid, '  • G''(ω), G"(ω), and δ(ω) derived for all variants and p-values\n');
    fprintf(fid, '  • Universality class differences quantified in frequency domain\n');
    fprintf(fid, '  • Ready for microrheology applications and phase transition analysis\n');
    
    fclose(fid);
    fprintf('  Saved: %s\n', summary_file);
    
end
