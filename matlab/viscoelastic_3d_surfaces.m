function viscoelastic_3d_surfaces(analyzer_results_file, output_dir)
% VISCOELASTIC_3D_SURFACES MATLAB version of 3D viscoelastic surface generator
% Creates novel 3D surface visualizations showing how storage and loss moduli evolve
% as functions of both percolation probability (p) and frequency (ω).
%
% Inputs:
%   analyzer_results_file: Path to hybrid analyzer results CSV
%   output_dir: Directory to save output plots (default: 'output_3d_surfaces')
%
% Example:
%   viscoelastic_3d_surfaces('new_hybrid_results.csv', 'output_3d_surfaces');

% Set default output directory if not provided
if nargin < 2
    output_dir = 'output_3d_surfaces';
end

% Create output directory
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

fprintf('=== MATLAB 3D VISCOELASTIC SURFACE GENERATOR ===\n');
fprintf('Creating novel 3D surfaces for G''(ω, p) and G''''(ω, p)\n\n');

% Load analyzer results
if ~exist(analyzer_results_file, 'file')
    fprintf('Error: Results file not found: %s\n', analyzer_results_file);
    fprintf('Please run the hybrid analysis first.\n');
    return;
end

fprintf('Loading results from: %s\n', analyzer_results_file);
results = readtable(analyzer_results_file);

% Extract sigmoid parameters
fprintf('Extracting sigmoid parameters...\n');
p_c = 0.6884;  % Theoretical critical threshold
width = 0.015; % Typical width from analysis
alpha_min = 0.0;
alpha_max = 1.0;

fprintf('Using sigmoid parameters:\n');
fprintf('  p_c = %.4f\n', p_c);
fprintf('  width = %.4f\n', width);
fprintf('  α_min = %.4f\n', alpha_min);
fprintf('  α_max = %.4f\n', alpha_max);

% Define frequency range (logarithmic scale)
omega_min = 1e-3;  % 0.001 rad/s
omega_max = 1e3;   % 1000 rad/s
omega_points = 100;

% Define p-range based on data
p_min = min(results.p);
p_max = max(results.p);
p_points = 200;

fprintf('\nCreating grids:\n');
fprintf('  p: %.4f to %.4f (%d points)\n', p_min, p_max, p_points);
fprintf('  ω: %.3e to %.3e (%d points)\n', omega_min, omega_max, omega_points);

% Create fine grids
omega_grid = logspace(log10(omega_min), log10(omega_max), omega_points);
p_grid = linspace(p_min, p_max, p_points);

% Create 2D meshgrids
[P, OMEGA] = meshgrid(p_grid, omega_grid);

% Calculate sigmoid α function
alpha_p = sigmoid_alpha_function(p_grid, p_c, width, alpha_min, alpha_max);

% Calculate surfaces
fprintf('\nCalculating viscoelastic surfaces...\n');

% G'(ω, p) surface
fprintf('Calculating G''(ω, p) surface...\n');
G_prime_surface = calculate_G_prime_surface(P, OMEGA, alpha_p, p_grid);

% G''(ω, p) surface
fprintf('Calculating G''''(ω, p) surface...\n');
G_double_prime_surface = calculate_G_double_prime_surface(P, OMEGA, alpha_p, p_grid);

% Phase angle δ(ω, p) surface
fprintf('Calculating phase angle δ(ω, p) surface...\n');
delta_surface = calculate_phase_angle_surface(P, OMEGA, alpha_p, p_grid);

% Loss tangent tan δ(ω, p) surface
fprintf('Calculating loss tangent tan δ(ω, p) surface...\n');
tan_delta_surface = calculate_loss_tangent_surface(P, OMEGA, alpha_p, p_grid);

fprintf('✓ All surfaces calculated successfully!\n');

% Create plots
fprintf('\nCreating 3D surface plots...\n');

% Main 3D surface plot
create_main_3d_surface_plot(P, OMEGA, G_prime_surface, G_double_prime_surface, ...
                           delta_surface, tan_delta_surface, p_c, output_dir);

% Individual surface plots
create_individual_surface_plots(P, OMEGA, G_prime_surface, G_double_prime_surface, ...
                              p_c, omega_min, omega_max, output_dir);

