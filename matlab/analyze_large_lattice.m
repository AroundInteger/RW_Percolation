% analyze_large_lattice.m
% Comprehensive analysis on large lattice (L=200) for better statistics

clear; clc; close all;

% Parameters for large lattice analysis
L = 200;  % Large lattice for better statistics
p_values = 0.1:0.05:0.9;
methods = {'random', 'templated_6n', 'templated_26n'};
method_names = {'Random', '6N Templated', '26N Templated'};
colors = [0.2, 0.6, 0.8; 0.8, 0.2, 0.2; 0.2, 0.8, 0.2];

fprintf('=== LARGE LATTICE ANALYSIS (L=%d) ===\n', L);
fprintf('This may take several minutes...\n\n');

% Initialize results storage
num_p = length(p_values);
num_methods = length(methods);

largest_cluster_fractions = zeros(num_methods, num_p);
spanning_probabilities = zeros(num_methods, num_p);
num_clusters_avg = zeros(num_methods, num_p);
connectivities = zeros(num_methods, num_p);
gel_points_percolation = zeros(num_methods, num_p);

% Initialize parallel pool
parpool(3); % Adjust the number of workers if needed

% Preallocate or copy p_values to a local variable
local_p_values = p_values;

% Analyze each method in parallel
parfor method_idx = 1:num_methods
    method = methods{method_idx};
    method_name = method_names{method_idx};

    fprintf('Analyzing %s...\n', method_name);

    for p_idx = 1:num_p
        p = local_p_values(p_idx);  % Use the local variable

        if mod(p_idx, 5) == 0  % Progress indicator
            fprintf('  Progress: p=%.2f (%d/%d)\n', p, p_idx, num_p);
        end

        % Generate lattice
        if strcmp(method, 'templated_6n')
            lattice = generate_templated_lattice(L, p, '6N');
        elseif strcmp(method, 'templated_26n')
            lattice = generate_templated_lattice(L, p, '26N');
        else
            opts = struct();
            opts.mode = 'random';
            lattice = generate_templated_growth_3d_advanced(L, p, opts);
        end

        % Analyze lattice
        analysis = analyze_lattice_properties(lattice, p);

        % Find connected components
        [L_labeled, num_clusters] = bwlabeln(lattice, 6);

        % Calculate largest cluster fraction
        if num_clusters > 0
            cluster_sizes = zeros(num_clusters, 1);
            for i = 1:num_clusters
                cluster_sizes(i) = sum(L_labeled(:) == i);
            end
            largest_cluster = max(cluster_sizes);
            largest_cluster_fractions(method_idx, p_idx) = largest_cluster / numel(lattice);
        else
            largest_cluster_fractions(method_idx, p_idx) = 0;
        end

        % Check for sample-spanning cluster
        spanning = check_sample_spanning_cluster(L_labeled, num_clusters);
        spanning_probabilities(method_idx, p_idx) = spanning;

        % Store other properties
        num_clusters_avg(method_idx, p_idx) = num_clusters;
        connectivities(method_idx, p_idx) = analysis.connectivity;

        % Calculate percolation-based gel-point
        gel_points_percolation(method_idx, p_idx) = calculate_percolation_gel_point(lattice, p);
    end

    fprintf('  %s analysis completed.\n\n', method_name);
end


