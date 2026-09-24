% TEST_LATTICE_VISUALIZATION Test script for the lattice visualization function
%
% This script tests the basic functionality of visualize_lattice_types
% to ensure it works correctly before running the full demo.

clear; clc; close all;

fprintf('=== Testing Lattice Visualization Function ===\n\n');

%% Test 1: Basic functionality with small lattice
fprintf('Test 1: Basic functionality with small lattice (L=30)\n');
try
    L_test = 30;
    p_test = [0.2, 0.5];
    
    fprintf('  Testing with L=%d, p=[%.1f, %.1f]\n', L_test, p_test(1), p_test(2));
    
    % Run visualization (don't save figures for testing)
    visualize_lattice_types(L_test, p_test, false);
    
    fprintf('  ✓ Basic functionality test passed\n\n');
catch ME
    fprintf('  ✗ Basic functionality test failed: %s\n', ME.message);
    fprintf('  Error details: %s\n', ME.getReport());
    return;
end

%% Test 2: Verify lattice generation
fprintf('Test 2: Verify lattice generation\n');
try
    % Check if lattices were generated correctly
    L = 30;
    p = 0.3;
    
    % Test individual lattice generation
    opts = struct('mode', 'templated', 'connectivity', 6, 'periodic', false);
    test_lattice = generate_templated_growth_3d_advanced(L, p, opts);
    
    % Verify lattice properties
    if size(test_lattice, 1) == L && size(test_lattice, 2) == L && size(test_lattice, 3) == L
        fprintf('  ✓ Lattice size verification passed\n');
    else
        fprintf('  ✗ Lattice size verification failed\n');
        return;
    end
    
    % Verify density is reasonable
    density = sum(test_lattice(:)) / L^3;
    if density > 0 && density < 1
        fprintf('  ✓ Lattice density verification passed (density = %.4f)\n', density);
    else
        fprintf('  ✗ Lattice density verification failed (density = %.4f)\n', density);
        return;
    end
    
    fprintf('  ✓ Lattice generation test passed\n\n');
    
catch ME
    fprintf('  ✗ Lattice generation test failed: %s\n', ME.message);
    return;
end

%% Test 3: Test different lattice types
fprintf('Test 3: Test different lattice types\n');
try
    L = 30;
    p = 0.4;
    
    % Test all 7 lattice types
    lattice_types = {'templated', 'density_increment', 'random', 'templated', 'templated', 'templated', 'templated'};
    connectivity = [6, 0, 0, 26, 6, 6, 6];
    periodic = [false, false, false, false, true, false, false];
    min_neighbors = [1, 1, 1, 1, 1, 1, 2];
    
    for i = 1:7
        opts = struct('mode', lattice_types{i});
        if connectivity(i) > 0
            opts.connectivity = connectivity(i);
        end
        if periodic(i)
            opts.periodic = true;
        end
        if min_neighbors(i) > 1
            opts.min_neighbors = min_neighbors(i);
        end
        
        test_lat = generate_templated_growth_3d_advanced(L, p, opts);
        fprintf('  ✓ Lattice type %d generated successfully\n', i);
    end
    
    fprintf('  ✓ All lattice types test passed\n\n');
    
catch ME
    fprintf('  ✗ Lattice types test failed: %s\n', ME.message);
    return;
end

%% Test 4: Test cluster analysis
fprintf('Test 4: Test cluster analysis\n');
try
    L = 30;
    p = 0.5;
    
    opts = struct('mode', 'templated');
    test_lattice = generate_templated_growth_3d_advanced(L, p, opts);
    
    [num_clusters, cluster_sizes, cluster_labels] = analyze_3d_clusters(test_lattice);
    
    if num_clusters > 0 && max(cluster_sizes) > 0
        fprintf('  ✓ Cluster analysis test passed\n');
        fprintf('    Found %d clusters, largest size: %d\n', num_clusters, max(cluster_sizes));
    else
        fprintf('  ✗ Cluster analysis test failed\n');
        return;
    end
    
    fprintf('  ✓ Cluster analysis test passed\n\n');
    
catch ME
    fprintf('  ✗ Cluster analysis test failed: %s\n', ME.message);
    return;
end

%% Test 5: Performance test
fprintf('Test 5: Performance test\n');
try
    L_sizes = [20, 30, 40];
    p = 0.3;
    
    fprintf('  Testing performance with different lattice sizes:\n');
    fprintf('  %-10s %-15s %-15s\n', 'Size', 'Memory (MB)', 'Runtime (s)');
    
    for L_size = L_sizes
        % Estimate memory
        memory_mb = (L_size^3 * 8) / (1024^2);
        
        % Time generation
        tic;
        opts = struct('mode', 'templated');
        test_lattice = generate_templated_growth_3d_advanced(L_size, p, opts);
        runtime = toc;
        
        fprintf('  %-10d %-15.2f %-15.4f\n', L_size, memory_mb, runtime);
    end
    
    fprintf('  ✓ Performance test passed\n\n');
    
catch ME
    fprintf('  ✗ Performance test failed: %s\n', ME.message);
    return;
end

%% All tests passed
fprintf('=== All Tests Passed! ===\n');
fprintf('The lattice visualization function is working correctly.\n');
fprintf('You can now run the full demo: demo_lattice_visualization\n');
fprintf('Or use the function directly: visualize_lattice_types(60, [0.2, 0.5, 0.7])\n\n');

%% Clean up
close all;
fprintf('Test completed successfully!\n');