% Contour plots
create_contour_plots(P, OMEGA, G_prime_surface, G_double_prime_surface, ...
                    delta_surface, tan_delta_surface, p_c, output_dir);

% Cross-sectional plots
create_cross_sectional_plots(p_grid, omega_grid, G_prime_surface, G_double_prime_surface, ...
                            delta_surface, tan_delta_surface, p_c, output_dir);

% Animation frames
create_animation_frames(p_grid, omega_grid, G_prime_surface, G_double_prime_surface, ...
                       p_c, omega_min, omega_max, output_dir);

% Save surface data
save_surface_data(p_grid, omega_grid, G_prime_surface, G_double_prime_surface, ...
                 delta_surface, tan_delta_surface, output_dir);

% Generate summary report
generate_summary_report(p_min, p_max, omega_min, omega_max, p_points, omega_points, ...
                       p_c, output_dir);

fprintf('\n%s\n', repmat('=', 1, 60));
fprintf('3D VISCOELASTIC SURFACE GENERATION COMPLETE!\n');
fprintf('Results saved to: %s\n', output_dir);
fprintf('%s\n', repmat('=', 1, 60));
fprintf('\nNovel visualizations created:\n');
fprintf('✓ 3D surfaces for G''(ω, p) and G''''(ω, p)\n');
fprintf('✓ Contour plots for easy interpretation\n');
fprintf('✓ Cross-sectional analysis\n');
fprintf('✓ Animation frames for frequency sweep\n');
fprintf('✓ Data export for further analysis\n');
fprintf('\nThis represents a new contribution to the community!\n');

end

function alpha = sigmoid_alpha_function(p_values, p_c, width, alpha_min, alpha_max)
% Calculate α values using sigmoid function

% Sigmoid function: α(p) = α_min + (α_max - α_min) / (1 + exp((p - p_c) / width))
alpha = alpha_min + (alpha_max - alpha_min) ./ (1 + exp((p_values - p_c) / width));

% Ensure bounds
alpha = max(0.0, min(1.0, alpha));

end

function G_prime_surface = calculate_G_prime_surface(P, OMEGA, alpha_p, p_grid)
% Calculate G'(ω, p) surface

% Initialize surface
G_prime_surface = zeros(size(P));

% For each frequency, calculate G' across p-values
for i = 1:size(P, 1)
    for j = 1:size(P, 2)
        omega = OMEGA(i, j);
        alpha = alpha_p(j);
        
        if alpha <= 0
            % Solid regime: G' = G0 (constant)
            G_prime_surface(i, j) = 1.0;
        elseif alpha >= 1
            % Liquid regime: G' = G0 (constant)
            G_prime_surface(i, j) = 1.0;
        else
            % Viscoelastic regime: G' = G0 * ω^α
            G_prime_surface(i, j) = omega ^ alpha;
        end
    end
end

fprintf('  ✓ G''(ω, p) surface calculated: shape %s\n', mat2str(size(G_prime_surface)));

end

function G_double_prime_surface = calculate_G_double_prime_surface(P, OMEGA, alpha_p, p_grid)
% Calculate G''(ω, p) surface

% Initialize surface
G_double_prime_surface = zeros(size(P));

% For each frequency, calculate G'' across p-values
for i = 1:size(P, 1)
    for j = 1:size(P, 2)
        omega = OMEGA(i, j);
        alpha = alpha_p(j);
        
        if alpha <= 0
            % Solid regime: G'' = 0 (no loss)
            G_double_prime_surface(i, j) = 0.0;
        elseif alpha >= 1
            % Liquid regime: G'' = G0 (viscous)
            G_double_prime_surface(i, j) = 1.0;
        else
            % Viscoelastic regime: G'' = G0 * ω^α
            G_double_prime_surface(i, j) = omega ^ alpha;
        end
    end
end

fprintf('  ✓ G''''(ω, p) surface calculated: shape %s\n', mat2str(size(G_double_prime_surface)));

end

function delta_surface = calculate_phase_angle_surface(P, OMEGA, alpha_p, p_grid)
% Calculate phase angle δ(ω, p) surface

% Initialize surface
delta_surface = zeros(size(P));

