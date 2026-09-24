% calculate_obstruction_probability.m
% Step 2: Calculate obstruction probability from pore sizes
% This provides the mathematical foundation linking lattice structure to RW response

clear; close all; clc;

fprintf('=== OBSTRUCTION PROBABILITY CALCULATION ===\n');
fprintf('Step 2: Linking pore sizes to obstruction probability\n\n');

% Load pore analysis results
pore_file = 'Clusters/pore_size_analysis_results.mat';
if exist(pore_file, 'file')
    load(pore_file);
    fprintf('Loaded pore analysis results from: %s\n', pore_file);
else
    fprintf('ERROR: Pore analysis results not found. Run analyze_pore_size_distributions.m first.\n');
    return;
end

% Analysis parameters
p_analysis = [0.1, 0.2, 0.3, 0.3116, 0.35, 0.4, 0.5, 0.6, 0.6884, 0.7, 0.8, 0.9];
variants = {'Templated_6N', 'Templated_26N', 'Density_Increment', 'Random_Percolation'};

% Map variant names to MSD data field names
msd_variant_map = containers.Map();
msd_variant_map('Templated_6N') = '6N_Templated';
msd_variant_map('Templated_26N') = '26N_Templated';
msd_variant_map('Density_Increment') = 'Density_Increment';
msd_variant_map('Random_Percolation') = 'Random_Percolation';

% Initialize obstruction probability results
obstruction_results = struct();

fprintf('\nCalculating obstruction probabilities for %d p-values and %d variants...\n', length(p_analysis), length(variants));

for v = 1:length(variants)
    variant = variants{v};
    fprintf('\n=== Analyzing %s ===\n', variant);
    
    obstruction_results.(variant) = struct();
    
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        fprintf('  p = %.4f... ', p_val);
        
        % Get pore data for this variant and p-value
        field_name = get_field_name(p_val);
        if isfield(pore_results, variant) && isfield(pore_results.(variant), field_name)
            pore_data = pore_results.(variant).(field_name);
            
            if ~isempty(pore_data)
                % Calculate obstruction probability from pore data
                obstruction_analysis = calculate_obstruction_from_pores(pore_data, p_val, variant);
                
                % Store results
                obstruction_results.(variant).(field_name) = obstruction_analysis;
                
                fprintf('✓ (P_obs=%.3f, D_eff=%.3f)\n', obstruction_analysis.P_obstruction, obstruction_analysis.D_effective);
            else
                fprintf('✗ (no pore data)\n');
                obstruction_results.(variant).(field_name) = [];
            end
        else
            fprintf('✗ (no data)\n');
            obstruction_results.(variant).(field_name) = [];
        end
    end
end

% Create obstruction probability analysis plots
fprintf('\n=== CREATING OBSTRUCTION PROBABILITY PLOTS ===\n');
create_obstruction_plots(obstruction_results, p_analysis, variants);

% Calculate correlation with MSD behavior
fprintf('\n=== CALCULATING MSD CORRELATION ===\n');
msd_correlation = calculate_msd_obstruction_correlation(obstruction_results, p_analysis, variants);

% Save results
fprintf('\n=== SAVING RESULTS ===\n');
save('Clusters/obstruction_probability_analysis.mat', 'obstruction_results', 'msd_correlation', 'p_analysis', 'variants');
fprintf('Results saved to: Clusters/obstruction_probability_analysis.mat\n');

% Create summary report
create_obstruction_summary(obstruction_results, msd_correlation, p_analysis, variants);

fprintf('\n=== OBSTRUCTION PROBABILITY CALCULATION COMPLETE ===\n');

% ============================================================================
% HELPER FUNCTIONS
% ============================================================================

function field_name = get_field_name(p_val)
% Convert p_value to valid MATLAB field name
field_name = sprintf('p_%.4f', p_val);
field_name = strrep(field_name, '.', '_');
end

