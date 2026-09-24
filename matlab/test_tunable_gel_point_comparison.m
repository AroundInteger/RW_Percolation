% test_tunable_gel_point_comparison.m
% Comprehensive test of tunable gel-point lattice generator
% Compare against random, templated, Eden, and DLA models
% Quantify differences between templated models and classical growth models

clc; close all; clear all;

fprintf('=== Tunable Gel-Point Lattice Generator Test ===\n');
fprintf('Comparing Random, Templated, Eden, and DLA Models\n\n');

% Parameters
L = 100;  % Lattice size
p_values = [0.1,0.69,0.8];  % Occupation probabilities to test
num_trials = 5;  % Number of trials for statistical analysis
output_dir = '/Users/iMacPro/Documents/GitHub/RW_Percolation/paper_drafts/figures';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Initialize results storage
results = struct();
methods = {'Random', '6N_Templated', '26N_Templated', 'Eden', 'DLA'};
num_methods = length(methods);

% Storage for analysis
lattice_data = cell(num_methods, length(p_values), num_trials);
alpha_values = zeros(num_methods, length(p_values), num_trials);
connectivity_data = zeros(num_methods, length(p_values), num_trials);
fractal_dimensions = zeros(num_methods, length(p_values), num_trials);
pore_size_distributions = cell(num_methods, length(p_values), num_trials);

%% Generate Lattices for All Methods
fprintf('Generating lattices for all methods...\n');

for trial = 1:num_trials
    fprintf('Trial %d/%d\n', trial, num_trials);
    
    for p_idx = 1:length(p_values)
        p = p_values(p_idx);
        fprintf('  p = %.3f\n', p);
        
        % Random Percolation
        lattice_random = generate_random_lattice(L, p);
        lattice_data{1, p_idx, trial} = lattice_random;
        
        % 6N Templated
        lattice_6n = generate_templated_lattice(L, p, '6N');
        lattice_data{2, p_idx, trial} = lattice_6n;
        
        % 26N Templated
        lattice_26n = generate_templated_lattice(L, p, '26N');
        lattice_data{3, p_idx, trial} = lattice_26n;
        
        % Eden Growth
        lattice_eden = generate_eden_model(L, p);
        lattice_data{4, p_idx, trial} = lattice_eden;
        
        % DLA Growth
        lattice_dla = generate_dla_model(L, p);
        lattice_data{5, p_idx, trial} = lattice_dla;
    end
end

%% Analyze Lattice Properties
fprintf('\nAnalyzing lattice properties...\n');

for method_idx = 1:num_methods
    fprintf('Method: %s\n', methods{method_idx});
    
    for p_idx = 1:length(p_values)
        p = p_values(p_idx);
        
        for trial = 1:num_trials
            lattice = lattice_data{method_idx, p_idx, trial};
            
            % Comprehensive analysis
            analysis = analyze_lattice_properties(lattice, p);
            
            % Extract key metrics
            alpha_values(method_idx, p_idx, trial) = analysis.growth_exponent;
            connectivity_data(method_idx, p_idx, trial) = analysis.connectivity;
            fractal_dimensions(method_idx, p_idx, trial) = analysis.fractal_dimension;
            pore_size_distributions{method_idx, p_idx, trial} = analysis.pore_analysis.pore_size_distribution;
        end
    end
end

%% Tunable Gel-Point Analysis
fprintf('\nAnalyzing tunable gel-point positioning...\n');

% Calculate average properties
alpha_avg = mean(alpha_values, 3);
connectivity_avg = mean(connectivity_data, 3);
fractal_avg = mean(fractal_dimensions, 3);

% Find gel-points (where alpha drops significantly)
gel_points = zeros(num_methods, 1);
for method_idx = 1:num_methods
    alpha_curve = alpha_avg(method_idx, :);
    [~, max_idx] = max(alpha_curve);
    
    % Find where alpha drops to 80% of maximum
    threshold = 0.8 * max(alpha_curve);
    drop_idx = find(alpha_curve < threshold, 1);
    
    if ~isempty(drop_idx)
        gel_points(method_idx) = p_values(drop_idx);
    else
        gel_points(method_idx) = p_values(end);
    end
end

%% Quantify Differences Between Models
fprintf('\nQuantifying differences between models...\n');

% Calculate pairwise differences
differences = struct();
for i = 1:num_methods
    for j = i+1:num_methods
        pair_name = sprintf('%s_vs_%s', methods{i}, methods{j});
        
        % Alpha curve differences
        alpha_diff = mean(abs(alpha_avg(i, :) - alpha_avg(j, :)));
        
        % Connectivity differences
        conn_diff = mean(abs(connectivity_avg(i, :) - connectivity_avg(j, :)));
        
        % Fractal dimension differences
        fractal_diff = mean(abs(fractal_avg(i, :) - fractal_avg(j, :)));
        
        % Gel-point differences
        gel_diff = abs(gel_points(i) - gel_points(j));
        
        differences.(pair_name) = struct(...
            'alpha_difference', alpha_diff, ...
            'connectivity_difference', conn_diff, ...
            'fractal_difference', fractal_diff, ...
            'gel_point_difference', gel_diff);
    end
