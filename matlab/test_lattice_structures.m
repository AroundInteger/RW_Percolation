% test_lattice_structures.m
% Test script to compare actual lattice structures between methods

clear; clc;

% Test parameters
L = 50;
p = 0.5;  % Test at moderate density
num_trials = 3;

fprintf('Testing Lattice Structure Differences\n');
fprintf('====================================\n');

methods = {'random', 'templated_6n', 'templated_26n'};
method_names = {'Random', '6N Templated', '26N Templated'};

% Store results
results = struct();

for method_idx = 1:length(methods)
    method = methods{method_idx};
    method_name = method_names{method_idx};
    
    fprintf('\n%s Method:\n', method_name);
    fprintf('----------------\n');
    
    % Initialize arrays for this method
    densities = zeros(num_trials, 1);
    connectivities = zeros(num_trials, 1);
    cluster_sizes = zeros(num_trials, 1);
    pore_sizes = zeros(num_trials, 1);
    fractal_dims = zeros(num_trials, 1);
    gel_points = zeros(num_trials, 1);
    
    for trial = 1:num_trials
        % Generate lattice
        if strcmp(method, 'templated_6n')
            lattice = generate_templated_lattice(L, p, '6N');
        elseif strcmp(method, 'templated_26n')
            lattice = generate_templated_lattice(L, p, '26N');
        else
            % For random, use the advanced function with proper opts
            opts = struct();
            opts.mode = 'random';
            lattice = generate_templated_growth_3d_advanced(L, p, opts);
        end
        
        % Analyze properties
        analysis = analyze_lattice_properties(lattice, p);
        
        % Store results
        densities(trial) = analysis.density;
        connectivities(trial) = analysis.connectivity;
        cluster_sizes(trial) = analysis.cluster_analysis.largest_cluster_size;
        pore_sizes(trial) = analysis.pore_analysis.largest_pore_size;
        fractal_dims(trial) = analysis.fractal_dimension;
        gel_points(trial) = analysis.gel_point;
        
        fprintf('  Trial %d: Density=%.3f, Connectivity=%.3f, Largest Cluster=%d, Largest Pore=%d, Fractal Dim=%.2f, Gel Point=%.3f\n', ...
            trial, analysis.density, analysis.connectivity, analysis.cluster_analysis.largest_cluster_size, ...
            analysis.pore_analysis.largest_pore_size, analysis.fractal_dimension, analysis.gel_point);
    end
    
    % Calculate averages
    results.(method).density_avg = mean(densities);
    results.(method).density_std = std(densities);
    results.(method).connectivity_avg = mean(connectivities);
    results.(method).connectivity_std = std(connectivities);
    results.(method).cluster_size_avg = mean(cluster_sizes);
    results.(method).cluster_size_std = std(cluster_sizes);
    results.(method).pore_size_avg = mean(pore_sizes);
    results.(method).pore_size_std = std(pore_sizes);
    results.(method).fractal_dim_avg = mean(fractal_dims);
    results.(method).fractal_dim_std = std(fractal_dims);
    results.(method).gel_point_avg = mean(gel_points);
    results.(method).gel_point_std = std(gel_points);
    
    fprintf('  Averages: Density=%.3f±%.3f, Connectivity=%.3f±%.3f, Cluster Size=%.0f±%.0f, Pore Size=%.0f±%.0f, Fractal Dim=%.2f±%.2f, Gel Point=%.3f±%.3f\n', ...
        results.(method).density_avg, results.(method).density_std, ...
        results.(method).connectivity_avg, results.(method).connectivity_std, ...
        results.(method).cluster_size_avg, results.(method).cluster_size_std, ...
        results.(method).pore_size_avg, results.(method).pore_size_std, ...
        results.(method).fractal_dim_avg, results.(method).fractal_dim_std, ...
        results.(method).gel_point_avg, results.(method).gel_point_std);
end

% Compare methods
fprintf('\n\nComparison Between Methods:\n');
fprintf('===========================\n');

% Compare connectivity
fprintf('\nConnectivity Comparison:\n');
for i = 1:length(methods)
    for j = i+1:length(methods)
        method1 = methods{i};
        method2 = methods{j};
        name1 = method_names{i};
        name2 = method_names{j};
        
        conn1 = results.(method1).connectivity_avg;
        conn2 = results.(method2).connectivity_avg;
        diff = abs(conn1 - conn2);
        
        fprintf('  %s vs %s: %.3f vs %.3f (diff: %.3f)\n', name1, name2, conn1, conn2, diff);
        
        if diff > 0.05
            fprintf('    ✓ Significant difference detected\n');
        else
            fprintf('    ✗ No significant difference\n');
        end
    end
end

% Compare gel-points
fprintf('\nGel-Point Comparison:\n');
for i = 1:length(methods)
    for j = i+1:length(methods)
        method1 = methods{i};
        method2 = methods{j};
        name1 = method_names{i};
        name2 = method_names{j};
        
        gel1 = results.(method1).gel_point_avg;
        gel2 = results.(method2).gel_point_avg;
        diff = abs(gel1 - gel2);
        
        fprintf('  %s vs %s: %.3f vs %.3f (diff: %.3f)\n', name1, name2, gel1, gel2, diff);
        
        if diff > 0.05
            fprintf('    ✓ Significant difference detected\n');
        else
            fprintf('    ✗ No significant difference\n');
        end
    end
end

fprintf('\nLattice structure comparison completed.\n');
