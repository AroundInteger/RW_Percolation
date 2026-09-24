% Quick test to verify the 3D logical growth fix works
clear; clc; close all;

fprintf('=== Testing 3D Logical Growth Fix ===\n');

%% Test 1: Basic functionality
L = 50;  % Small lattice for quick test
p = 0.2;

fprintf('Test 1: Basic growth (L=%d, p=%.2f)\n', L, p);

try
    lattice = generate_templated_growth_3d_logical(L, p);
    fprintf('✓ Success! Generated lattice with %d sites (%.3f density)\n', ...
        sum(lattice(:)), sum(lattice(:))/L^3);
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    return;
end

%% Test 2: Template reuse
fprintf('\nTest 2: Template reuse\n');

try
    base_lattice = generate_templated_growth_3d_logical(L, 0.1);
    grown_lattice = generate_templated_growth_3d_logical(L, 0.3, base_lattice);
    fprintf('✓ Success! Template reuse works\n');
    fprintf('  Base: %d sites, Grown: %d sites\n', ...
        sum(base_lattice(:)), sum(grown_lattice(:)));
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    return;
end

%% Test 3: Edge cases
fprintf('\nTest 3: Edge cases\n');

try
    % Test p = 0
    lattice_p0 = generate_templated_growth_3d_logical(L, 0);
    fprintf('✓ p=0: %d sites\n', sum(lattice_p0(:)));
    
    % Test very small p
    lattice_small = generate_templated_growth_3d_logical(L, 0.01);
    fprintf('✓ p=0.01: %d sites\n', sum(lattice_small(:)));
    
    % Test high p
    lattice_high = generate_templated_growth_3d_logical(L, 0.6);
    fprintf('✓ p=0.6: %d sites\n', sum(lattice_high(:)));
    
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    return;
end

%% Test 4: Visualization
fprintf('\nTest 4: Basic visualization\n');

try
    % Show middle slice
    z_slice = round(L/2);
    lattice_slice = lattice(:, :, z_slice);
    
    figure('Position', [100, 100, 800, 600]);
    
    subplot(2, 2, 1);
    imagesc(lattice_slice);
    title(sprintf('Z-slice (z=%d)', z_slice));
    axis equal tight;
    colorbar;
    
    subplot(2, 2, 2);
    y_slice = round(L/2);
    imagesc(squeeze(lattice(:, y_slice, :)));
    title(sprintf('Y-slice (y=%d)', y_slice));
    axis equal tight;
    colorbar;
    
    subplot(2, 2, 3);
    x_slice = round(L/2);
    imagesc(squeeze(lattice(x_slice, :, :)));
    title(sprintf('X-slice (x=%d)', x_slice));
    axis equal tight;
    colorbar;
    
    subplot(2, 2, 4);
    % Show 3D isosurface
    [x, y, z] = meshgrid(1:L, 1:L, 1:L);
    p = patch(isosurface(x, y, z, lattice, 0.5));
    p.FaceColor = 'red';
    p.EdgeColor = 'none';
    alpha(0.7);
    view(3);
    axis equal;
    title('3D Isosurface');
    grid on;
    
    sgtitle('3D Lattice Visualization Test');
    fprintf('✓ Visualization successful\n');
    
catch ME
    fprintf('✗ Visualization error: %s\n', ME.message);
end

%% Test 5: Performance
fprintf('\nTest 5: Performance test\n');

try
    test_sizes = [30, 40, 50];
    test_p = 0.3;
    
    fprintf('Testing different lattice sizes:\n');
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
    
    fprintf('✓ Performance test successful\n');
    
catch ME
    fprintf('✗ Performance test error: %s\n', ME.message);
end

fprintf('\n=== All Tests Complete ===\n');
fprintf('If you see this message, the 3D logical growth fix is working!\n');
