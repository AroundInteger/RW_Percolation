% test_6n_templated.m
% Test script to verify 6N templated lattice generation

clear; clc;

% Test parameters
L = 50;
p_values = [0.1, 0.3, 0.5, 0.7, 0.9];
num_trials = 3;

fprintf('Testing 6N Templated Lattice Generation\n');
fprintf('======================================\n');

% Test 6N templated lattice generation
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('\nTesting p = %.1f\n', p);
    
    for trial = 1:num_trials
        % Generate 6N templated lattice
        lattice = generate_templated_growth_3d_advanced(L, p, '6n_templated');
        
        % Calculate actual density
        actual_density = sum(lattice(:)) / numel(lattice);
        
        % Calculate basic properties
        num_occupied = sum(lattice(:));
        num_total = numel(lattice);
        
        fprintf('  Trial %d: Target p=%.3f, Actual p=%.3f, Occupied=%d/%d\n', ...
            trial, p, actual_density, num_occupied, num_total);
        
        % Verify density is reasonable (within 5% of target)
        if abs(actual_density - p) > 0.05
            fprintf('    WARNING: Density deviation > 5%%\n');
        end
    end
end

% Test gel-point calculation for 6N templated
fprintf('\n\nTesting Gel-Point Calculation for 6N Templated\n');
fprintf('==============================================\n');

% Test with a known percolation threshold
test_p = 0.6884;  % Known percolation threshold for 3D
lattice = generate_templated_growth_3d_advanced(L, test_p, '6n_templated');
gel_point = calculate_gel_point_accurate(lattice, test_p, '6n_templated');

fprintf('Test p = %.4f (known percolation threshold)\n', test_p);
fprintf('Calculated gel-point = %.4f\n', gel_point);
fprintf('Expected gel-point ≈ %.4f (should be higher than random)\n', test_p);

if gel_point > test_p
    fprintf('✓ Gel-point is higher than random (as expected for templated)\n');
else
    fprintf('✗ Gel-point should be higher than random for templated method\n');
end

fprintf('\n6N templated lattice test completed.\n');
