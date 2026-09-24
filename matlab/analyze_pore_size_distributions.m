% analyze_pore_size_distributions.m
% Quantify pore-size distributions for each variant and p_value
% This is the first step in rigorously quantifying universality class differences
%
% PORE DEFINITION:
% ===============
% A pore is defined as a connected region of empty (unoccupied) lattice sites.
% 
% Technical specifications:
% - Connectivity: 26-neighbor connectivity in 3D (face, edge, and corner neighbors)
% - Empty sites: Lattice sites where template = false (unoccupied)
% - Pore size: Number of connected empty sites in the pore
% - Pore volume: Same as pore size (unit lattice spacing)
% - Pore surface area: Number of boundary faces between empty and occupied sites
%
% This definition captures the fundamental difference between templated and
% random percolation: templated systems create larger, more connected pores
% that reduce obstruction probability for random walkers.

clear; close all; clc;

fprintf('=== PORE-SIZE DISTRIBUTION ANALYSIS ===\n');
fprintf('Quantifying pore-size distributions to understand universality class differences\n\n');

% Load the main data
mat_file = 'Clusters/random_walk_analysis_L500_LW1000000_NW3000.mat';
load(mat_file);

% Analysis parameters
p_analysis = [0.1, 0.2, 0.3, 0.3116, 0.35, 0.4, 0.5, 0.6, 0.6884, 0.7, 0.8, 0.9];
variants = {'Templated_6N', 'Templated_26N', 'Density_Increment', 'Random_Percolation'};

% Initialize results storage
pore_results = struct();

fprintf('Analyzing pore-size distributions for %d p-values and %d variants...\n', length(p_analysis), length(variants));

for v = 1:length(variants)
    variant = variants{v};
    fprintf('\n=== Analyzing %s ===\n', variant);
    
    pore_results.(variant) = struct();
    
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        fprintf('  p = %.4f... ', p_val);
        
        % Load the specific lattice
        % Map variant names to file naming convention
        if strcmp(variant, 'Templated_6N')
            file_variant = '6N_Templated';
        elseif strcmp(variant, 'Templated_26N')
            file_variant = '26N_Templated';
        else
            file_variant = variant;
        end
        lattice_file = sprintf('Clusters/Lattice_%s_p%.4f_L500.mat', file_variant, p_val);
        
        if exist(lattice_file, 'file')
            % Load lattice
            lattice_data = load(lattice_file);
            
            % Check which field contains the lattice data
            field_names = fieldnames(lattice_data);
            if ismember('template', field_names)
                lattice = lattice_data.template;
            elseif ismember('lattice', field_names)
                lattice = lattice_data.lattice;
            elseif ismember('Lattice', field_names)
                lattice = lattice_data.Lattice;
            else
                % Use the first field that's a logical array
                for f = 1:length(field_names)
                    if islogical(lattice_data.(field_names{f}))
                        lattice = lattice_data.(field_names{f});
                        break;
                    end
                end
            end
            
            % Analyze pore-size distribution
            pore_analysis = analyze_single_lattice_pores(lattice, p_val, variant);
            
            % Store results
            field_name = get_field_name(p_val);
            pore_results.(variant).(field_name) = pore_analysis;
            
            fprintf('✓ (%.0f pores, max size: %.0f)\n', pore_analysis.num_pores, pore_analysis.max_pore_size);
        else
            fprintf('✗ (file not found)\n');
            field_name = get_field_name(p_val);
            pore_results.(variant).(field_name) = [];
        end
    end
end

% Create comprehensive analysis plots
fprintf('\n=== CREATING PORE-SIZE ANALYSIS PLOTS ===\n');
create_pore_size_plots(pore_results, p_analysis, variants);

% Calculate scaling exponents
fprintf('\n=== CALCULATING SCALING EXPONENTS ===\n');
scaling_results = calculate_pore_scaling_exponents(pore_results, p_analysis, variants);

% Save results
fprintf('\n=== SAVING RESULTS ===\n');
save('Clusters/pore_size_analysis_results.mat', 'pore_results', 'scaling_results', 'p_analysis', 'variants');
fprintf('Results saved to: Clusters/pore_size_analysis_results.mat\n');

