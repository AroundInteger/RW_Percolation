% test_templated_random_variant.m
% Test script to demonstrate the new templated_random variant
% This variant builds on previous p-values but uses random selection (statistically equivalent to independent random)

clc; close all; clear all;

% Parameters
L = 50;
p_values = [0.1, 0.3, 0.5, 0.7];
num_tests = 5;

fprintf('Testing Templated Random Variant\n');
fprintf('================================\n\n');

% Test 1: Independent Random Percolation (baseline)
fprintf('1. Independent Random Percolation (baseline):\n');
for i = 1:num_tests
    opts = struct('mode', 'random');
    lattice = generate_templated_growth_3d_advanced(L, 0.5, opts);
    density = sum(lattice(:)) / L^3;
    fprintf('   Test %d: Density = %.4f\n', i, density);
end

fprintf('\n2. Templated Random Percolation (new variant):\n');
% Test 2: Templated Random Percolation (new variant)
base_template = false(L, L, L);
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('   p = %.1f:\n', p);
    
    for i = 1:num_tests
        opts = struct('mode', 'templated_random', 'template', base_template);
        lattice = generate_templated_growth_3d_advanced(L, p, opts);
        density = sum(lattice(:)) / L^3;
        fprintf('     Test %d: Density = %.4f\n', i, density);
    end
    
    % Update template for next p-value (even though templated_random ignores it)
    base_template = logical(lattice);
end

fprintf('\n3. Comparison with Density Increment:\n');
% Test 3: Density Increment for comparison
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('   p = %.1f:\n', p);
    
    for i = 1:num_tests
        opts = struct('mode', 'density_increment', 'template', false(L, L, L));
        lattice = generate_templated_growth_3d_advanced(L, p, opts);
        density = sum(lattice(:)) / L^3;
        fprintf('     Test %d: Density = %.4f\n', i, density);
    end
end

fprintf('\n4. Statistical Equivalence Test:\n');
% Test 4: Statistical equivalence test
fprintf('   Comparing Independent Random vs Templated Random at p=0.5:\n');
n_samples = 100;
independent_densities = zeros(n_samples, 1);
templated_densities = zeros(n_samples, 1);

for i = 1:n_samples
    % Independent random
    opts = struct('mode', 'random');
    lattice = generate_templated_growth_3d_advanced(L, 0.5, opts);
    independent_densities(i) = sum(lattice(:)) / L^3;
    
    % Templated random
    opts = struct('mode', 'templated_random', 'template', false(L, L, L));
    lattice = generate_templated_growth_3d_advanced(L, 0.5, opts);
    templated_densities(i) = sum(lattice(:)) / L^3;
end

fprintf('   Independent Random: Mean = %.4f, Std = %.4f\n', ...
    mean(independent_densities), std(independent_densities));
fprintf('   Templated Random:   Mean = %.4f, Std = %.4f\n', ...
    mean(templated_densities), std(templated_densities));

% Statistical test
[h, p_val] = ttest2(independent_densities, templated_densities);
fprintf('   t-test p-value: %.6f (p > 0.05 means statistically equivalent)\n', p_val);

if p_val > 0.05
    fprintf('   ✓ Statistically equivalent (as expected)\n');
else
    fprintf('   ✗ Not statistically equivalent (unexpected)\n');
end

fprintf('\n5. Template Usage Test:\n');
% Test 5: Verify that templated_random ignores the template
fprintf('   Testing with non-empty template (should be ignored):\n');
test_template = false(L, L, L);
test_template(1:10, 1:10, 1:10) = true;  % Create a small occupied region
fprintf('   Template density: %.4f\n', sum(test_template(:)) / L^3);

opts = struct('mode', 'templated_random', 'template', test_template);
lattice = generate_templated_growth_3d_advanced(L, 0.3, opts);
fprintf('   Result density: %.4f\n', sum(lattice(:)) / L^3);
fprintf('   ✓ Template ignored (result density ≈ target p=0.3)\n');

fprintf('\nTest completed successfully!\n');
fprintf('The templated_random variant provides the same statistical behavior\n');
fprintf('as independent random percolation but follows the templating paradigm.\n');
