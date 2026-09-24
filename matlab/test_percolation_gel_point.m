% test_percolation_gel_point.m
% Test script to compare percolation-based gel-point calculation

clear; clc;

% Test parameters
L = 300;
p_values = [0.3, 0.6, 0.8];
num_trials = 3;

fprintf('Testing Percolation-Based Gel-Point Calculation\n');
fprintf('==============================================\n');

methods = {'random', 'templated_6n', 'templated_26n'};
method_names = {'Random', '6N Templated', '26N Templated'};

% Expected gel-points from previous analysis
expected_gel_points = [0.6827, 0.8000, 0.8825];

for method_idx = 1:length(methods)
    method = methods{method_idx};
    method_name = method_names{method_idx};
    expected_gel = expected_gel_points(method_idx);
    
    fprintf('\n%s Method (Expected: %.4f):\n', method_name, expected_gel);
    fprintf('----------------------------------------\n');
    
    % Test at different densities
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
        
        % Calculate gel-point using different methods
        gel_point_accurate = calculate_gel_point_accurate(lattice, p, method);
        analysis = analyze_lattice_properties(lattice, p);
        gel_point_analysis = analysis.gel_point;
        gel_point_percolation = calculate_percolation_gel_point(lattice, p);
        
        % Check for sample-spanning cluster
        [L_labeled, num_clusters] = bwlabeln(lattice, 6);
        sample_spanning = check_sample_spanning_cluster(L_labeled, num_clusters);
        
        fprintf('  p=%.1f: Accurate=%.3f, Analysis=%.3f, Percolation=%.3f, Spanning=%s\n', ...
            p, gel_point_accurate, gel_point_analysis, gel_point_percolation, ...
            mat2str(sample_spanning));
    end
end

fprintf('\n\nGel-Point Calculation Comparison:\n');
fprintf('================================\n');
fprintf('Method                | Expected | Accurate | Analysis | Percolation\n');
fprintf('----------------------|----------|----------|----------|------------\n');
for method_idx = 1:length(methods)
    method = methods{method_idx};
    method_name = method_names{method_idx};
    expected_gel = expected_gel_points(method_idx);
    
    % Test at p=0.5 for comparison
    p = 0.5;
    if strcmp(method, 'templated_6n')
        lattice = generate_templated_lattice(L, p, '6N');
    elseif strcmp(method, 'templated_26n')
        lattice = generate_templated_lattice(L, p, '26N');
    else
        opts = struct();
        opts.mode = 'random';
        lattice = generate_templated_growth_3d_advanced(L, p, opts);
    end
    
    gel_point_accurate = calculate_gel_point_accurate(lattice, p, method);
    analysis = analyze_lattice_properties(lattice, p);
    gel_point_analysis = analysis.gel_point;
    gel_point_percolation = calculate_percolation_gel_point(lattice, p);
    
    fprintf('%-20s | %8.4f | %8.4f | %8.4f | %11.4f\n', ...
        method_name, expected_gel, gel_point_accurate, gel_point_analysis, gel_point_percolation);
end

fprintf('\nPercolation-based gel-point test completed.\n');

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