% % Analyze each method
% for method_idx = 1:num_methods
%     method = methods{method_idx};
%     method_name = method_names{method_idx};
% 
%     fprintf('Analyzing %s...\n', method_name);
% 
%     for p_idx = 1:num_p
%         p = p_values(p_idx);
% 
%         if mod(p_idx, 5) == 0  % Progress indicator
%             fprintf('  Progress: p=%.2f (%d/%d)\n', p, p_idx, num_p);
%         end
% 
%         % Generate lattice
%         if strcmp(method, 'templated_6n')
%             lattice = generate_templated_lattice(L, p, '6N');
%         elseif strcmp(method, 'templated_26n')
%             lattice = generate_templated_lattice(L, p, '26N');
%         else
%             opts = struct();
%             opts.mode = 'random';
%             lattice = generate_templated_growth_3d_advanced(L, p, opts);
%         end
% 
%         % Analyze lattice
%         analysis = analyze_lattice_properties(lattice, p);
% 
%         % Find connected components
%         [L_labeled, num_clusters] = bwlabeln(lattice, 6);
% 
%         % Calculate largest cluster fraction
%         if num_clusters > 0
%             cluster_sizes = zeros(num_clusters, 1);
%             for i = 1:num_clusters
%                 cluster_sizes(i) = sum(L_labeled(:) == i);
%             end
%             largest_cluster = max(cluster_sizes);
%             largest_cluster_fractions(method_idx, p_idx) = largest_cluster / numel(lattice);
%         else
%             largest_cluster_fractions(method_idx, p_idx) = 0;
%         end
% 
%         % Check for sample-spanning cluster
%         spanning = check_sample_spanning_cluster(L_labeled, num_clusters);
%         spanning_probabilities(method_idx, p_idx) = spanning;
% 
%         % Store other properties
%         num_clusters_avg(method_idx, p_idx) = num_clusters;
%         connectivities(method_idx, p_idx) = analysis.connectivity;
% 
%         % Calculate percolation-based gel-point
%         gel_points_percolation(method_idx, p_idx) = calculate_percolation_gel_point(lattice, p);
%     end
% 
%     fprintf('  %s analysis completed.\n\n', method_name);
% end

% Create comprehensive visualizations
figure('Position', [100, 100, 1400, 1000]);

% Plot 1: Largest cluster fraction
subplot(2, 3, 1);
hold on;
for method_idx = 1:num_methods
    plot(p_values, largest_cluster_fractions(method_idx, :), 'o-', ...
        'Color', colors(method_idx, :), 'LineWidth', 2, 'MarkerSize', 3);
end
xlabel('Occupation Probability (p)');
ylabel('Largest Cluster Fraction');
title('Largest Cluster Growth (L=200)');
legend(method_names, 'Location', 'northwest');
grid on;

% Plot 2: Spanning probability
subplot(2, 3, 2);
hold on;
for method_idx = 1:num_methods
    plot(p_values, spanning_probabilities(method_idx, :), 'o-', ...
        'Color', colors(method_idx, :), 'LineWidth', 2, 'MarkerSize', 3);
end
xlabel('Occupation Probability (p)');
ylabel('Spanning Probability');
title('Sample-Spanning Cluster Formation (L=200)');
legend(method_names, 'Location', 'northwest');
grid on;

% Plot 3: Number of clusters
subplot(2, 3, 3);
hold on;
for method_idx = 1:num_methods
    plot(p_values, num_clusters_avg(method_idx, :), 'o-', ...
        'Color', colors(method_idx, :), 'LineWidth', 2, 'MarkerSize', 3);
end
xlabel('Occupation Probability (p)');
ylabel('Number of Clusters');
title('Cluster Fragmentation (L=200)');
legend(method_names, 'Location', 'northeast');
grid on;

% Plot 4: Connectivity
subplot(2, 3, 4);
hold on;
for method_idx = 1:num_methods
    plot(p_values, connectivities(method_idx, :), 'o-', ...
        'Color', colors(method_idx, :), 'LineWidth', 2, 'MarkerSize', 3);
end
xlabel('Occupation Probability (p)');
ylabel('Connectivity');
title('Site Connectivity (L=200)');
legend(method_names, 'Location', 'northwest');
grid on;

% Plot 5: Percolation-based gel-points
subplot(2, 3, 5);
hold on;
for method_idx = 1:num_methods
    plot(p_values, gel_points_percolation(method_idx, :), 'o-', ...
        'Color', colors(method_idx, :), 'LineWidth', 2, 'MarkerSize', 3);
end
xlabel('Occupation Probability (p)');
ylabel('Estimated Gel-Point');
title('Percolation-Based Gel-Point (L=200)');
legend(method_names, 'Location', 'northwest');
grid on;

% Plot 6: Comparison with theoretical values
subplot(2, 3, 6);
theoretical_gel_points = [0.6884, 0.8000, 0.8825];  % Expected values
hold on;
for method_idx = 1:num_methods
    plot(p_values, gel_points_percolation(method_idx, :), 'o-', ...
        'Color', colors(method_idx, :), 'LineWidth', 2, 'MarkerSize', 3);
    yline(theoretical_gel_points(method_idx), '--', 'Color', colors(method_idx, :), ...
        'LineWidth', 1, 'Alpha', 0.7);
