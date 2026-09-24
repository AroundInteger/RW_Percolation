% Benchmark script comparing different 3D growth methods
% Compares logical growth, standard templated growth, and random percolation
clear; clc; close all;

%% Benchmark Parameters
L = 50;  % Lattice size (balanced for performance vs memory)
p_values = [0.1, 0.2, 0.3, 0.4, 0.5];
num_runs = 3;  % Number of runs per method per probability (reduced for 3D)

fprintf('=== 3D Growth Methods Benchmark ===\n');
fprintf('Lattice size: %d x %d x %d\n', L, L, L);
fprintf('Memory per lattice: %.2f MB\n', (L^3 * 8) / (1024^2));
fprintf('Testing %d probabilities with %d runs each\n', length(p_values), num_runs);

%% Initialize Results Arrays
methods = {'Logical Growth', 'Standard Templated', 'Random Percolation'};
num_methods = length(methods);

runtimes = zeros(length(p_values), num_methods, num_runs);
achieved_densities = zeros(length(p_values), num_methods, num_runs);
memory_usage = zeros(length(p_values), num_methods, num_runs);

%% Run Benchmarks
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('\nBenchmarking p = %.2f...\n', p);
    
    for run = 1:num_runs
        fprintf('  Run %d/%d...\n', run, num_runs);
        
        % Method 1: Logical Growth
        tic;
        lattice_logical = generate_templated_growth_3d_logical(L, p);
        runtime_logical = toc;
        
        % Method 2: Standard Templated Growth
        tic;
        lattice_standard = generate_templated_growth_3d(L, p);
        runtime_standard = toc;
        
        % Method 3: Random Percolation
        tic;
        lattice_random = rand(L, L, L) < p;
        runtime_random = toc;
        
        % Store results
        runtimes(p_idx, 1, run) = runtime_logical;
        runtimes(p_idx, 2, run) = runtime_standard;
        runtimes(p_idx, 3, run) = runtime_random;
        
        achieved_densities(p_idx, 1, run) = sum(lattice_logical(:)) / L^3;
        achieved_densities(p_idx, 2, run) = sum(lattice_standard(:)) / L^3;
        achieved_densities(p_idx, 3, run) = sum(lattice_random(:)) / L^3;
        
        % Estimate memory usage (all methods use same memory)
        memory_usage(p_idx, :, run) = (L^3 * 8) / (1024^2);
    end
end

%% Analyze Results
fprintf('\n=== Benchmark Results ===\n');

% Calculate statistics
mean_runtimes = mean(runtimes, 3);
std_runtimes = std(runtimes, 0, 3);
mean_densities = mean(achieved_densities, 3);
std_densities = std(achieved_densities, 0, 3);

% Performance comparison
fprintf('\nRuntime Performance (seconds):\n');
fprintf('%-20s', 'Probability');
for m = 1:num_methods
    fprintf('%-20s', methods{m});
end
fprintf('\n');

for p_idx = 1:length(p_values)
    fprintf('%-20.2f', p_values(p_idx));
    for m = 1:num_methods
        fprintf('%-20.4f', mean_runtimes(p_idx, m));
    end
    fprintf('\n');
end

% Density accuracy comparison
fprintf('\nDensity Accuracy (achieved/target):\n');
fprintf('%-20s', 'Probability');
for m = 1:num_methods
    fprintf('%-20s', methods{m});
end
fprintf('\n');

for p_idx = 1:length(p_values)
    fprintf('%-20.2f', p_values(p_idx));
    for m = 1:num_methods
        accuracy = mean_densities(p_idx, m) / p_values(p_idx);
        fprintf('%-20.4f', accuracy);
    end
    fprintf('\n');
end

%% Create Visualization
figure('Position', [100, 100, 1400, 1000]);

% Runtime comparison
subplot(2, 3, 1);
errorbar(p_values, mean_runtimes(:, 1), std_runtimes(:, 1), 'o-', 'LineWidth', 2, 'DisplayName', 'Logical');
hold on;
errorbar(p_values, mean_runtimes(:, 2), std_runtimes(:, 2), 's-', 'LineWidth', 2, 'DisplayName', 'Standard');
errorbar(p_values, mean_runtimes(:, 3), std_runtimes(:, 3), '^-', 'LineWidth', 2, 'DisplayName', 'Random');
xlabel('Target Probability');
ylabel('Runtime (seconds)');
title('Runtime Performance');
legend('Location', 'best');
grid on;

% Density accuracy
subplot(2, 3, 2);
accuracy_logical = mean_densities(:, 1) ./ p_values';
accuracy_standard = mean_densities(:, 2) ./ p_values';
accuracy_random = mean_densities(:, 3) ./ p_values';