% Create summary report
create_pore_analysis_summary(pore_results, scaling_results, p_analysis, variants);

fprintf('\n=== PORE-SIZE ANALYSIS COMPLETE ===\n');

%% ============================================================================
%% HELPER FUNCTIONS
%% ============================================================================

function field_name = get_field_name(p_val)
% Convert p_value to valid MATLAB field name
field_name = sprintf('p_%.4f', p_val);
field_name = strrep(field_name, '.', '_'); % Replace dots with underscores
end

function pore_analysis = analyze_single_lattice_pores(lattice, p_val, variant)
% Analyze pore-size distribution for a single lattice
%
% PORE IDENTIFICATION PROCESS:
% 1. Convert lattice to binary: empty sites = true, occupied sites = false
% 2. Use 26-connectivity to find connected components of empty sites
% 3. Each connected component is a "pore"
% 4. Calculate pore properties: size, surface area, etc.

% Convert to binary (true = empty, false = occupied)
empty_lattice = ~lattice;

% Find connected components (pores) using 26-connectivity
% This means two empty sites are connected if they share:
% - A face (6 neighbors)
% - An edge (12 neighbors) 
% - A corner (8 neighbors)
% Total: 26 neighbors in 3D
CC = bwconncomp(empty_lattice, 26);

% Calculate pore properties
num_pores = CC.NumObjects;
pore_sizes = zeros(num_pores, 1);
pore_surface_areas = zeros(num_pores, 1);
pore_volumes = zeros(num_pores, 1);

for i = 1:num_pores
    % Get pore indices
    pore_indices = CC.PixelIdxList{i};
    pore_sizes(i) = length(pore_indices);
    
    % Calculate surface area (approximate)
    pore_surface_areas(i) = calculate_pore_surface_area(empty_lattice, pore_indices);
    
    % Volume is same as size for unit lattice
    pore_volumes(i) = pore_sizes(i);
end

% Calculate statistics
max_pore_size = max(pore_sizes);
mean_pore_size = mean(pore_sizes);
std_pore_size = std(pore_sizes);
median_pore_size = median(pore_sizes);

% Calculate pore-size distribution
[counts, edges] = histcounts(log10(pore_sizes), 20);
bin_centers = (edges(1:end-1) + edges(2:end)) / 2;
log_sizes = bin_centers;
log_counts = log10(counts + 1); % Add 1 to avoid log(0)

% Fit power law: P(s) ∝ s^(-τ)
valid_idx = counts > 0;
if sum(valid_idx) > 3
    p_fit = polyfit(log_sizes(valid_idx), log_counts(valid_idx), 1);
    tau_exponent = -p_fit(1);
    r_squared = calculate_r_squared(log_sizes(valid_idx), log_counts(valid_idx), p_fit);
else
    tau_exponent = NaN;
    r_squared = NaN;
end

% Store results
pore_analysis = struct();
pore_analysis.p_val = p_val;
pore_analysis.variant = variant;
pore_analysis.num_pores = num_pores;
pore_analysis.pore_sizes = pore_sizes;
pore_analysis.max_pore_size = max_pore_size;
pore_analysis.mean_pore_size = mean_pore_size;
pore_analysis.std_pore_size = std_pore_size;
pore_analysis.median_pore_size = median_pore_size;
pore_analysis.tau_exponent = tau_exponent;
pore_analysis.r_squared = r_squared;
pore_analysis.log_sizes = log_sizes;
pore_analysis.log_counts = log_counts;
pore_analysis.valid_fit = ~isnan(tau_exponent) && r_squared > 0.7;

end

function surface_area = calculate_pore_surface_area(lattice, pore_indices)
% Calculate approximate surface area of a pore
% This is a simplified calculation - could be made more sophisticated

% Get lattice dimensions
[Lx, Ly, Lz] = size(lattice);

% Convert linear indices to subscripts
[px, py, pz] = ind2sub([Lx, Ly, Lz], pore_indices);

