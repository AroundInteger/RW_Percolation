% test_models_simple.m
% Simple test to verify all models work correctly

clc; close all; clear all;

fprintf('=== Simple Model Test ===\n');

% Parameters
L = 50;  % Smaller lattice for testing
p = 0.3;  % Target density

fprintf('Testing with L=%d, p=%.2f\n\n', L, p);

% Test Random Percolation
fprintf('1. Random Percolation...\n');
lattice_random = generate_random_lattice(L, p);
density_random = sum(lattice_random(:)) / numel(lattice_random);
fprintf('   Density: %.3f (target: %.3f)\n', density_random, p);

% Test 6N Templated
fprintf('2. 6N Templated...\n');
lattice_6n = generate_templated_lattice(L, p, '6N');
density_6n = sum(lattice_6n(:)) / numel(lattice_6n);
fprintf('   Density: %.3f (target: %.3f)\n', density_6n, p);

% Test 26N Templated
fprintf('3. 26N Templated...\n');
lattice_26n = generate_templated_lattice(L, p, '26N');
density_26n = sum(lattice_26n(:)) / numel(lattice_26n);
fprintf('   Density: %.3f (target: %.3f)\n', density_26n, p);

% Test Eden Hybrid
fprintf('4. Eden Hybrid...\n');
lattice_eden = generate_hybrid_models(L, p, 'eden_hybrid');
density_eden = sum(lattice_eden(:)) / numel(lattice_eden);
fprintf('   Density: %.3f (target: %.3f)\n', density_eden, p);

% Test DLA Hybrid
fprintf('5. DLA Hybrid...\n');
lattice_dla = generate_hybrid_models(L, p, 'dla_hybrid');
density_dla = sum(lattice_dla(:)) / numel(lattice_dla);
fprintf('   Density: %.3f (target: %.3f)\n', density_dla, p);

% Test Tunable Hybrid
fprintf('6. Tunable Hybrid...\n');
lattice_tunable = generate_hybrid_models(L, p, 'tunable_hybrid');
density_tunable = sum(lattice_tunable(:)) / numel(lattice_tunable);
fprintf('   Density: %.3f (target: %.3f)\n', density_tunable, p);

fprintf('\n=== Test Complete ===\n');

% Helper function
function lattice = generate_random_lattice(L, p)
    lattice = rand(L, L, L) < p;
end

function lattice = generate_templated_lattice(L, p, method)
    lattice = false(L, L, L);
    center = round(L/2);
    lattice(center, center, center) = true;
    
    if strcmp(method, '6N')
        neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];
    else
        [X, Y, Z] = meshgrid(-1:1, -1:1, -1:1);
        neighbors = [X(:), Y(:), Z(:)];
        neighbors(all(neighbors == 0, 2), :) = [];
    end
    
    target_sites = round(p * L^3);
    current_sites = 1;
    
    while current_sites < target_sites
        [occupied_x, occupied_y, occupied_z] = ind2sub([L, L, L], find(lattice));
        if isempty(occupied_x), break; end
        
        idx = randi(length(occupied_x));
        x = occupied_x(idx); y = occupied_y(idx); z = occupied_z(idx);
        
        for n = 1:size(neighbors, 1)
            nx = x + neighbors(n, 1);
            ny = y + neighbors(n, 2);
            nz = z + neighbors(n, 3);
            
            if nx >= 1 && nx <= L && ny >= 1 && ny <= L && nz >= 1 && nz <= L
                if ~lattice(nx, ny, nz) && rand < 0.5
                    lattice(nx, ny, nz) = true;
                    current_sites = current_sites + 1;
                    break;
                end
            end
        end
    end
end