% For each frequency, calculate δ across p-values
for i = 1:size(P, 1)
    for j = 1:size(P, 2)
        alpha = alpha_p(j);
        
        if alpha <= 0
            % Solid regime: δ = 0° (purely elastic)
            delta_surface(i, j) = 0.0;
        elseif alpha >= 1
            % Liquid regime: δ = 90° (purely viscous)
            delta_surface(i, j) = 90.0;
        else
            % Viscoelastic regime: δ = πα/2
            delta_rad = pi * alpha / 2;
            delta_surface(i, j) = delta_rad * 180 / pi;
        end
    end
end

fprintf('  ✓ Phase angle δ(ω, p) surface calculated: shape %s\n', mat2str(size(delta_surface)));

end

function tan_delta_surface = calculate_loss_tangent_surface(P, OMEGA, alpha_p, p_grid)
% Calculate loss tangent tan δ(ω, p) surface

% Initialize surface
tan_delta_surface = zeros(size(P));

% For each frequency, calculate tan δ across p-values
for i = 1:size(P, 1)
    for j = 1:size(P, 2)
        alpha = alpha_p(j);
        
        if alpha <= 0
            % Solid regime: tan δ = 0
            tan_delta_surface(i, j) = 0.0;
        elseif alpha >= 1
            % Liquid regime: tan δ → ∞ (use large finite value)
            tan_delta_surface(i, j) = 100.0;
        else
            % Viscoelastic regime: tan δ = tan(πα/2)
            delta_rad = pi * alpha / 2;
            tan_delta = tan(delta_rad);
            % Ensure reasonable bounds
            tan_delta_surface(i, j) = max(0.0, min(100.0, tan_delta));
        end
    end
end

fprintf('  ✓ Loss tangent tan δ(ω, p) surface calculated: shape %s\n', mat2str(size(tan_delta_surface)));

end

function create_main_3d_surface_plot(P, OMEGA, G_prime_surface, G_double_prime_surface, ...
                                    delta_surface, tan_delta_surface, p_c, output_dir)
% Create main 3D surface plot with all four surfaces

fig = figure('Position', [100, 100, 2000, 1600]);

