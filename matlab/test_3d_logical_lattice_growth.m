% Test script for 3D Logical Lattice Growth
% Tests the generate_templated_growth_3d_logical function
clear; clc; close all;

%% Test Parameters
p_c_prime = 0.6884;
L = 500;  % Lattice size (reduced for 3D to avoid memory issues)
p_values = [0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5];
p_values = [0.1, 0.3116, 0.45, 0.6884, 0.85];

p_values = [0:0.05:0.3, 0.3116,0.35:0.05:0.6,linspace(0.6,0.75,21),p_c_prime, 0.8, 0.85, 0.9, 0.95];
p_values = unique(p_values);
num_tests = 3;  % Number of test runs per probability (reduced for 3D)

fprintf('=== Testing 3D Logical Lattice Growth ===\n');
fprintf('Lattice size: %d x %d x %d\n', L, L, L);
fprintf('Memory per lattice: %.2f MB\n', (L^3 * 8) / (1024^2));

%% Test 1: Basic Growth Verification
fprintf('\n=== Testing Basic Growth Patterns ===\n');
figure('Position', [100, 100, 1400, 1000]);

% Test with a subset of p_values to avoid too many subplots
test_p_values = p_values(1:min(8, length(p_values)));
lattice = rand(L,L,L)<p_values(1);
for i = 1:length(test_p_values)
    subplot(2, 4, i);
    
    % Generate lattice
    lattice = generate_templated_growth_3d_logical(L, test_p_values(i),lattice);
    
    % Create 2D slice visualization (middle slice in z-direction)
    z_slice = round(L/2);
    lattice_slice = lattice(:, :, z_slice);
    
    % Visualize the slice
    imagesc(lattice_slice);
    colormap([1 1 1; 0 0 0]); % White for empty, black for occupied
    axis equal tight;
    title(sprintf('p = %.2f (%.1f%% achieved)', test_p_values(i), 100*sum(lattice(:))/L^3));
    
    % Verify connectivity
    [num_clusters, cluster_sizes] = analyze_3d_clusters(lattice);
    fprintf('p=%.2f: %d clusters, largest=%d sites\n', test_p_values(i), num_clusters, max(cluster_sizes));
end

sgtitle('3D Growth Patterns - Z-Slice Visualizations');

%% Test 2: 3D Connectivity Verification
fprintf('\n=== Testing 3D Connectivity ===\n');
figure('Position', [200, 200, 1200, 800]);

% Test with higher density to see connectivity
test_p = 0.3;
lattice = generate_templated_growth_3d_logical(L, test_p);

% Analyze clusters
[num_clusters, cluster_sizes, cluster_labels] = analyze_3d_clusters(lattice);

% Create 3D visualization slices
subplot(2, 3, 1);
z_slice = round(L/2);
imagesc(lattice(:, :, z_slice));
title(sprintf('Z-slice (z=%d)', z_slice));
axis equal tight;

subplot(2, 3, 2);
y_slice = round(L/2);
imagesc(squeeze(lattice(:, y_slice, :)));
title(sprintf('Y-slice (y=%d)', y_slice));
axis equal tight;

subplot(2, 3, 3);
x_slice = round(L/2);
imagesc(squeeze(lattice(x_slice, :, :)));
title(sprintf('X-slice (x=%d)', x_slice));
axis equal tight;

% Show cluster analysis
subplot(2, 3, 4);
imagesc(cluster_labels(:, :, z_slice));
title(sprintf('Clusters (Z-slice): %d clusters', num_clusters));
axis equal tight;
colorbar;

subplot(2, 3, 5);
histogram(cluster_sizes, 20);
title('Cluster Size Distribution');
xlabel('Cluster Size');
ylabel('Frequency');

subplot(2, 3, 6);
% Show largest cluster
largest_cluster_mask = cluster_labels == 1;
largest_cluster_slice = largest_cluster_mask(:, :, z_slice);
imagesc(largest_cluster_slice);
title(sprintf('Largest Cluster (size=%d)', max(cluster_sizes)));
axis equal tight;

fprintf('Connectivity test: %d clusters found\n', num_clusters);
fprintf('Cluster sizes: %s\n', mat2str(sort(cluster_sizes, 'descend')));

%% Test 3: Template Reuse Verification
fprintf('\n=== Testing Template Reuse ===\n');
figure('Position', [300, 300, 1400, 400]);

% Start with base template
base_lattice = generate_templated_growth_3d_logical(L, 0.1);

% Grow incrementally
lattice_1 = generate_templated_growth_3d_logical(L, 0.2, base_lattice);
lattice_2 = generate_templated_growth_3d_logical(L, 0.3, lattice_1);
lattice_3 = generate_templated_growth_3d_logical(L, 0.4, lattice_2);

% Show middle slices
z_slice = round(L/2);

subplot(1, 4, 1);
imagesc(base_lattice(:, :, z_slice));
title('p = 0.1 (base)');
axis equal tight;

subplot(1, 4, 2);
imagesc(lattice_1(:, :, z_slice));
title('p = 0.2 (grown)');
axis equal tight;

subplot(1, 4, 3);
imagesc(lattice_2(:, :, z_slice));
title('p = 0.3 (grown)');
axis equal tight;

subplot(1, 4, 4);
imagesc(lattice_3(:, :, z_slice));
title('p = 0.4 (grown)');
axis equal tight;

sgtitle('3D Template Reuse Verification');