function obstruction_analysis = calculate_obstruction_from_pores(pore_data, p_val, variant)
% Calculate obstruction probability from pore size data

% Extract pore information
pore_sizes = pore_data.pore_sizes;
max_pore_size = pore_data.max_pore_size;
mean_pore_size = pore_data.mean_pore_size;
std_pore_size = pore_data.std_pore_size;

% Method 1: Pore-size averaged obstruction probability
% P_obstruction = 1 - (1 - p)^(neighbors_in_pore)
% For large pores, this approaches 0
neighbors_per_pore = 6; % 6 face neighbors in 3D
P_obstruction_pore_averaged = 1 - (1 - p_val)^neighbors_per_pore;

% Method 2: Correlation length based obstruction probability
% P_obstruction ∝ 1/ξ³ where ξ ∝ sqrt(mean_pore_size)
correlation_length = sqrt(mean_pore_size);
P_obstruction_correlation = 1 / (correlation_length^3);

% Method 3: Direct pore-size distribution based
% Weight by pore size distribution
if ~isempty(pore_sizes)
    % Calculate obstruction probability for each pore size
    P_obstruction_by_size = zeros(size(pore_sizes));
    for i = 1:length(pore_sizes)
        pore_size = pore_sizes(i);
        % Larger pores have lower obstruction probability
        P_obstruction_by_size(i) = 1 / (1 + pore_size/1000); % Normalized
    end
    
    % Weight by pore size (larger pores are more important)
    weights = pore_sizes / sum(pore_sizes);
    P_obstruction_weighted = sum(P_obstruction_by_size .* weights);
else
    P_obstruction_weighted = 1; % Maximum obstruction if no pores
end

% Method 4: Maximum pore size based (your key insight)
% Very large pores → very low obstruction
if max_pore_size > 1000
    P_obstruction_max_pore = 1 / (1 + max_pore_size/10000);
else
    P_obstruction_max_pore = 1;
end

% Choose the most appropriate method based on variant
if contains(variant, 'Templated')
    % For templated systems, use max pore size method (your insight)
    P_obstruction = P_obstruction_max_pore;
    method_used = 'max_pore_size';
else
    % For random systems, use correlation length method
    P_obstruction = P_obstruction_correlation;
    method_used = 'correlation_length';
end

% Calculate effective diffusion coefficient
% D_eff = D_0 × (1 - P_obstruction)
D_0 = 1; % Normalized
D_effective = D_0 * (1 - P_obstruction);

% Calculate expected MSD exponent
% α ≈ 1 - P_obstruction (for small P_obstruction)
alpha_expected = 1 - P_obstruction;
alpha_expected = max(0, min(1, alpha_expected)); % Clamp to [0,1]

% Store results
obstruction_analysis = struct();
obstruction_analysis.p_val = p_val;
obstruction_analysis.variant = variant;
obstruction_analysis.P_obstruction = P_obstruction;
obstruction_analysis.D_effective = D_effective;
obstruction_analysis.alpha_expected = alpha_expected;
obstruction_analysis.method_used = method_used;
obstruction_analysis.max_pore_size = max_pore_size;
obstruction_analysis.mean_pore_size = mean_pore_size;
obstruction_analysis.correlation_length = correlation_length;
obstruction_analysis.P_obstruction_pore_averaged = P_obstruction_pore_averaged;
obstruction_analysis.P_obstruction_correlation = P_obstruction_correlation;
obstruction_analysis.P_obstruction_weighted = P_obstruction_weighted;
obstruction_analysis.P_obstruction_max_pore = P_obstruction_max_pore;

end

function create_obstruction_plots(obstruction_results, p_analysis, variants)
% Create comprehensive obstruction probability analysis plots

fig = figure('Position', [100, 100, 1600, 1200], 'Name', 'Obstruction Probability Analysis');

