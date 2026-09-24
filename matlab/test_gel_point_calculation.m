% test_gel_point_calculation.m
% Test script to compare gel-point calculation methods

clear; clc;

% Test parameters
L = 50;
p_values = [0.1, 0.3, 0.5, 0.7, 0.9];
num_trials = 3;

fprintf('Testing Gel-Point Calculation Methods\n');
fprintf('====================================\n');

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
        
        % Calculate gel-point based on connectivity (more sophisticated)
        gel_point_connectivity = calculate_gel_point_from_connectivity(lattice, p);
        
        fprintf('  p=%.1f: Accurate=%.3f, Analysis=%.3f, Connectivity=%.3f\n', ...
            p, gel_point_accurate, gel_point_analysis, gel_point_connectivity);
    end
end

fprintf('\n\nGel-Point Calculation Comparison:\n');
fprintf('================================\n');
fprintf('Method                | Expected | Accurate | Analysis | Connectivity\n');
fprintf('----------------------|----------|----------|----------|-------------\n');
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
    gel_point_connectivity = calculate_gel_point_from_connectivity(lattice, p);
    
    fprintf('%-20s | %8.4f | %8.4f | %8.4f | %11.4f\n', ...
        method_name, expected_gel, gel_point_accurate, gel_point_analysis, gel_point_connectivity);
end

fprintf('\nGel-point calculation test completed.\n');

function gel_point = calculate_gel_point_from_connectivity(lattice, p)
    % Calculate gel-point based on connectivity analysis
    % This is a more sophisticated approach than the simple estimate_gel_point
    
    % Analyze the lattice structure
    analysis = analyze_lattice_properties(lattice, p);
    connectivity = analysis.connectivity;
    density = analysis.density;
    
    % Find connected components
    [L, num_clusters] = bwlabeln(lattice, 6);
    
    if num_clusters == 0
        gel_point = 0.0;
        return;
    end
    
    % Calculate cluster sizes
    cluster_sizes = zeros(num_clusters, 1);
    for i = 1:num_clusters
        cluster_sizes(i) = sum(L(:) == i);
    end
    
    largest_cluster_size = max(cluster_sizes);
    total_sites = numel(lattice);
    largest_cluster_fraction = largest_cluster_size / total_sites;
    
    % Estimate gel-point based on multiple factors
    % Higher connectivity and larger clusters suggest earlier gel formation
    
    % Base gel-point from percolation theory
    base_gel_point = 0.6884;
    
    % Adjust based on connectivity (higher connectivity = earlier gel)
    connectivity_factor = (connectivity - 0.5) * 0.3;  % Scale factor
    
    % Adjust based on largest cluster size (larger clusters = earlier gel)
    cluster_factor = (largest_cluster_fraction - 0.5) * 0.2;  % Scale factor
    
    % Calculate final gel-point
    gel_point = base_gel_point + connectivity_factor + cluster_factor;
    
    % Ensure reasonable bounds
    gel_point = max(0.3, min(0.95, gel_point));
end
