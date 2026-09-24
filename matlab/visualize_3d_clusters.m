% visualize_3d_clusters.m
% Create detailed 3D visualizations of clusters for different methods

clear; clc; close all;

% Parameters
L = 25;  % Smaller for 3D visualization
p_values = [0.3, 0.5, 0.7];  % Focus on key percolation values
methods = {'random', 'templated_6n', 'templated_26n'};
method_names = {'Random', '6N Templated', '26N Templated'};

% Create output directory
output_dir = '/Users/iMacPro/Documents/GitHub/RW_Percolation/paper_drafts/figures';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

fprintf('Creating 3D cluster visualizations...\n');

% Generate visualizations for each method and p-value
for method_idx = 1:length(methods)
    method = methods{method_idx};
    method_name = method_names{method_idx};
    
    for p_idx = 1:length(p_values)
        p = p_values(p_idx);
        
        fprintf('Generating %s at p=%.1f...\n', method_name, p);
        
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
        
        % Find connected components
        [L_labeled, num_clusters] = bwlabeln(lattice, 6);
        
        % Create figure
        figure('Position', [100, 100, 800, 600]);
        
        % 3D visualization
        subplot(2, 2, 1);
        [x, y, z] = ind2sub(size(lattice), find(lattice));
        scatter3(x, y, z, 20, 'filled', 'MarkerFaceColor', [0.2, 0.6, 0.8]);
        xlabel('X'); ylabel('Y'); zlabel('Z');
        title(sprintf('%s: p=%.1f (All Sites)', method_name, p));
        axis equal; grid on;
        
        % Show largest cluster only
        subplot(2, 2, 2);
        if num_clusters > 0
            cluster_sizes = zeros(num_clusters, 1);
            for i = 1:num_clusters
                cluster_sizes(i) = sum(L_labeled(:) == i);
            end
            [~, largest_cluster_id] = max(cluster_sizes);
            largest_cluster_mask = (L_labeled == largest_cluster_id);
            [x_large, y_large, z_large] = ind2sub(size(lattice), find(largest_cluster_mask));
            scatter3(x_large, y_large, z_large, 20, 'filled', 'MarkerFaceColor', [0.8, 0.2, 0.2]);
            title(sprintf('Largest Cluster (%d sites)', cluster_sizes(largest_cluster_id)));
        else
            title('No Clusters');
        end
        xlabel('X'); ylabel('Y'); zlabel('Z');
        axis equal; grid on;
        
        % 2D slices
        subplot(2, 2, 3);
        z_slice = round(L/2);
        cluster_slice = L_labeled(:, :, z_slice);
        imagesc(cluster_slice);
        colorbar;
        title(sprintf('Z-slice (z=%d)', z_slice));
        axis equal tight;
        
        subplot(2, 2, 4);
        y_slice = round(L/2);
        cluster_slice_y = squeeze(L_labeled(:, y_slice, :));
        imagesc(cluster_slice_y);
        colorbar;
        title(sprintf('Y-slice (y=%d)', y_slice));
        axis equal tight;
        
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
            info_text = sprintf('Clusters: %d\nLargest: %.1f%%\nSpanning: %s', ...
                num_clusters, largest_fraction*100, mat2str(spanning));
            annotation('textbox', [0.02, 0.02, 0.3, 0.1], 'String', info_text, ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        end
        
        % Save figure
        filename = sprintf('cluster_3d_%s_p%.1f.png', method, p);
        filepath = fullfile(output_dir, filename);
        saveas(gcf, filepath);
        
        % Also save as .fig for later editing
        fig_filename = sprintf('cluster_3d_%s_p%.1f.fig', method, p);
        fig_filepath = fullfile(output_dir, fig_filename);
        saveas(gcf, fig_filepath);
        
        close(gcf);
    end
end

% Create summary comparison figure
fprintf('Creating summary comparison...\n');
figure('Position', [100, 100, 1200, 400]);

for method_idx = 1:length(methods)
    method = methods{method_idx};
    method_name = method_names{method_idx};
    
    % Use p=0.5 for comparison
    p = 0.5;
    
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
    
    % Find connected components
    [L_labeled, num_clusters] = bwlabeln(lattice, 6);
    
    % Show 2D slice
    subplot(1, 3, method_idx);
    z_slice = round(L/2);
    cluster_slice = L_labeled(:, :, z_slice);
    imagesc(cluster_slice);
    colorbar;
    title(sprintf('%s\np=%.1f', method_name, p));
    axis equal tight;
    
    % Add cluster count
    if num_clusters > 0
        cluster_sizes = zeros(num_clusters, 1);
        for i = 1:num_clusters
            cluster_sizes(i) = sum(L_labeled(:) == i);
        end
        largest_cluster = max(cluster_sizes);
        largest_fraction = largest_cluster / numel(lattice);
        
        spanning = check_sample_spanning_cluster(L_labeled, num_clusters);
        
        xlabel(sprintf('Clusters: %d, Largest: %.1f%%, Spanning: %s', ...
            num_clusters, largest_fraction*100, mat2str(spanning)));
    end
end

sgtitle('Cluster Structure Comparison at p=0.5', 'FontSize', 16, 'FontWeight', 'bold');

% Save summary figure
summary_filename = 'cluster_comparison_summary.png';
summary_filepath = fullfile(output_dir, summary_filename);
saveas(gcf, summary_filepath);

fprintf('3D cluster visualization completed.\n');
fprintf('Images saved to: %s\n', output_dir);

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