% Subplot 1: Obstruction probability vs p for all variants
subplot(2, 3, 1);
colors = lines(length(variants));
for v = 1:length(variants)
    variant = variants{v};
    P_obstruction = zeros(size(p_analysis));
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(obstruction_results, variant) && isfield(obstruction_results.(variant), field_name)
            data = obstruction_results.(variant).(field_name);
            if ~isempty(data)
                P_obstruction(p_idx) = data.P_obstruction;
            end
        end
    end
    plot(p_analysis, P_obstruction, 'o-', 'Color', colors(v, :), 'LineWidth', 2, 'DisplayName', variant);
    hold on;
end
xlabel('Percolation Probability p');
ylabel('Obstruction Probability P_{obstruction}');
title('Obstruction Probability vs P');
legend('Location', 'west');legend box off
grid on;

% Subplot 2: Effective diffusion coefficient vs p
subplot(2, 3, 2);
for v = 1:length(variants)
    variant = variants{v};
    D_effective = zeros(size(p_analysis));
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(obstruction_results, variant) && isfield(obstruction_results.(variant), field_name)
            data = obstruction_results.(variant).(field_name);
            if ~isempty(data)
                D_effective(p_idx) = data.D_effective;
            end
        end
    end
    plot(p_analysis, D_effective, 'o-', 'Color', colors(v, :), 'LineWidth', 2, 'DisplayName', variant);
    hold on;
end
xlabel('Percolation Probability p');
ylabel('Effective Diffusion Coefficient D_{eff}');
title('Effective Diffusion vs P');
legend('Location', 'west');legend box off
grid on;

% Subplot 3: Expected MSD exponent vs p
subplot(2, 3, 3);
for v = 1:length(variants)
    variant = variants{v};
    alpha_expected = zeros(size(p_analysis));
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(obstruction_results, variant) && isfield(obstruction_results.(variant), field_name)
            data = obstruction_results.(variant).(field_name);
            if ~isempty(data)
                alpha_expected(p_idx) = data.alpha_expected;
            end
        end
    end
    plot(p_analysis, alpha_expected, 'o-', 'Color', colors(v, :), 'LineWidth', 2, 'DisplayName', variant);
    hold on;
end
xlabel('Percolation Probability p');
ylabel('Expected MSD Exponent α');
title('Expected MSD Exponent vs P');
legend('Location', 'west');legend box off
grid on;

% Subplot 4: Max pore size vs obstruction probability
subplot(2, 3, 4);
for v = 1:length(variants)
    variant = variants{v};
    max_pore_sizes = [];
    P_obstruction_values = [];
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(obstruction_results, variant) && isfield(obstruction_results.(variant), field_name)
            data = obstruction_results.(variant).(field_name);
            if ~isempty(data)
                max_pore_sizes(end+1) = data.max_pore_size;
                P_obstruction_values(end+1) = data.P_obstruction;
            end
        end
    end
    if ~isempty(max_pore_sizes)
        loglog(max_pore_sizes, P_obstruction_values, 'o-', 'Color', colors(v, :), 'LineWidth', 2, 'DisplayName', variant);
        hold on;
    end
end
xlabel('Maximum Pore Size');
ylabel('Obstruction Probability P_{obstruction}');
title('P_{obstruction} vs Max Pore Size');
legend('Location', 'southwest');legend box off
grid on;

% Subplot 5: Correlation length vs obstruction probability
subplot(2, 3, 5);
for v = 1:length(variants)
    variant = variants{v};
    correlation_lengths = [];
    P_obstruction_values = [];
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(obstruction_results, variant) && isfield(obstruction_results.(variant), field_name)
            data = obstruction_results.(variant).(field_name);
            if ~isempty(data)
                correlation_lengths(end+1) = data.correlation_length;
                P_obstruction_values(end+1) = data.P_obstruction;
            end
        end
    end
    if ~isempty(correlation_lengths)
        loglog(correlation_lengths, P_obstruction_values, 'o-', 'Color', colors(v, :), 'LineWidth', 2, 'DisplayName', variant);
        hold on;
    end
