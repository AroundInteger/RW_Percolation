% analyze_percolation_behavior.m
% Quantitative analysis of percolation behavior for different methods

clear; clc; close all;

% Parameters
L = 50;
p_values = 0.1:0.05:0.9;
methods = {'random', 'templated_6n', 'templated_26n'};
method_names = {'Random', '6N Templated', '26N Templated'};
colors = [0.2, 0.6, 0.8; 0.8, 0.2, 0.2; 0.2, 0.8, 0.2];

fprintf('Analyzing percolation behavior...\n');

% Initialize results storage
num_p = length(p_values);
num_methods = length(methods);

largest_cluster_fractions = zeros(num_methods, num_p);
spanning_probabilities = zeros(num_methods, num_p);
num_clusters_avg = zeros(num_methods, num_p);
connectivities = zeros(num_methods, num_p);

% Analyze each method
for method_idx = 1:num_methods
    method = methods{method_idx};
    method_name = method_names{method_idx};
    
    fprintf('Analyzing %s...\n', method_name);
    
    for p_idx = 1:num_p
        p = p_values(p_idx);
        
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
    end
end

% Create visualizations
figure('Position', [100, 100, 1200, 800]);

% Plot 1: Largest cluster fraction
subplot(2, 2, 1);
hold on;
for method_idx = 1:num_methods
    plot(p_values, largest_cluster_fractions(method_idx, :), 'o-', ...
        'Color', colors(method_idx, :), 'LineWidth', 2, 'MarkerSize', 4);
end
xlabel('Occupation Probability (p)');
ylabel('Largest Cluster Fraction');
title('Largest Cluster Growth');
legend(method_names, 'Location', 'northwest');
grid on;

% Plot 2: Spanning probability
subplot(2, 2, 2);
hold on;
for method_idx = 1:num_methods
    plot(p_values, spanning_probabilities(method_idx, :), 'o-', ...
        'Color', colors(method_idx, :), 'LineWidth', 2, 'MarkerSize', 4);
end
xlabel('Occupation Probability (p)');
ylabel('Spanning Probability');
title('Sample-Spanning Cluster Formation');
legend(method_names, 'Location', 'northwest');
grid on;

% Plot 3: Number of clusters
subplot(2, 2, 3);
hold on;
for method_idx = 1:num_methods
    plot(p_values, num_clusters_avg(method_idx, :), 'o-', ...
        'Color', colors(method_idx, :), 'LineWidth', 2, 'MarkerSize', 4);
end
xlabel('Occupation Probability (p)');
ylabel('Number of Clusters');
title('Cluster Fragmentation');
legend(method_names, 'Location', 'northeast');
grid on;

% Plot 4: Connectivity
subplot(2, 2, 4);
hold on;
for method_idx = 1:num_methods
    plot(p_values, connectivities(method_idx, :), 'o-', ...
        'Color', colors(method_idx, :), 'LineWidth', 2, 'MarkerSize', 4);
end
xlabel('Occupation Probability (p)');
ylabel('Connectivity');
title('Site Connectivity');
legend(method_names, 'Location', 'northwest');
grid on;

sgtitle('Percolation Behavior Analysis', 'FontSize', 16, 'FontWeight', 'bold');

% Save figure
output_dir = '/Users/iMacPro/Documents/GitHub/RW_Percolation/paper_drafts/figures';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

filename = 'percolation_behavior_analysis.png';
filepath = fullfile(output_dir, filename);
saveas(gcf, filepath);

% Calculate gel-points based on spanning probability
fprintf('\nGel-Point Analysis:\n');
fprintf('==================\n');

for method_idx = 1:num_methods
    method_name = method_names{method_idx};
    
    % Find where spanning probability crosses 0.5
    spanning_curve = spanning_probabilities(method_idx, :);
    gel_point_idx = find(spanning_curve >= 0.5, 1);
    
    if ~isempty(gel_point_idx)
        gel_point = p_values(gel_point_idx);
    else
        gel_point = NaN;
    end
    
    % Also find where largest cluster fraction crosses 0.5
    largest_curve = largest_cluster_fractions(method_idx, :);
    gel_point_largest_idx = find(largest_curve >= 0.5, 1);
    
    if ~isempty(gel_point_largest_idx)
        gel_point_largest = p_values(gel_point_largest_idx);
    else
        gel_point_largest = NaN;
    end
    
    fprintf('%s:\n', method_name);
    fprintf('  Gel-point (spanning): %.3f\n', gel_point);
    fprintf('  Gel-point (largest):  %.3f\n', gel_point_largest);
    fprintf('  Max connectivity:     %.3f\n', max(connectivities(method_idx, :)));
    fprintf('\n');
end

fprintf('Analysis completed. Figure saved to: %s\n', filepath);

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
