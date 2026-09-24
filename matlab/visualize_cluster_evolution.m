% visualize_cluster_evolution.m
% Visualize cluster evolution as a function of percolation probability
% for different templating methods

clear; clc; close all;

% Parameters
L = 30;  % Smaller lattice for better visualization
p_values = [0.1, 0.3, 0.5, 0.7, 0.9];
methods = {'random', 'templated_6n', 'templated_26n'};
method_names = {'Random Percolation', '6N Templated', '26N Templated'};

% Create figure
figure('Position', [100, 100, 1200, 800]);

% Generate and visualize for each method
for method_idx = 1:length(methods)
    method = methods{method_idx};
    method_name = method_names{method_idx};
    
    fprintf('Generating visualizations for %s...\n', method_name);
    
    % Create subplot for this method
    subplot(3, 6, (method_idx-1)*6 + 1);
    text(0.5, 0.5, method_name, 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'FontSize', 12, 'FontWeight', 'bold');
    axis off;
    
    % Generate and visualize for each p-value
    for p_idx = 1:length(p_values)
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
        
        % Create subplot
        subplot(3, 6, (method_idx-1)*6 + p_idx + 1);
        
        % Show 2D slice (middle z-slice)
        z_slice = round(L/2);
        lattice_slice = lattice(:, :, z_slice);
        
        % Create image with different colors for different clusters
        [L_labeled, num_clusters] = bwlabeln(lattice, 6);
        cluster_slice = L_labeled(:, :, z_slice);
        
        % Create colored image
        if num_clusters > 0
            % Use different colors for different clusters
            colors = lines(num_clusters);
            colored_slice = zeros(L, L, 3);
            
            for cluster_id = 1:num_clusters
                cluster_mask = (cluster_slice == cluster_id);
                for c = 1:3
                    colored_slice(:, :, c) = colored_slice(:, :, c) + ...
                        cluster_mask * colors(cluster_id, c);
                end
            end
        else
            colored_slice = zeros(L, L, 3);
        end
        
        % Display image
        imshow(colored_slice);
        title(sprintf('p = %.1f', p), 'FontSize', 10);
        
        % Add percolation information
        if num_clusters > 0
            cluster_sizes = zeros(num_clusters, 1);
            for i = 1:num_clusters
                cluster_sizes(i) = sum(L_labeled(:) == i);
            end
            largest_cluster = max(cluster_sizes);
            largest_fraction = largest_cluster / numel(lattice);
            
            % Check for sample-spanning cluster
            spanning = check_sample_spanning_cluster(L_labeled, num_clusters);
            
            % Add text annotation
            if spanning
                text(5, 5, 'SPANNING', 'Color', 'red', 'FontSize', 8, 'FontWeight', 'bold');
            end
            text(5, L-5, sprintf('Largest: %.1f%%', largest_fraction*100), ...
                 'Color', 'white', 'FontSize', 8);
        end
        
        axis off;
    end
end

% Add overall title
sgtitle('Cluster Evolution: Random vs Templated Percolation', 'FontSize', 16, 'FontWeight', 'bold');

% Add column labels
for p_idx = 1:length(p_values)
    subplot(3, 6, p_idx + 1);
    text(0.5, -0.1, sprintf('p = %.1f', p_values(p_idx)), ...
         'HorizontalAlignment', 'center', 'Units', 'normalized', ...
         'FontSize', 12, 'FontWeight', 'bold');
end

fprintf('Visualization completed.\n');

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