% Count boundary faces
surface_area = 0;
for i = 1:length(px)
    x = px(i); y = py(i); z = pz(i);
    
    % Check 6 faces
    if x == 1 || ~lattice(x-1, y, z), surface_area = surface_area + 1; end
    if x == Lx || ~lattice(x+1, y, z), surface_area = surface_area + 1; end
    if y == 1 || ~lattice(x, y-1, z), surface_area = surface_area + 1; end
    if y == Ly || ~lattice(x, y+1, z), surface_area = surface_area + 1; end
    if z == 1 || ~lattice(x, y, z-1), surface_area = surface_area + 1; end
    if z == Lz || ~lattice(x, y, z+1), surface_area = surface_area + 1; end
end

end

function r_squared = calculate_r_squared(x, y, p_fit)
% Calculate R-squared for linear fit
y_pred = polyval(p_fit, x);
ss_res = sum((y - y_pred).^2);
ss_tot = sum((y - mean(y)).^2);
r_squared = 1 - (ss_res / ss_tot);
end

function create_pore_size_plots(pore_results, p_analysis, variants)
% Create comprehensive pore-size analysis plots

fig = figure('Position', [100, 100, 1600, 1200], 'Name', 'Pore-Size Distribution Analysis');

% Subplot 1: Pore-size distributions for different variants at p=0.5
subplot(2, 3, 1);
p_compare = 0.5;
[~, p_idx] = min(abs(p_analysis - p_compare));

colors = lines(length(variants));
for v = 1:length(variants)
    variant = variants{v};
    field_name = get_field_name(p_compare);
    if isfield(pore_results, variant) && isfield(pore_results.(variant), field_name)
        data = pore_results.(variant).(field_name);
        if ~isempty(data) && data.valid_fit
            plot(data.log_sizes, data.log_counts, 'o-', 'Color', colors(v, :), ...
                 'LineWidth', 2, 'DisplayName', variant);
            hold on;
        end
    end
end
xlabel('log_{10}(Pore Size)');
ylabel('log_{10}(Count)');
title(sprintf('Pore-Size Distribution at p=%.1f', p_compare));
legend('Location', 'best');
grid on;

% Subplot 2: Maximum pore size vs p for all variants
subplot(2, 3, 2);
for v = 1:length(variants)
    variant = variants{v};
    max_sizes = zeros(size(p_analysis));
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(pore_results, variant) && isfield(pore_results.(variant), field_name)
            data = pore_results.(variant).(field_name);
            if ~isempty(data)
                max_sizes(p_idx) = data.max_pore_size;
            end
        end
    end
    plot(p_analysis, max_sizes, 'o-', 'Color', colors(v, :), 'LineWidth', 2, 'DisplayName', variant);
    hold on;
end
xlabel('Percolation Probability p');
ylabel('Maximum Pore Size');
title('Maximum Pore Size vs P');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 3: Mean pore size vs p
subplot(2, 3, 3);
for v = 1:length(variants)
    variant = variants{v};
    mean_sizes = zeros(size(p_analysis));
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(pore_results, variant) && isfield(pore_results.(variant), field_name)
            data = pore_results.(variant).(field_name);
            if ~isempty(data)
                mean_sizes(p_idx) = data.mean_pore_size;
            end
        end
    end
    plot(p_analysis, mean_sizes, 'o-', 'Color', colors(v, :), 'LineWidth', 2, 'DisplayName', variant);
    hold on;
end
xlabel('Percolation Probability p');
ylabel('Mean Pore Size');
title('Mean Pore Size vs P');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

% Subplot 4: Tau exponent vs p
subplot(2, 3, 4);
for v = 1:length(variants)
    variant = variants{v};
    tau_values = zeros(size(p_analysis));
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(pore_results, variant) && isfield(pore_results.(variant), field_name)
            data = pore_results.(variant).(field_name);
            if ~isempty(data) && data.valid_fit
                tau_values(p_idx) = data.tau_exponent;
            else
                tau_values(p_idx) = NaN;
            end
        end
    end
    valid_idx = ~isnan(tau_values);
    if any(valid_idx)
        plot(p_analysis(valid_idx), tau_values(valid_idx), 'o-', 'Color', colors(v, :), ...
             'LineWidth', 2, 'DisplayName', variant);
        hold on;
    end