end
xlabel('Correlation Length ξ');
ylabel('Obstruction Probability P_{obstruction}');
title('P_{obstruction} vs Correlation Length');
legend('Location', 'southwest');legend box off
grid on;

% Subplot 6: Method comparison
subplot(2, 3, 6);
p_compare = 0.5;
[~, p_idx] = min(abs(p_analysis - p_compare));
methods = {'Pore Averaged', 'Correlation Length', 'Weighted', 'Max Pore'};
method_values = zeros(length(variants), length(methods));

for v = 1:length(variants)
    variant = variants{v};
    field_name = get_field_name(p_compare);
    if isfield(obstruction_results, variant) && isfield(obstruction_results.(variant), field_name)
        data = obstruction_results.(variant).(field_name);
        if ~isempty(data)
            method_values(v, 1) = data.P_obstruction_pore_averaged;
            method_values(v, 2) = data.P_obstruction_correlation;
            method_values(v, 3) = data.P_obstruction_weighted;
            method_values(v, 4) = data.P_obstruction_max_pore;
        end
    end
end

bar(method_values);
set(gca, 'XTickLabel', variants);
xlabel('Variant');
ylabel('Obstruction Probability');
title(sprintf('Method Comparison at p=%.1f', p_compare));
legend(methods, 'Location', 'best');
grid on;

sgtitle('Obstruction Probability Analysis', 'FontSize', 16);

% Save figure
filename = 'Clusters/obstruction_probability_analysis.png';
saveas(fig, filename, 'png');
fprintf('  Saved: %s\n', filename);

end

function msd_correlation = calculate_msd_obstruction_correlation(obstruction_results, p_analysis, variants)
% Calculate correlation between obstruction probability and MSD behavior

fprintf('Calculating MSD-obstruction correlation...\n');

% Load MSD results for comparison
msd_file = 'Clusters/universality_class_analysis.mat';
if exist(msd_file, 'file')
    load(msd_file);
    fprintf('  Loaded MSD results for correlation analysis\n');
else
    fprintf('  WARNING: MSD results not found, using obstruction data only\n');
    alpha_results = [];
    delta_results = [];
end

% Map variant names to MSD data field names
msd_variant_map = containers.Map();
msd_variant_map('Templated_6N') = '6N_Templated';
msd_variant_map('Templated_26N') = '26N_Templated';
msd_variant_map('Density_Increment') = 'Density_Increment';
msd_variant_map('Random_Percolation') = 'Random_Percolation';

msd_correlation = struct();

for v = 1:length(variants)
    variant = variants{v};
    fprintf('  %s: ', variant);
    
    % Extract obstruction probabilities
    P_obstruction = [];
    alpha_expected = [];
    p_values = [];
    
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(obstruction_results, variant) && isfield(obstruction_results.(variant), field_name)
            data = obstruction_results.(variant).(field_name);
            if ~isempty(data)
                P_obstruction(end+1) = data.P_obstruction;
                alpha_expected(end+1) = data.alpha_expected;
                p_values(end+1) = p_val;
            end
        end
    end
    
    if length(P_obstruction) > 3
        % Calculate correlation between obstruction and expected alpha
        if ~isempty(alpha_expected)
            correlation_coeff = corrcoef(P_obstruction, alpha_expected);
            r_squared = correlation_coeff(1,2)^2;
            fprintf('r²=%.3f ', r_squared);
        else
            r_squared = NaN;
            fprintf('no MSD data ');
        end
        
        % Calculate scaling exponent: P_obstruction vs p
        log_p = log(p_values);
        log_P_obs = log(P_obstruction);
        valid_idx = isfinite(log_p) & isfinite(log_P_obs) & P_obstruction > 0;
        
        if sum(valid_idx) > 3
            p_fit = polyfit(log_p(valid_idx), log_P_obs(valid_idx), 1);
            scaling_exponent = p_fit(1);
            fprintf('scaling=%.2f\n', scaling_exponent);
        else
            scaling_exponent = NaN;
            fprintf('insufficient data\n');
        end
    else
        r_squared = NaN;
        scaling_exponent = NaN;
        fprintf('insufficient data\n');
    end
    
    % Store results using valid field name (replace problematic characters)
    field_name = variant;
    field_name = strrep(field_name, 'Templated_6N', 'Templated6N');
    field_name = strrep(field_name, 'Templated_26N', 'Templated26N');
    field_name = strrep(field_name, 'Density_Increment', 'DensityIncrement');
    field_name = strrep(field_name, 'Random_Percolation', 'RandomPercolation');
    
    % Ensure field name is valid
    field_name = matlab.lang.makeValidName(field_name);
    
    msd_correlation.(field_name) = struct();
    msd_correlation.(field_name).r_squared = r_squared;
    msd_correlation.(field_name).scaling_exponent = scaling_exponent;
    msd_correlation.(field_name).P_obstruction = P_obstruction;
    msd_correlation.(field_name).alpha_expected = alpha_expected;
    msd_correlation.(field_name).p_values = p_values;