end

%% Create Comprehensive Visualizations
fprintf('\nCreating comprehensive visualizations...\n');

% Figure 1: Growth Exponent Comparison
figure('Position', [100, 100, 1200, 800]);

subplot(2, 2, 1);
colors = [0.2, 0.4, 0.8; 0.8, 0.2, 0.2; 0.2, 0.8, 0.2; 0.8, 0.4, 0.2; 0.6, 0.2, 0.8];
for method_idx = 1:num_methods
    alpha_curve = alpha_avg(method_idx, :);
    alpha_std = std(alpha_values(method_idx, :, :), 0, 3);
    
    errorbar(p_values, alpha_curve, alpha_std, 'Color', colors(method_idx, :), ...
             'LineWidth', 2, 'DisplayName', methods{method_idx});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Growth Exponent α');
title('Growth Exponent Comparison');
legend('Location', 'northeast');
grid on;

% Add gel-points
for method_idx = 1:num_methods
    xline(gel_points(method_idx), '--', 'Color', colors(method_idx, :), ...
          'LineWidth', 1.5, 'DisplayName', sprintf('%s gel-point', methods{method_idx}));
end

% Figure 2: Connectivity Comparison
subplot(2, 2, 2);
for method_idx = 1:num_methods
    conn_curve = connectivity_avg(method_idx, :);
    conn_std = std(connectivity_data(method_idx, :, :), 0, 3);
    
    errorbar(p_values, conn_curve, conn_std, 'Color', colors(method_idx, :), ...
             'LineWidth', 2, 'DisplayName', methods{method_idx});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Connectivity');
title('Connectivity Comparison');
legend('Location', 'northeast');
grid on;

% Figure 3: Fractal Dimension Comparison
subplot(2, 2, 3);
for method_idx = 1:num_methods
    fractal_curve = fractal_avg(method_idx, :);
    fractal_std = std(fractal_dimensions(method_idx, :, :), 0, 3);
    
    errorbar(p_values, fractal_curve, fractal_std, 'Color', colors(method_idx, :), ...
             'LineWidth', 2, 'DisplayName', methods{method_idx});
    hold on;
end
xlabel('Occupation Probability p');
ylabel('Fractal Dimension');
title('Fractal Dimension Comparison');
legend('Location', 'northeast');
grid on;

% Figure 4: Gel-Point Comparison
subplot(2, 2, 4);
bar(gel_points, 'FaceColor', 'flat', 'CData', colors);
set(gca, 'XTickLabel', methods);
ylabel('Gel-Point (p_c'')');
title('Gel-Point Comparison');
grid on;
xtickangle(45);

sgtitle('Tunable Gel-Point Lattice Generator Test Results', 'FontSize', 16, 'FontWeight', 'bold');

% Save Figure 1
saveas(gcf, fullfile(output_dir, 'tunable_gel_point_comparison.png'));

%% Create Model Difference Analysis
figure('Position', [100, 100, 1200, 600]);

% Extract difference data
pair_names = fieldnames(differences);
num_pairs = length(pair_names);

alpha_diffs = zeros(num_pairs, 1);
conn_diffs = zeros(num_pairs, 1);
fractal_diffs = zeros(num_pairs, 1);
gel_diffs = zeros(num_pairs, 1);

for i = 1:num_pairs
    pair = differences.(pair_names{i});
    alpha_diffs(i) = pair.alpha_difference;
    conn_diffs(i) = pair.connectivity_difference;
    fractal_diffs(i) = pair.fractal_difference;
    gel_diffs(i) = pair.gel_point_difference;
end

% Plot differences
subplot(1, 3, 1);
bar(alpha_diffs, 'FaceColor', [0.2, 0.6, 0.8]);
set(gca, 'XTickLabel', pair_names);
ylabel('Alpha Difference');
title('Growth Exponent Differences');
xtickangle(45);
grid on;

subplot(1, 3, 2);
bar(conn_diffs, 'FaceColor', [0.8, 0.4, 0.2]);
set(gca, 'XTickLabel', pair_names);
ylabel('Connectivity Difference');
title('Connectivity Differences');
xtickangle(45);
grid on;

subplot(1, 3, 3);
bar(gel_diffs, 'FaceColor', [0.6, 0.8, 0.2]);
set(gca, 'XTickLabel', pair_names);
ylabel('Gel-Point Difference');
title('Gel-Point Differences');
xtickangle(45);
grid on;

sgtitle('Model Difference Analysis', 'FontSize', 16, 'FontWeight', 'bold');

% Save Figure 2
saveas(gcf, fullfile(output_dir, 'model_difference_analysis.png'));

%% Create Lattice Visualization
figure('Position', [100, 100, 1200, 800]);

