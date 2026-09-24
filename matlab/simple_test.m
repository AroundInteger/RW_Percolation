% SIMPLE_TEST Simple test for the lattice visualization function
% Run this to test basic functionality

clear; clc; close all;

fprintf('=== Simple Lattice Visualization Test ===\n\n');

try
    % Test with very small parameters
    L_test = 20;  % Very small for quick testing
    p_test = [0.3];  % Single p-value
    
    fprintf('Testing with L=%d, p=[%.1f]\n', L_test, p_test(1));
    fprintf('This should complete quickly...\n\n');
    
    % Run visualization (don't save figures)
    visualize_lattice_types(L_test, p_test, false);
    
    fprintf('\n✓ Test completed successfully!\n');
    fprintf('The visualization function is working correctly.\n');
    
catch ME
    fprintf('\n✗ Test failed with error:\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('\nFull error details:\n');
    fprintf('%s\n', ME.getReport());
    
    % Check if it's a missing function issue
    if contains(ME.message, 'Unrecognized function')
        fprintf('\nThis suggests a missing function. Please check:\n');
        fprintf('1. generate_templated_growth_3d_advanced.m exists\n');
fprintf('2. analyze_3d_clusters.m exists\n');
fprintf('3. All files are in the MATLAB path\n');
fprintf('4. Output will be saved to Clusters/ directory\n');
    end
end

fprintf('\n=== Test Complete ===\n');
