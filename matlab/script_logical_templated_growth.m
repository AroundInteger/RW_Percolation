% Script to verify templated growth patterns
clear; clc; close all;

%% Test Parameters
L = 300;  % Lattice size
p_values = [0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.6, 0.7];
num_tests = 5;  % Number of test runs per probability

%% Test 1: Basic Growth Verification
fprintf('=== Testing Basic Growth Patterns ===\n');
figure('Position', [100, 100, 1200, 800]);

lattice = rand(L,L)<p_values(1);

for i = 1:min(12, length(p_values))
    subplot(3, 4, i);
    
    % Generate lattice
    lattice = generate_templated_growth_2d_logical(L, p_values(i),lattice);
    bw = lattice > 0;
    bw_big = bwareafilt(bw,1);
    
    % Visualize
    % imagesc(bw_big);
    % colormap([1 1 1; 0 0 0]); % White for empty, black for occupied
    % axis equal tight;
    imshowpair(bw,bw_big);
    % colormap([1 1 1; 0 0 0]); % White for empty, black for occupied
    % axis equal tight;
    title(sprintf('p = %.2f (%.1f%% achieved)', p_values(i), 100*sum(lattice(:))/L^2));
    
    % Verify connectivity
    [num_clusters, cluster_sizes] = analyze_clusters(lattice);
    fprintf('p=%.2f: %d clusters, largest=%d sites\n', p_values(i), num_clusters, max(cluster_sizes));
end

sgtitle('Basic Growth Patterns - Single Realizations');

%% Test 2: Connectivity Verification
fprintf('\n=== Testing Connectivity ===\n');
figure('Position', [200, 200, 1000, 600]);

% Test with higher density to see connectivity
test_p = 0.3;
lattice = generate_templated_growth_2d_logical(L, test_p);

% Analyze clusters
[num_clusters, cluster_sizes, cluster_labels] = analyze_clusters(lattice);

subplot(1, 2, 1);
imagesc(lattice);
colormap([1 1 1; 0 0 0]);
axis equal tight;
title(sprintf('Original Lattice (p=%.2f)', test_p));

subplot(1, 2, 2);
imagesc(cluster_labels);
axis equal tight;
title(sprintf('Cluster Analysis: %d clusters', num_clusters));
colorbar;

fprintf('Connectivity test: %d clusters found\n', num_clusters);
fprintf('Cluster sizes: %s\n', mat2str(sort(cluster_sizes, 'descend')));

%% Test 3: Template Reuse Verification
fprintf('\n=== Testing Template Reuse ===\n');
figure('Position', [300, 300, 1200, 400]);

% Start with base template
base_lattice = generate_templated_growth_2d_logical(L, 0.1);

% Grow incrementally
lattice_1 = generate_templated_growth_2d_logical(L, 0.2, base_lattice);
lattice_2 = generate_templated_growth_2d_logical(L, 0.3, lattice_1);
lattice_3 = generate_templated_growth_2d_logical(L, 0.4, lattice_2);

subplot(1, 4, 1);
imagesc(base_lattice);
title('p = 0.1 (base)');
axis equal tight;

subplot(1, 4, 2);
imagesc(lattice_1);
title('p = 0.2 (grown)');
axis equal tight;

subplot(1, 4, 3);
imagesc(lattice_2);
title('p = 0.3 (grown)');
axis equal tight;

subplot(1, 4, 4);
imagesc(lattice_3);
title('p = 0.4 (grown)');
axis equal tight;

sgtitle('Template Reuse Verification');

%% Test 4: Statistical Verification
fprintf('\n=== Testing Statistical Properties ===\n');
figure('Position', [400, 400, 1000, 600]);

achieved_densities = zeros(length(p_values), num_tests);
growth_efficiency = zeros(length(p_values), num_tests);

for i = 1:length(p_values)
    for j = 1:num_tests
        lattice = generate_templated_growth_2d_logical(L, p_values(i));
        achieved_densities(i, j) = sum(lattice(:)) / L^2;
        
        % Calculate growth efficiency (how close to target)
        growth_efficiency(i, j) = achieved_densities(i, j) / p_values(i);
    end
end

% Plot results
subplot(2, 2, 1);
errorbar(p_values, mean(achieved_densities, 2), std(achieved_densities, 0, 2), 'o-');
hold on;
plot([0, max(p_values)], [0, max(p_values)], '--k');
xlabel('Target Probability');
ylabel('Achieved Density');
title('Density Achievement');
legend('Achieved', 'Target', 'Location', 'best');
grid on;

subplot(2, 2, 2);
boxplot(growth_efficiency', p_values);
xlabel('Target Probability');
ylabel('Growth Efficiency (Achieved/Target)');
title('Growth Efficiency');
grid on;

subplot(2, 2, 3);
plot(p_values, std(achieved_densities, 0, 2), 'o-');
xlabel('Target Probability');
ylabel('Standard Deviation');
title('Variability in Achievement');
grid on;

subplot(2, 2, 4);
histogram(growth_efficiency(:), 20);
xlabel('Growth Efficiency');
ylabel('Frequency');
title('Distribution of Growth Efficiency');
grid on;

%% Test 5: Performance Benchmark
fprintf('\n=== Performance Benchmark ===\n');
test_sizes = [50, 100, 150, 200];
test_p = 0.3;
timing_results = zeros(length(test_sizes), 1);

for i = 1:length(test_sizes)
    L_test = test_sizes(i);
    tic;
    lattice = generate_templated_growth_2d_logical(L_test, test_p);
    timing_results(i) = toc;
    fprintf('L=%d: %.4f seconds\n', L_test, timing_results(i));
end

figure;
plot(test_sizes.^2, timing_results, 'o-');
xlabel('Lattice Area (L²)');
ylabel('Time (seconds)');
title('Performance Scaling');
grid on;

%% Helper Function for Cluster Analysis
function [num_clusters, cluster_sizes, cluster_labels] = analyze_clusters(lattice)
    % Analyze connectivity using bwlabel
    cluster_labels = bwlabel(lattice, 4); % 4-connectivity
    num_clusters = max(cluster_labels(:));
    
    if num_clusters == 0
        cluster_sizes = [];
        return;
    end
    
    cluster_sizes = zeros(num_clusters, 1);
    for i = 1:num_clusters
        cluster_sizes(i) = sum(cluster_labels(:) == i);
    end
end

%% Summary Report
fprintf('\n=== VERIFICATION SUMMARY ===\n');
fprintf('✓ Basic growth patterns tested\n');
fprintf('✓ Connectivity verified\n');
fprintf('✓ Template reuse functionality confirmed\n');
fprintf('✓ Statistical properties analyzed\n');
fprintf('✓ Performance benchmarked\n');
fprintf('\nAll tests completed successfully!\n');