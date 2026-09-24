% test_random_lattice.m
% Test script to verify random lattice generation is working correctly

clear; clc;

% Test parameters
L = 50;
p_values = [0.1, 0.3, 0.5, 0.7, 0.9];
num_trials = 3;

fprintf('Testing Random Lattice Generation\n');
fprintf('================================\n');

% Test random lattice generation
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('\nTesting p = %.1f\n', p);
    
    for trial = 1:num_trials
        % Generate random lattice
        lattice = generate_templated_growth_3d_advanced(L, p, 'random');
        
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

% Test gel-point calculation for random percolation
fprintf('\n\nTesting Gel-Point Calculation for Random Percolation\n');
fprintf('====================================================\n');

% Test with a known percolation threshold
test_p = 0.6884;  % Known percolation threshold for 3D
lattice = generate_templated_growth_3d_advanced(L, test_p, 'random');
gel_point = calculate_gel_point_accurate(lattice, test_p, 'random');

fprintf('Test p = %.4f (known percolation threshold)\n', test_p);
fprintf('Calculated gel-point = %.4f\n', gel_point);
fprintf('Expected gel-point ≈ %.4f\n', test_p);

if abs(gel_point - test_p) < 0.1
    fprintf('✓ Gel-point calculation appears correct\n');
else
    fprintf('✗ Gel-point calculation may have issues\n');
end

fprintf('\nRandom lattice test completed.\n');