end
xlabel('Percolation Probability p');
ylabel('Tau Exponent (P(s) ∝ s^{-τ})');
title('Pore-Size Distribution Exponent vs P');
legend('Location', 'best');
grid on;

% Subplot 5: Number of pores vs p
subplot(2, 3, 5);
for v = 1:length(variants)
    variant = variants{v};
    num_pores = zeros(size(p_analysis));
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(pore_results, variant) && isfield(pore_results.(variant), field_name)
            data = pore_results.(variant).(field_name);
            if ~isempty(data)
                num_pores(p_idx) = data.num_pores;
            end
        end
    end
    plot(p_analysis, num_pores, 'o-', 'Color', colors(v, :), 'LineWidth', 2, 'DisplayName', variant);
    hold on;
end
xlabel('Percolation Probability p');
ylabel('Number of Pores');
title('Number of Pores vs P');
legend('Location', 'best');
grid on;

% Subplot 6: Pore-size variance vs p
subplot(2, 3, 6);
for v = 1:length(variants)
    variant = variants{v};
    std_sizes = zeros(size(p_analysis));
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(pore_results, variant) && isfield(pore_results.(variant), field_name)
            data = pore_results.(variant).(field_name);
            if ~isempty(data)
                std_sizes(p_idx) = data.std_pore_size;
            end
        end
    end
    plot(p_analysis, std_sizes, 'o-', 'Color', colors(v, :), 'LineWidth', 2, 'DisplayName', variant);
    hold on;
end
xlabel('Percolation Probability p');
ylabel('Pore-Size Standard Deviation');
title('Pore-Size Variance vs P');
legend('Location', 'best');
grid on;
set(gca, 'YScale', 'log');

sgtitle('Pore-Size Distribution Analysis', 'FontSize', 16);

% Save figure
filename = 'Clusters/pore_size_distribution_analysis.png';
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function scaling_results = calculate_pore_scaling_exponents(pore_results, p_analysis, variants)
% Calculate scaling exponents for pore-size distributions

fprintf('Calculating scaling exponents...\n');

scaling_results = struct();

for v = 1:length(variants)
    variant = variants{v};
    fprintf('  %s: ', variant);
    
    % Extract data for this variant
    max_sizes = [];
    mean_sizes = [];
    tau_values = [];
    p_values = [];
    
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(pore_results, variant) && isfield(pore_results.(variant), field_name)
            data = pore_results.(variant).(field_name);
            if ~isempty(data)
                max_sizes(end+1) = data.max_pore_size;
                mean_sizes(end+1) = data.mean_pore_size;
                if data.valid_fit
                    tau_values(end+1) = data.tau_exponent;
                else
                    tau_values(end+1) = NaN;
                end
                p_values(end+1) = p_val;
            end
        end
    end
    
    % Calculate scaling exponents
    if length(max_sizes) > 5
        % Max pore size scaling: s_max ∝ (1-p)^(-α_max)
        log_one_minus_p = log(1 - p_values);
        log_max_sizes = log(max_sizes);
        valid_idx = isfinite(log_max_sizes) & isfinite(log_one_minus_p);
        
        if sum(valid_idx) > 3
            p_fit = polyfit(log_one_minus_p(valid_idx), log_max_sizes(valid_idx), 1);
            alpha_max = -p_fit(1);
            r_sq_max = calculate_r_squared(log_one_minus_p(valid_idx), log_max_sizes(valid_idx), p_fit);
        else
            alpha_max = NaN;
            r_sq_max = NaN;
        end
        
        % Mean pore size scaling
        log_mean_sizes = log(mean_sizes);
        valid_idx = isfinite(log_mean_sizes) & isfinite(log_one_minus_p);
        
        if sum(valid_idx) > 3
            p_fit = polyfit(log_one_minus_p(valid_idx), log_mean_sizes(valid_idx), 1);
            alpha_mean = -p_fit(1);
            r_sq_mean = calculate_r_squared(log_one_minus_p(valid_idx), log_mean_sizes(valid_idx), p_fit);
        else
            alpha_mean = NaN;
            r_sq_mean = NaN;
        end
        
        % Tau exponent scaling
        valid_tau = ~isnan(tau_values);
        if sum(valid_tau) > 3
            p_fit = polyfit(p_values(valid_tau), tau_values(valid_tau), 1);
            tau_slope = p_fit(1);
            r_sq_tau = calculate_r_squared(p_values(valid_tau), tau_values(valid_tau), p_fit);
        else
            tau_slope = NaN;
            r_sq_tau = NaN;
        end
        
        fprintf('α_max=%.2f, α_mean=%.2f, τ_slope=%.2f\n', alpha_max, alpha_mean, tau_slope);
    else
        alpha_max = NaN; alpha_mean = NaN; tau_slope = NaN;
        r_sq_max = NaN; r_sq_mean = NaN; r_sq_tau = NaN;
        fprintf('insufficient data\n');
    end
    
    % Store results
    scaling_results.(variant) = struct();
    scaling_results.(variant).alpha_max = alpha_max;
    scaling_results.(variant).alpha_mean = alpha_mean;
    scaling_results.(variant).tau_slope = tau_slope;
    scaling_results.(variant).r_sq_max = r_sq_max;
    scaling_results.(variant).r_sq_mean = r_sq_mean;
    scaling_results.(variant).r_sq_tau = r_sq_tau;
    scaling_results.(variant).p_values = p_values;
    scaling_results.(variant).max_sizes = max_sizes;
    scaling_results.(variant).mean_sizes = mean_sizes;
    scaling_results.(variant).tau_values = tau_values;