end
xlabel('Occupation Probability (p)');
ylabel('Gel-Point');
title('Comparison with Theoretical Values');
legend([method_names, {'Theoretical Random', 'Theoretical 6N', 'Theoretical 26N'}], ...
    'Location', 'northwest');
grid on;

sgtitle('Large Lattice Analysis (L=200): Comprehensive Percolation Study', ...
    'FontSize', 16, 'FontWeight', 'bold');

% Save figure
output_dir = '/Users/iMacPro/Documents/GitHub/RW_Percolation/paper_drafts/figures';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

filename = 'large_lattice_analysis_L200.png';
filepath = fullfile(output_dir, filename);
saveas(gcf, filepath);

% Calculate and display gel-points
fprintf('\n=== GEL-POINT ANALYSIS (L=%d) ===\n', L);

for method_idx = 1:num_methods
    method_name = method_names{method_idx};
    theoretical = theoretical_gel_points(method_idx);
    
    % Find where spanning probability crosses 0.5
    spanning_curve = spanning_probabilities(method_idx, :);
    gel_point_idx = find(spanning_curve >= 0.5, 1);
    
    if ~isempty(gel_point_idx)
        gel_point_spanning = p_values(gel_point_idx);
    else
        gel_point_spanning = NaN;
    end
    
    % Find where largest cluster fraction crosses 0.5
    largest_curve = largest_cluster_fractions(method_idx, :);
    gel_point_largest_idx = find(largest_curve >= 0.5, 1);
    
    if ~isempty(gel_point_largest_idx)
        gel_point_largest = p_values(gel_point_largest_idx);
    else
        gel_point_largest = NaN;
    end
    
    % Average percolation-based gel-point
    avg_gel_point = mean(gel_points_percolation(method_idx, :));
    
    fprintf('\n%s:\n', method_name);
    fprintf('  Theoretical:           %.4f\n', theoretical);
    fprintf('  Gel-point (spanning):  %.4f\n', gel_point_spanning);
    fprintf('  Gel-point (largest):   %.4f\n', gel_point_largest);
    fprintf('  Avg percolation:       %.4f\n', avg_gel_point);
    fprintf('  Max connectivity:      %.4f\n', max(connectivities(method_idx, :)));
    
    % Calculate differences from theoretical
    if ~isnan(gel_point_spanning)
        diff_spanning = abs(gel_point_spanning - theoretical);
        fprintf('  Difference (spanning): %.4f\n', diff_spanning);
    end
    if ~isnan(gel_point_largest)
        diff_largest = abs(gel_point_largest - theoretical);
        fprintf('  Difference (largest):  %.4f\n', diff_largest);
    end
end

% Save results to file
results_file = fullfile(output_dir, 'large_lattice_results_L200.mat');
save(results_file, 'L', 'p_values', 'methods', 'method_names', ...
    'largest_cluster_fractions', 'spanning_probabilities', 'num_clusters_avg', ...
    'connectivities', 'gel_points_percolation', 'theoretical_gel_points');

fprintf('\n=== ANALYSIS COMPLETED ===\n');
fprintf('Results saved to: %s\n', results_file);
fprintf('Figure saved to: %s\n', filepath);

function spanning = check_sample_spanning_cluster(L_labeled, num_clusters)
    % Check if any cluster spans the sample
    [Lx, Ly, Lz] = size(L_labeled);
    spanning = false;
    
    for cluster_id = 1:num_clusters
        cluster_mask = (L_labeled == cluster_id);
        
        % Check if cluster spans in x-direction
        x_spanning = any(any(cluster_mask(1, :, :))) && any(any(cluster_mask(end, :, :)));
        
        % Check if cluster spans in y-direction  
        y_spanning = any(any(cluster_mask(:, 1, :))) && any(any(cluster_mask(:, end, :)));
        
        % Check if cluster spans in z-direction
        z_spanning = any(any(cluster_mask(:, :, 1))) && any(any(cluster_mask(:, :, end)));
        
        % Cluster is sample-spanning if it spans in at least one direction
        if x_spanning || y_spanning || z_spanning
            spanning = true;
            break;
        end
    end
end