errorbar(p_values, accuracy_logical, std_densities(:, 1) ./ p_values', 'o-', 'LineWidth', 2, 'DisplayName', 'Logical');
hold on;
errorbar(p_values, accuracy_standard, std_densities(:, 2) ./ p_values', 's-', 'LineWidth', 2, 'DisplayName', 'Standard');
errorbar(p_values, accuracy_random, std_densities(:, 3) ./ p_values', '^-', 'LineWidth', 2, 'DisplayName', 'Random');
plot([0, max(p_values)], [1, 1], '--k', 'DisplayName', 'Perfect');
xlabel('Target Probability');
ylabel('Accuracy (Achieved/Target)');
title('Density Accuracy');
legend('Location', 'best');
grid on;

% Speedup comparison
subplot(2, 3, 3);
speedup_vs_standard = mean_runtimes(:, 2) ./ mean_runtimes(:, 1);
speedup_vs_random = mean_runtimes(:, 3) ./ mean_runtimes(:, 1);

plot(p_values, speedup_vs_standard, 'o-', 'LineWidth', 2, 'DisplayName', 'vs Standard');
hold on;
plot(p_values, speedup_vs_random, 's-', 'LineWidth', 2, 'DisplayName', 'vs Random');
plot([0, max(p_values)], [1, 1], '--k', 'DisplayName', 'No Speedup');
xlabel('Target Probability');
ylabel('Speedup Factor');
title('Logical Growth Speedup');
legend('Location', 'best');
grid on;

% Runtime distribution
subplot(2, 3, 4);
all_runtimes = runtimes(:);
histogram(all_runtimes, 30);
xlabel('Runtime (seconds)');
ylabel('Frequency');
title('Runtime Distribution (All Methods)');
grid on;

% Method comparison at specific probability
subplot(2, 3, 5);
p_test = 0.3;
p_idx = find(abs(p_values - p_test) < 1e-6);
if isempty(p_idx)
    p_idx = 1;
end

runtime_data = squeeze(runtimes(p_idx, :, :))';
boxplot(runtime_data, 'Labels', methods);
ylabel('Runtime (seconds)');
title(sprintf('Runtime Comparison at p = %.1f', p_values(p_idx)));
grid on;

% Memory efficiency
subplot(2, 3, 6);
memory_efficiency = mean_runtimes ./ memory_usage(:, 1, 1);
plot(p_values, memory_efficiency(:, 1), 'o-', 'LineWidth', 2, 'DisplayName', 'Logical');
hold on;
plot(p_values, memory_efficiency(:, 2), 's-', 'LineWidth', 2, 'DisplayName', 'Standard');
plot(p_values, memory_efficiency(:, 3), '^-', 'LineWidth', 2, 'DisplayName', 'Random');
xlabel('Target Probability');
ylabel('Runtime/Memory (s/MB)');
title('Memory Efficiency');
legend('Location', 'best');
grid on;

sgtitle('3D Growth Methods Benchmark Results');

%% Summary Statistics
fprintf('\n=== Summary Statistics ===\n');

% Overall performance
overall_mean_runtime = mean(mean_runtimes, 1);
overall_std_runtime = std(mean_runtimes, [], 1);

fprintf('Overall Mean Runtime (seconds):\n');
for m = 1:num_methods
    fprintf('  %s: %.4f ± %.4f\n', methods{m}, overall_mean_runtime(m), overall_std_runtime(m));
end

% Speedup analysis
mean_speedup_vs_standard = mean(speedup_vs_standard);
mean_speedup_vs_random = mean(speedup_vs_random);

fprintf('\nAverage Speedup of Logical Growth:\n');
fprintf('  vs Standard Templated: %.2fx\n', mean_speedup_vs_standard);
fprintf('  vs Random Percolation: %.2fx\n', mean_speedup_vs_random);

% Accuracy analysis
mean_accuracy_logical = mean(accuracy_logical);
mean_accuracy_standard = mean(accuracy_standard);
mean_accuracy_random = mean(accuracy_random);

fprintf('\nAverage Density Accuracy:\n');
fprintf('  Logical Growth: %.4f\n', mean_accuracy_logical);
fprintf('  Standard Templated: %.4f\n', mean_accuracy_standard);
fprintf('  Random Percolation: %.4f\n', mean_accuracy_random);

fprintf('\n=== Benchmark Complete ===\n');

%% Helper Functions

function lattice = generate_templated_growth_3d(L, p, template_lattice)
% Standard 3D templated growth for comparison
    
    if nargin < 3 || isempty(template_lattice)
        % Start from scratch with center seed
        lattice = zeros(L, L, L);
        center = round(L/2);
        lattice(center, center, center) = 1;
        current_sites = 1;
    else
        % Use existing lattice as template
        lattice = template_lattice;
        current_sites = sum(lattice(:));
    end
    
    target_sites = round(p * L^3);
    
    while current_sites < target_sites
        % Find all unoccupied sites adjacent to occupied sites
        [occupied_x, occupied_y, occupied_z] = ind2sub([L, L, L], find(lattice));
        adjacent_candidates = [];
        
        for i = 1:length(occupied_x)
            x = occupied_x(i); y = occupied_y(i); z = occupied_z(i);
            
            % Check 6 neighbors
            neighbors = [x-1,y,z; x+1,y,z; x,y-1,z; x,y+1,z; x,y,z-1; x,y,z+1];
            
            for j = 1:size(neighbors,1)
                nx = neighbors(j,1); ny = neighbors(j,2); nz = neighbors(j,3);
                
                if nx > 0 && nx <= L && ny > 0 && ny <= L && nz > 0 && nz <= L
                    if lattice(nx, ny, nz) == 0
                        adjacent_candidates(end+1) = sub2ind([L,L,L], nx, ny, nz);
                    end
                end
            end
        end
        
        adjacent_candidates = unique(adjacent_candidates);
        
        if isempty(adjacent_candidates)
            break;  % No more adjacent sites available
        end
        
        % Select random adjacent site
        selected_idx = adjacent_candidates(randi(length(adjacent_candidates)));
        lattice(selected_idx) = 1;
        current_sites = current_sites + 1;
    end
end
