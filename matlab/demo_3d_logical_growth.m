% Simple demonstration of 3D Logical Lattice Growth
% Shows basic usage and visualizations
clear; clc; close all;

fprintf('=== 3D Logical Lattice Growth Demo ===\n');

%% Basic Example
L = 200;  % Small lattice for quick demo
p = 0.3;

fprintf('Generating 3D lattice: L=%d, p=%.2f\n', L, p);

% Generate lattice
lattice = generate_templated_growth_3d_logical(L, p);

fprintf('Generated lattice with %d occupied sites (%.3f density)\n', ...
    sum(lattice(:)), sum(lattice(:))/L^3);

%% Visualization
figure('Position', [100, 100, 1200, 800]);

% Show different slices
subplot(2, 3, 1);
z_slice = round(L/2);
imagesc(lattice(:, :, z_slice));
title(sprintf('Z-slice (z=%d)', z_slice));
axis equal tight;
colorbar;

subplot(2, 3, 2);
y_slice = round(L/2);
imagesc(squeeze(lattice(:, y_slice, :)));
title(sprintf('Y-slice (y=%d)', y_slice));
axis equal tight;
colorbar;

subplot(2, 3, 3);
x_slice = round(L/2);
imagesc(squeeze(lattice(x_slice, :, :)));
title(sprintf('X-slice (x=%d)', x_slice));
axis equal tight;
colorbar;

% Show 3D isosurface
subplot(2, 3, 4);
[x, y, z] = meshgrid(1:L, 1:L, 1:L);
p = patch(isosurface(x, y, z, lattice, 0.5));
p.FaceColor = 'red';
p.EdgeColor = 'none';
alpha(0.7);
view(3);
axis equal;
title('3D Isosurface');
grid on;

% Show cluster analysis
subplot(2, 3, 5);
[num_clusters, cluster_sizes, cluster_labels] = analyze_3d_clusters(lattice);
imagesc(cluster_labels(:, :, z_slice));
title(sprintf('Clusters: %d found', num_clusters));
axis equal tight;
colorbar;

% Show largest cluster
subplot(2, 3, 6);
largest_cluster_mask = cluster_labels == 1;
largest_cluster_slice = largest_cluster_mask(:, :, z_slice);
imagesc(largest_cluster_slice);
title(sprintf('Largest Cluster (size=%d)', max(cluster_sizes)));
axis equal tight;

sgtitle('3D Logical Lattice Growth Demo');

%% Template Reuse Example
fprintf('\n=== Template Reuse Example ===\n');

figure('Position', [200, 200, 1200, 400]);

% Start with base template
base_lattice = generate_templated_growth_3d_logical(L, 0.1);
fprintf('Base template: %.3f density\n', sum(base_lattice(:))/L^3);

% Grow incrementally
lattice_1 = generate_templated_growth_3d_logical(L, 0.2, base_lattice);
lattice_2 = generate_templated_growth_3d_logical(L, 0.3, lattice_1);
lattice_3 = generate_templated_growth_3d_logical(L, 0.4, lattice_2);

% Show progression
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

sgtitle('Template Reuse Progression');

%% Performance Test
fprintf('\n=== Performance Test ===\n');

test_sizes = [30, 40, 50];
test_p = 0.3;

fprintf('Testing performance with different lattice sizes:\n');
fprintf('%-15s %-15s %-15s\n', 'Size', 'Memory (MB)', 'Runtime (s)');

for i = 1:length(test_sizes)
    L_test = test_sizes(i);
    
    % Estimate memory
    memory_mb = (L_test^3 * 8) / (1024^2);
    
    % Time generation
    tic;
    lattice_test = generate_templated_growth_3d_logical(L_test, test_p);
    runtime = toc;
    
    fprintf('%-15d %-15.2f %-15.4f\n', L_test, memory_mb, runtime);
end

%% Edge Cases
fprintf('\n=== Edge Cases ===\n');

% Test with p = 0
lattice_p0 = generate_templated_growth_3d_logical(L, 0);
fprintf('p = 0: %d occupied sites\n', sum(lattice_p0(:)));

% Test with very small p
lattice_small = generate_templated_growth_3d_logical(L, 0.01);
fprintf('p = 0.01: %d occupied sites\n', sum(lattice_small(:)));

% Test with high p
lattice_high = generate_templated_growth_3d_logical(L, 0.8);
fprintf('p = 0.8: %d occupied sites\n', sum(lattice_high(:)));

fprintf('\n=== Demo Complete ===\n');

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