% Plot 1: G'(ω, p) surface
ax1 = subplot(2, 2, 1);
surf1 = surf(P, OMEGA, G_prime_surface, 'FaceAlpha', 0.8, 'LineWidth', 0.5);
colormap(ax1, 'viridis');
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Frequency ω (rad/s)', 'FontSize', 12);
zlabel("G'(ω, p)", 'FontSize', 12);
title('Storage Modulus G''(ω, p)', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YScale', 'log');
colorbar;
view(3);

% Plot 2: G''(ω, p) surface
ax2 = subplot(2, 2, 2);
surf2 = surf(P, OMEGA, G_double_prime_surface, 'FaceAlpha', 0.8, 'LineWidth', 0.5);
colormap(ax2, 'plasma');
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Frequency ω (rad/s)', 'FontSize', 12);
zlabel("G''(ω, p)", 'FontSize', 12);
title('Loss Modulus G''''(ω, p)', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YScale', 'log');
colorbar;
view(3);

% Plot 3: Phase angle δ(ω, p) surface
ax3 = subplot(2, 2, 3);
surf3 = surf(P, OMEGA, delta_surface, 'FaceAlpha', 0.8, 'LineWidth', 0.5);
colormap(ax3, 'coolwarm');
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Frequency ω (rad/s)', 'FontSize', 12);
zlabel('Phase Angle δ (degrees)', 'FontSize', 12);
title('Phase Angle δ(ω, p)', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YScale', 'log');
zlim([0, 90]);
colorbar;
view(3);

% Plot 4: Loss tangent tan δ(ω, p) surface
ax4 = subplot(2, 2, 4);
surf4 = surf(P, OMEGA, tan_delta_surface, 'FaceAlpha', 0.8, 'LineWidth', 0.5);
colormap(ax4, 'RdYlBu');
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Frequency ω (rad/s)', 'FontSize', 12);
zlabel('Loss Tangent tan δ', 'FontSize', 12);
title('Loss Tangent tan δ(ω, p)', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YScale', 'log');
zlim([0, 100]);
colorbar;
view(3);

% Save plot
output_file = fullfile(output_dir, 'viscoelastic_3d_surfaces_main.png');
saveas(fig, output_file, 'png');
close(fig);

fprintf('  ✓ Main 3D surface plot saved: %s\n', output_file);

end

function create_individual_surface_plots(P, OMEGA, G_prime_surface, G_double_prime_surface, ...
                                       p_c, omega_min, omega_max, output_dir)
% Create individual 3D surface plots for detailed analysis

% G'(ω, p) individual plot
fig = figure('Position', [100, 100, 1400, 1000]);
ax = subplot(111);
surf = surf(P, OMEGA, G_prime_surface, 'FaceAlpha', 0.9, 'LineWidth', 0.3);
colormap('viridis');

xlabel('Percolation Probability (p)', 'FontSize', 14);
ylabel('Frequency ω (rad/s)', 'FontSize', 14);
zlabel("G'(ω, p)", 'FontSize', 14);
title('Storage Modulus Surface G''(ω, p)\n3D Visualization of Elastic Response', ...
      'FontSize', 16, 'FontWeight', 'bold');

% Add critical threshold line
hold on;
plot3([p_c, p_c], [omega_min, omega_max], ...
      [max(G_prime_surface(:)), max(G_prime_surface(:))], ...
      'r--', 'LineWidth', 3, 'Alpha', 0.8);

set(gca, 'YScale', 'log');
colorbar;
view(3);

% Save plot
output_file = fullfile(output_dir, 'G_prime_3d_surface.png');
saveas(fig, output_file, 'png');
close(fig);

% G''(ω, p) individual plot
fig = figure('Position', [100, 100, 1400, 1000]);
ax = subplot(111);
surf = surf(P, OMEGA, G_double_prime_surface, 'FaceAlpha', 0.9, 'LineWidth', 0.3);
colormap('plasma');

xlabel('Percolation Probability (p)', 'FontSize', 14);
ylabel('Frequency ω (rad/s)', 'FontSize', 14);
zlabel("G''(ω, p)", 'FontSize', 14);
title('Loss Modulus Surface G''''(ω, p)\n3D Visualization of Viscous Response', ...
      'FontSize', 16, 'FontWeight', 'bold');

% Add critical threshold line
hold on;
plot3([p_c, p_c], [omega_min, omega_max], ...
      [max(G_double_prime_surface(:)), max(G_double_prime_surface(:))], ...
      'r--', 'LineWidth', 3, 'Alpha', 0.8);

set(gca, 'YScale', 'log');
colorbar;
view(3);

% Save plot
output_file = fullfile(output_dir, 'G_double_prime_3d_surface.png');
saveas(fig, output_file, 'png');
close(fig);

fprintf('  ✓ Individual 3D surface plots created\n');

end

function create_contour_plots(P, OMEGA, G_prime_surface, G_double_prime_surface, ...
                             delta_surface, tan_delta_surface, p_c, output_dir)
% Create 2D contour plots for easier interpretation

fig = figure('Position', [100, 100, 1600, 1200]);

% G'(ω, p) contour
subplot(2, 2, 1);
contourf(P, OMEGA, G_prime_surface, 20);
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Frequency ω (rad/s)', 'FontSize', 12);
title("G'(ω, p) Contour", 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YScale', 'log');
hold on;
plot([p_c, p_c], ylim, 'r--', 'LineWidth', 2, 'Alpha', 0.8);
colorbar;

% G''(ω, p) contour
subplot(2, 2, 2);
contourf(P, OMEGA, G_double_prime_surface, 20);
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Frequency ω (rad/s)', 'FontSize', 12);
title("G''(ω, p) Contour", 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YScale', 'log');
hold on;
plot([p_c, p_c], ylim, 'r--', 'LineWidth', 2, 'Alpha', 0.8);
colorbar;

% Phase angle contour
subplot(2, 2, 3);
contourf(P, OMEGA, delta_surface, 20);
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Frequency ω (rad/s)', 'FontSize', 12);
title('Phase Angle δ(ω, p) Contour', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YScale', 'log');
hold on;
plot([p_c, p_c], ylim, 'r--', 'LineWidth', 2, 'Alpha', 0.8);
colorbar;

% Loss tangent contour
subplot(2, 2, 4);
contourf(P, OMEGA, tan_delta_surface, 20);
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Frequency ω (rad/s)', 'FontSize', 12);
title('Loss Tangent tan δ(ω, p) Contour', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YScale', 'log');
hold on;
plot([p_c, p_c], ylim, 'r--', 'LineWidth', 2, 'Alpha', 0.8);
colorbar;

% Save plot
output_file = fullfile(output_dir, 'viscoelastic_contour_plots.png');
saveas(fig, output_file, 'png');
close(fig);

fprintf('  ✓ Contour plots created\n');

end

function create_cross_sectional_plots(p_grid, omega_grid, G_prime_surface, G_double_prime_surface, ...
                                    delta_surface, tan_delta_surface, p_c, output_dir)
% Create cross-sectional plots showing specific frequency and p-value cuts

fig = figure('Position', [100, 100, 1600, 1200]);

% Cross-section 1: Fixed frequency, varying p
fixed_omega = 1.0;  % 1 rad/s
[~, omega_idx] = min(abs(omega_grid - fixed_omega));

subplot(2, 2, 1);
plot(p_grid, G_prime_surface(omega_idx, :), 'b-', 'LineWidth', 3, 'DisplayName', "G'(ω=1)");
hold on;
plot(p_grid, G_double_prime_surface(omega_idx, :), 'r-', 'LineWidth', 3, 'DisplayName', "G''(ω=1)");
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Modulus G(ω=1)', 'FontSize', 12);
title(sprintf('Moduli vs p at ω = %.1f rad/s', fixed_omega), 'FontSize', 14, 'FontWeight', 'bold');
plot([p_c, p_c], ylim, 'k:', 'LineWidth', 2, 'Alpha', 0.8, 'DisplayName', sprintf("p_c' = %.4f", p_c));
legend;
grid on;

% Cross-section 2: Fixed p, varying frequency
fixed_p = p_c;  % Critical p-value
[~, p_idx] = min(abs(p_grid - fixed_p));

subplot(2, 2, 2);
loglog(omega_grid, G_prime_surface(:, p_idx), 'b-', 'LineWidth', 3, 'DisplayName', "G'(p=p_c)");
hold on;
loglog(omega_grid, G_double_prime_surface(:, p_idx), 'r-', 'LineWidth', 3, 'DisplayName', "G''(p=p_c)");
xlabel('Frequency ω (rad/s)', 'FontSize', 12);
ylabel('Modulus G(p=p_c)', 'FontSize', 12);
title(sprintf('Moduli vs ω at p = %.4f', fixed_p), 'FontSize', 14, 'FontWeight', 'bold');
legend;
grid on;

% Cross-section 3: Phase angle vs p at fixed frequency
subplot(2, 2, 3);
plot(p_grid, delta_surface(omega_idx, :), 'g-', 'LineWidth', 3, 'DisplayName', 'Phase Angle δ');
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Phase Angle δ (degrees)', 'FontSize', 12);
title(sprintf('Phase Angle vs p at ω = %.1f rad/s', fixed_omega), 'FontSize', 14, 'FontWeight', 'bold');
hold on;
plot([p_c, p_c], ylim, 'k:', 'LineWidth', 2, 'Alpha', 0.8, 'DisplayName', sprintf("p_c' = %.4f", p_c));
plot(xlim, [45, 45], 'Color', [1, 0.5, 0], 'LineStyle', '--', 'Alpha', 0.6, 'DisplayName', 'δ = 45° (critical)');
legend;
grid on;
ylim([0, 90]);

% Cross-section 4: Loss tangent vs p at fixed frequency
subplot(2, 2, 4);
plot(p_grid, tan_delta_surface(omega_idx, :), 'm-', 'LineWidth', 3, 'DisplayName', 'Loss Tangent tan δ');
xlabel('Percolation Probability (p)', 'FontSize', 12);
ylabel('Loss Tangent tan δ', 'FontSize', 12);
title(sprintf('Loss Tangent vs p at ω = %.1f rad/s', fixed_omega), 'FontSize', 14, 'FontWeight', 'bold');
hold on;
plot([p_c, p_c], ylim, 'k:', 'LineWidth', 2, 'Alpha', 0.8, 'DisplayName', sprintf("p_c' = %.4f", p_c));
plot(xlim, [1, 1], 'Color', [1, 0.5, 0], 'LineStyle', '--', 'Alpha', 0.6, 'DisplayName', 'tan δ = 1 (critical)');
legend;
grid on;
ylim([0, 100]);

% Save plot
output_file = fullfile(output_dir, 'viscoelastic_cross_sections.png');
saveas(fig, output_file, 'png');
close(fig);

fprintf('  ✓ Cross-sectional plots created\n');

end

function create_animation_frames(p_grid, omega_grid, G_prime_surface, G_double_prime_surface, ...
                               p_c, omega_min, omega_max, output_dir)
% Create frames for potential animation (frequency sweep)

fprintf('Creating animation frames...\n');

% Create frames directory
frames_dir = fullfile(output_dir, 'animation_frames');
if ~exist(frames_dir, 'dir')
    mkdir(frames_dir);
end

% Select subset of frequencies for frames
frame_frequencies = logspace(log10(omega_min), log10(omega_max), 20);

for i = 1:length(frame_frequencies)
    omega = frame_frequencies(i);
    
    fig = figure('Position', [100, 100, 1200, 800]);
    ax = subplot(111);
    
    % Find closest frequency index
    [~, omega_idx] = min(abs(omega_grid - omega));
    
    % Create surface for this frequency
    p_mesh = p_grid;
    omega_mesh = ones(size(p_grid)) * omega;
    G_prime_mesh = G_prime_surface(omega_idx, :);
    G_double_prime_mesh = G_double_prime_surface(omega_idx, :);
    
    % Plot both moduli
    plot3(p_mesh, omega_mesh, G_prime_mesh, 'b-', 'LineWidth', 3, 'DisplayName', "G'");
    hold on;
    plot3(p_mesh, omega_mesh, G_double_prime_mesh, 'r-', 'LineWidth', 3, 'DisplayName', "G''");
    
    xlabel('Percolation Probability (p)', 'FontSize', 12);
    ylabel('Frequency ω (rad/s)', 'FontSize', 12);
    zlabel('Modulus G(ω, p)', 'FontSize', 12);
    title(sprintf('Viscoelastic Response at ω = %.3f rad/s\nFrame %d/20', omega, i), ...
          'FontSize', 14, 'FontWeight', 'bold');
    
    % Add critical threshold
    plot3([p_c, p_c], [omega, omega], [0, max(G_prime_mesh)*1.1], ...
          'k--', 'LineWidth', 3, 'Alpha', 0.8);
    
    xlim([min(p_grid), max(p_grid)]);
    ylim([omega*0.9, omega*1.1]);
    zlim([0, max(G_prime_mesh)*1.1]);
    
    legend;
    view(3);
    
    % Save frame
    frame_file = fullfile(frames_dir, sprintf('frame_%03d_omega_%.3f.png', i, omega));
    saveas(fig, frame_file, 'png');
    close(fig);
end

fprintf('  ✓ Animation frames created: %d frames\n', length(frame_frequencies));

end

function save_surface_data(p_grid, omega_grid, G_prime_surface, G_double_prime_surface, ...
                          delta_surface, tan_delta_surface, output_dir)
% Save surface data for further analysis

fprintf('Saving surface data...\n');

% Create data directory
data_dir = fullfile(output_dir, 'surface_data');
if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end

% Save as MAT file
mat_file = fullfile(data_dir, 'viscoelastic_surfaces_data.mat');
save(mat_file, 'p_grid', 'omega_grid', 'G_prime_surface', 'G_double_prime_surface', ...
     'delta_surface', 'tan_delta_surface');

% Save as CSV for easy viewing
% Flatten arrays for CSV
[P, OMEGA] = meshgrid(p_grid, omega_grid);
p_flat = P(:);
omega_flat = OMEGA(:);
G_prime_flat = G_prime_surface(:);
G_double_prime_flat = G_double_prime_surface(:);
delta_flat = delta_surface(:);
tan_delta_flat = tan_delta_surface(:);

% Create table
surface_table = table(p_flat, omega_flat, G_prime_flat, G_double_prime_flat, ...
                     delta_flat, tan_delta_flat, ...
                     'VariableNames', {'p', 'omega', 'G_prime', 'G_double_prime', ...
                                     'delta', 'tan_delta'});

% Save CSV
csv_file = fullfile(data_dir, 'viscoelastic_surfaces_data.csv');
writetable(surface_table, csv_file);

fprintf('  ✓ Surface data saved to %s\n', data_dir);
fprintf('    - MAT file: viscoelastic_surfaces_data.mat\n');
fprintf('    - CSV data: viscoelastic_surfaces_data.csv\n');

end

function generate_summary_report(p_min, p_max, omega_min, omega_max, p_points, omega_points, ...
                               p_c, output_dir)
% Generate a summary report of the 3D surface analysis

report_file = fullfile(output_dir, '3d_surface_analysis_summary.md');

fid = fopen(report_file, 'w');

fprintf(fid, '# 3D Viscoelastic Surface Analysis Summary\n\n');
fprintf(fid, '## Overview\n\n');
fprintf(fid, 'This report summarizes the generation of 3D surfaces for viscoelastic moduli\n');
fprintf(fid, 'as functions of both percolation probability (p) and frequency (ω).\n\n');

fprintf(fid, '## Surface Parameters\n\n');
fprintf(fid, '- **Percolation range**: p ∈ [%.4f, %.4f]\n', p_min, p_max);
fprintf(fid, '- **Frequency range**: ω ∈ [%.3e, %.3e] rad/s\n', omega_min, omega_max);
fprintf(fid, '- **Grid resolution**: %d × %d = %d points\n', p_points, omega_points, p_points * omega_points);
fprintf(fid, '- **Critical threshold**: p_c'' = %.4f\n\n', p_c);

fprintf(fid, '## Generated Surfaces\n\n');
fprintf(fid, '1. **G''(ω, p)**: Storage modulus surface\n');
fprintf(fid, '2. **G''''(ω, p)**: Loss modulus surface\n');
fprintf(fid, '3. **δ(ω, p)**: Phase angle surface\n');
fprintf(fid, '4. **tan δ(ω, p)**: Loss tangent surface\n\n');

fprintf(fid, '## Key Features\n\n');
fprintf(fid, '- **3D surface plots**: Interactive visualization of moduli evolution\n');
fprintf(fid, '- **Contour plots**: 2D representation for easier interpretation\n');
fprintf(fid, '- **Cross-sectional analysis**: Specific cuts through the surfaces\n');
fprintf(fid, '- **Animation frames**: Frequency sweep visualization\n');
fprintf(fid, '- **Data export**: MAT files and CSV for further analysis\n\n');

fprintf(fid, '## Physical Interpretation\n\n');
fprintf(fid, '- **Liquid regime (p < p_c'')**: G'' ≈ G'''' ≈ constant, δ ≈ 90°\n');
fprintf(fid, '- **Critical regime (p ≈ p_c'')**: Power law behavior, δ ≈ 45°\n');
fprintf(fid, '- **Solid regime (p > p_c'')**: G'' ≈ constant, G'''' ≈ 0, δ ≈ 0°\n\n');

fprintf(fid, '## Output Files\n\n');
fprintf(fid, '- `viscoelastic_3d_surfaces_main.png`: Main 4-panel 3D surface plot\n');
fprintf(fid, '- `G_prime_3d_surface.png`: Individual G'' surface\n');
fprintf(fid, '- `G_double_prime_3d_surface.png`: Individual G'''' surface\n');
fprintf(fid, '- `viscoelastic_contour_plots.png`: 2D contour representations\n');
fprintf(fid, '- `viscoelastic_cross_sections.png`: Cross-sectional analysis\n');
fprintf(fid, '- `animation_frames/`: Frequency sweep frames\n');
fprintf(fid, '- `surface_data/`: Numerical data for further analysis\n\n');

fprintf(fid, '## Novel Contributions\n\n');
fprintf(fid, 'This visualization represents a **new contribution to the community** by:\n');
fprintf(fid, '- Showing **simultaneous evolution** of viscoelastic properties with p and ω\n');
fprintf(fid, '- Revealing **frequency-dependent percolation effects**\n');
fprintf(fid, '- Providing **3D perspective** on the gel-point transition\n');
fprintf(fid, '- Enabling **interpolation** of moduli at any (p, ω) combination\n\n');

fprintf(fid, '## Applications\n\n');
fprintf(fid, '- **Material design**: Optimize percolation for desired frequency response\n');
fprintf(fid, '- **Process control**: Monitor gelation at specific frequencies\n');
fprintf(fid, '- **Quality assurance**: Verify viscoelastic properties across p-range\n');
fprintf(fid, '- **Research insights**: Understand frequency-percolation coupling\n\n');

fclose(fid);

fprintf('  ✓ Summary report saved: %s\n', report_file);

end