end

end

function create_pore_analysis_summary(pore_results, scaling_results, p_analysis, variants)
% Create summary report of pore analysis

summary_file = 'Clusters/pore_analysis_summary.txt';
fid = fopen(summary_file, 'w');

fprintf(fid, 'PORE-SIZE DISTRIBUTION ANALYSIS SUMMARY\n');
fprintf(fid, '========================================\n\n');

fprintf(fid, 'Analysis Parameters:\n');
fprintf(fid, '  Lattice size: L=500\n');
fprintf(fid, '  P-values analyzed: %s\n', mat2str(p_analysis));
fprintf(fid, '  Variants: %s\n', strjoin(variants, ', '));
fprintf(fid, '\n');

% Summary statistics for each variant
for v = 1:length(variants)
    variant = variants{v};
    fprintf(fid, '%s Analysis:\n', variant);
    fprintf(fid, '  Scaling exponents:\n');
    fprintf(fid, '    α_max (s_max ∝ (1-p)^{-α_max}): %.3f (R²=%.3f)\n', ...
            scaling_results.(variant).alpha_max, scaling_results.(variant).r_sq_max);
    fprintf(fid, '    α_mean (s_mean ∝ (1-p)^{-α_mean}): %.3f (R²=%.3f)\n', ...
            scaling_results.(variant).alpha_mean, scaling_results.(variant).r_sq_mean);
    fprintf(fid, '    τ_slope (τ vs p): %.3f (R²=%.3f)\n', ...
            scaling_results.(variant).tau_slope, scaling_results.(variant).r_sq_tau);
    
    % Calculate average pore sizes at key p-values
    key_p = [0.1, 0.5, 0.8];
    fprintf(fid, '  Average pore sizes at key p-values:\n');
    for p_val = key_p
        [~, p_idx] = min(abs(p_analysis - p_val));
        field_name = get_field_name(p_val);
        if p_idx <= length(p_analysis) && isfield(pore_results, variant) && ...
           isfield(pore_results.(variant), field_name)
            data = pore_results.(variant).(field_name);
            if ~isempty(data)
                fprintf(fid, '    p=%.1f: max=%.0f, mean=%.1f, std=%.1f\n', ...
                        p_val, data.max_pore_size, data.mean_pore_size, data.std_pore_size);
            end
        end
    end
    fprintf(fid, '\n');
end

fclose(fid);
fprintf('  Saved: %s\n', summary_file);

end