%% Test 4: Statistical Verification
fprintf('\n=== Testing Statistical Properties ===\n');
figure('Position', [400, 400, 1200, 800]);

achieved_densities = zeros(length(p_values), num_tests);
growth_efficiency = zeros(length(p_values), num_tests);
runtime_measurements = zeros(length(p_values), num_tests);

for i = 1:length(p_values)
    for j = 1:num_tests
        fprintf('Testing p=%.2f, run %d/%d...\n', p_values(i), j, num_tests);
        
        tic;
        lattice = generate_templated_growth_3d_logical(L, p_values(i));
        runtime = toc;
        
        achieved_densities(i, j) = sum(lattice(:)) / L^3;
        growth_efficiency(i, j) = achieved_densities(i, j) / p_values(i);
        runtime_measurements(i, j) = runtime;
    end
end

% Plot results
subplot(2, 3, 1);
errorbar(p_values, mean(achieved_densities, 2), std(achieved_densities, 0, 2), 'o-');
hold on;
plot([0, max(p_values)], [0, max(p_values)], '--k');
xlabel('Target Probability');
ylabel('Achieved Density');
title('Density Achievement');
legend('Achieved', 'Target', 'Location', 'best');
grid on;

subplot(2, 3, 2);
boxplot(growth_efficiency', p_values);
xlabel('Target Probability');
ylabel('Growth Efficiency (Achieved/Target)');
title('Growth Efficiency');
grid on;

subplot(2, 3, 3);
plot(p_values, std(achieved_densities, 0, 2), 'o-');
xlabel('Target Probability');
ylabel('Standard Deviation');
title('Density Variability');
grid on;

subplot(2, 3, 4);
errorbar(p_values, mean(runtime_measurements, 2), std(runtime_measurements, 0, 2), 'o-');
xlabel('Target Probability');
ylabel('Runtime (seconds)');
title('Performance');
grid on;

subplot(2, 3, 5);
scatter(achieved_densities(:), runtime_measurements(:), 'filled');
xlabel('Achieved Density');
ylabel('Runtime (seconds)');
title('Density vs Runtime');
grid on;

subplot(2, 3, 6);
histogram(runtime_measurements(:), 20);
title('Runtime Distribution');
xlabel('Runtime (seconds)');
ylabel('Frequency');

sgtitle('3D Growth Statistical Analysis');

%% Test 5: Memory and Performance Analysis
fprintf('\n=== Memory and Performance Analysis ===\n');

% Test different lattice sizes
test_sizes = [30, 40, 50, 60];
size_runtimes = zeros(length(test_sizes), 1);
size_memory = zeros(length(test_sizes), 1);

for i = 1:length(test_sizes)
    L_test = test_sizes(i);
    fprintf('Testing size %d x %d x %d...\n', L_test, L_test, L_test);
    
    % Estimate memory usage
    size_memory(i) = (L_test^3 * 8) / (1024^2); % MB
    
    % Time the generation
    tic;
    lattice = generate_templated_growth_3d_logical(L_test, 0.3);
    runtime = toc;
    size_runtimes(i) = runtime;
    
    fprintf('  Memory: %.2f MB, Runtime: %.3f s\n', size_memory(i), runtime);
end

figure('Position', [500, 500, 1000, 400]);

subplot(1, 2, 1);
plot(test_sizes, size_runtimes, 'o-', 'LineWidth', 2);
xlabel('Lattice Size');
ylabel('Runtime (seconds)');
title('Runtime vs Lattice Size');
grid on;

subplot(1, 2, 2);
plot(test_sizes, size_memory, 's-', 'LineWidth', 2);
xlabel('Lattice Size');
ylabel('Memory Usage (MB)');
title('Memory vs Lattice Size');
grid on;

sgtitle('3D Growth Scalability Analysis');

%% Test 6: Edge Case Testing
fprintf('\n=== Testing Edge Cases ===\n');

% Test with p = 0
fprintf('Testing p = 0...\n');
lattice_p0 = generate_templated_growth_3d_logical(L, 0);
fprintf('  Result: %d occupied sites (expected: 1)\n', sum(lattice_p0(:)));

% Test with p = 1 (should fail gracefully)
fprintf('Testing p = 1...\n');
try
    lattice_p1 = generate_templated_growth_3d_logical(L, 1);
    fprintf('  Result: %d occupied sites (expected: %d)\n', sum(lattice_p1(:)), L^3);
catch ME
    fprintf('  Error: %s\n', ME.message);
end

% Test with very small p
fprintf('Testing p = 0.001...\n');
lattice_small = generate_templated_growth_3d_logical(L, 0.001);
fprintf('  Result: %d occupied sites\n', sum(lattice_small(:)));

fprintf('\n=== 3D Logical Lattice Growth Testing Complete ===\n');

%% Helper Functions

function [num_clusters, cluster_sizes, cluster_labels] = analyze_3d_clusters(lattice)
% Analyze 3D clusters using bwconncomp
    
    % Convert to logical for bwconncomp
    bw = logical(lattice);
    
    % Find connected components (6-connectivity for 3D)
    cc = bwconncomp(bw, 6);
    
    num_clusters = cc.NumObjects;
    cluster_sizes = cellfun(@length, cc.PixelIdxList);
    
    % Create cluster labels if requested
    if nargout > 2
        cluster_labels = labelmatrix(cc);
    end
end