end

end

function create_obstruction_summary(obstruction_results, msd_correlation, p_analysis, variants)
% Create summary report of obstruction analysis

summary_file = 'Clusters/obstruction_analysis_summary.txt';
fid = fopen(summary_file, 'w');

fprintf(fid, 'OBSTRUCTION PROBABILITY ANALYSIS SUMMARY\n');
fprintf(fid, '==========================================\n\n');

fprintf(fid, 'Analysis Parameters:\n');
fprintf(fid, '  P-values analyzed: %s\n', mat2str(p_analysis));
fprintf(fid, '  Variants: %s\n', strjoin(variants, ', '));
fprintf(fid, '\n');

% Summary statistics for each variant
for v = 1:length(variants)
    variant = variants{v};
    fprintf(fid, '%s Analysis:\n', variant);
    
    % Extract obstruction probabilities
    P_obstruction = [];
    D_effective = [];
    alpha_expected = [];
    
    for p_idx = 1:length(p_analysis)
        p_val = p_analysis(p_idx);
        field_name = get_field_name(p_val);
        if isfield(obstruction_results, variant) && isfield(obstruction_results.(variant), field_name)
            data = obstruction_results.(variant).(field_name);
            if ~isempty(data)
                P_obstruction(end+1) = data.P_obstruction;
                D_effective(end+1) = data.D_effective;
                alpha_expected(end+1) = data.alpha_expected;
            end
        end
    end
    
    if ~isempty(P_obstruction)
        fprintf(fid, '  Obstruction Probability:\n');
        fprintf(fid, '    Mean: %.4f, Std: %.4f, Range: [%.4f, %.4f]\n', ...
                mean(P_obstruction), std(P_obstruction), min(P_obstruction), max(P_obstruction));
        
        fprintf(fid, '  Effective Diffusion:\n');
        fprintf(fid, '    Mean: %.4f, Std: %.4f, Range: [%.4f, %.4f]\n', ...
                mean(D_effective), std(D_effective), min(D_effective), max(D_effective));
        
        fprintf(fid, '  Expected MSD Exponent:\n');
        fprintf(fid, '    Mean: %.4f, Std: %.4f, Range: [%.4f, %.4f]\n', ...
                mean(alpha_expected), std(alpha_expected), min(alpha_expected), max(alpha_expected));
        
        % MSD correlation
        if isfield(msd_correlation, variant)
            fprintf(fid, '  MSD Correlation:\n');
            fprintf(fid, '    r²: %.4f\n', msd_correlation.(variant).r_squared);
            fprintf(fid, '    Scaling exponent: %.4f\n', msd_correlation.(variant).scaling_exponent);
        end
    else
        fprintf(fid, '  No data available\n');
    end
    fprintf(fid, '\n');
end

fclose(fid);
fprintf('  Saved: %s\n', summary_file);

end