% Select a representative p-value for visualization
vis_p_idx = find(p_values >= 0.4, 1);
vis_p = p_values(vis_p_idx);

for method_idx = 1:num_methods
    subplot(2, 3, method_idx);
    
    % Use first trial for visualization
    lattice = lattice_data{method_idx, vis_p_idx, 1};
    
    % Create 2D slice for visualization
    lattice_slice = lattice(:, :, round(L/2));
    
    imagesc(lattice_slice);
    title(sprintf('%s (p=%.2f)', methods{method_idx}, vis_p));
    axis equal; axis tight;
    colormap(gca, [1 1 1; 0 0 0]);
    set(gca, 'XTick', [], 'YTick', []);
    
    % Add statistics
    density = sum(lattice(:)) / numel(lattice);
    connectivity = connectivity_avg(method_idx, vis_p_idx);
    fractal_dim = fractal_avg(method_idx, vis_p_idx);
    
    text(0.02, 0.98, sprintf('Density: %.3f\nConn: %.3f\nFractal: %.3f', ...
         density, connectivity, fractal_dim), ...
         'Units', 'normalized', 'VerticalAlignment', 'top', ...
         'BackgroundColor', 'white', 'FontSize', 8);
end

% Add overall statistics
subplot(2, 3, 6);
text(0.1, 0.9, 'Model Comparison Summary:', 'FontSize', 12, 'FontWeight', 'bold');
y_pos = 0.8;
for method_idx = 1:num_methods
    text(0.1, y_pos, sprintf('%s: Gel-point = %.3f', methods{method_idx}, gel_points(method_idx)), ...
         'FontSize', 10);
    y_pos = y_pos - 0.1;
end
axis off;

sgtitle('Lattice Visualization and Statistics', 'FontSize', 16, 'FontWeight', 'bold');

% Save Figure 3
saveas(gcf, fullfile(output_dir, 'lattice_visualization_comparison.png'));

%% Print Summary Results
fprintf('\n=== SUMMARY RESULTS ===\n\n');

fprintf('Gel-Point Positions:\n');
for method_idx = 1:num_methods
    fprintf('  %s: p_c'' = %.3f\n', methods{method_idx}, gel_points(method_idx));
end

fprintf('\nModel Differences (Average):\n');
for i = 1:num_pairs
    pair = differences.(pair_names{i});
    fprintf('  %s:\n', pair_names{i});
    fprintf('    Alpha difference: %.4f\n', pair.alpha_difference);
    fprintf('    Connectivity difference: %.4f\n', pair.connectivity_difference);
    fprintf('    Fractal difference: %.4f\n', pair.fractal_difference);
    fprintf('    Gel-point difference: %.4f\n', pair.gel_point_difference);
    fprintf('\n');
end

% Save results
save(fullfile(output_dir, 'tunable_gel_point_results.mat'), ...
     'results', 'alpha_values', 'connectivity_data', 'fractal_dimensions', ...
     'gel_points', 'differences', 'p_values', 'methods');

fprintf('Results saved to: %s\n', fullfile(output_dir, 'tunable_gel_point_results.mat'));
fprintf('Figures saved to: %s\n', output_dir);
fprintf('\nTest completed successfully!\n');

%% Helper Functions

function lattice = generate_random_lattice(L, p)
    % Generate random percolation lattice
    lattice = rand(L, L, L) < p;
end

function lattice = generate_templated_lattice(L, p, method)
    % Generate templated lattice (6N or 26N)
    lattice = false(L, L, L);
    
    % Start with a seed
    center = round(L/2);
    lattice(center, center, center) = true;
    
    % Grow according to method
    if strcmp(method, '6N')
        % 6-neighbor connectivity
        neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];
    else % 26N
        % 26-neighbor connectivity
        [X, Y, Z] = meshgrid(-1:1, -1:1, -1:1);
        neighbors = [X(:), Y(:), Z(:)];
        neighbors(all(neighbors == 0, 2), :) = []; % Remove center
    end
    
    % Grow until target density
    target_sites = round(p * L^3);
    current_sites = 1;
    
    while current_sites < target_sites
        % Find occupied sites
        [occupied_x, occupied_y, occupied_z] = ind2sub([L, L, L], find(lattice));
        
        if isempty(occupied_x)
            break;
        end
        
        % Randomly select an occupied site
        idx = randi(length(occupied_x));
        x = occupied_x(idx);
        y = occupied_y(idx);
        z = occupied_z(idx);
        
        % Try to add a neighbor
        for n = 1:size(neighbors, 1)
            nx = x + neighbors(n, 1);
            ny = y + neighbors(n, 2);
            nz = z + neighbors(n, 3);
            
            if nx >= 1 && nx <= L && ny >= 1 && ny <= L && nz >= 1 && nz <= L
                if ~lattice(nx, ny, nz) && rand < 0.5
                    lattice(nx, ny, nz) = true;
                    current_sites = current_sites + 1;
                    break;
                end
            end
        end
    end
end
