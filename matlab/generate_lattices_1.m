% generate_lattices_1.m
% Generate lattices for the new fine-resolution p-values
% Store in matlab/Clusters1 directory

clear; clc; close all;

fprintf('=== GENERATING LATTICES FOR FINE-RESOLUTION ANALYSIS ===\n');
fprintf('Generating lattices with fine p-value resolution around critical points\n\n');

% Define the exact p-values from your specification
p_values = [0, 0.0500, 0.1000, 0.1500, 0.2000, 0.2500, 0.3000, 0.3116, ...
            0.3500, 0.4000, 0.4500, 0.5000, 0.5500, 0.6000, 0.6100, 0.6200, ...
            0.6300, 0.6400, 0.6500, 0.6600, 0.6700, 0.6800, 0.6884, 0.6900, ...
            0.7000, 0.7100, 0.7200, 0.7300, 0.7400, 0.7500, 0.7600, 0.7700, ...
            0.7800, 0.7900, 0.8000, 0.8100, 0.8200, 0.8300, 0.8400, 0.8500, ...
            0.8600, 0.8700, 0.8800, 0.8900, 0.9000, 0.9100, 0.9200, ... 
            0.9300, 0.9400, 0.9500, 0.9600, 0.9700, 0.9800, 0.9900];

% Define the 4 lattice variants
variants = {'6N_Templated', '26N_Templated', 'Density_Increment', 'Random_Percolation'};

% Parameters
L = 500;                    % Lattice size
output_dir = 'Clusters1';   % Output directory

fprintf('Parameters:\n');
fprintf('  Lattice size: %dx%dx%d\n', L, L, L);
fprintf('  P-values: %d values from %.4f to %.4f\n', length(p_values), p_values(1), p_values(end));
fprintf('  Variants: %s\n', strjoin(variants, ', '));
fprintf('  Output directory: %s\n\n', output_dir);

% Create output directory
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('Created output directory: %s\n', output_dir);
end

% Critical points
p_c = 0.3116;           % Standard percolation threshold
p_c_prime = 0.6884;     % Critical gel-point

fprintf('Critical Points:\n');
fprintf('  p_c = %.4f (standard percolation threshold)\n', p_c);
fprintf('  p_c_prime = %.4f (critical gel-point)\n', p_c_prime);
fprintf('  Fine resolution: %d values in [0.61, 0.69] around gel-point\n', sum(p_values >= 0.61 & p_values <= 0.69));
fprintf('\n');

% Calculate total lattices to generate
total_lattices = length(p_values) * length(variants);
fprintf('Total lattices to generate: %d\n', total_lattices);
fprintf('Expected runtime: 1-3 hours depending on system performance\n\n');

% Generate lattices using the viscoelastic_lattice_analysis function
fprintf('Starting lattice generation...\n');
tic;

try
    viscoelastic_lattice_analysis(L, p_values, true, output_dir);
    generation_time = toc;
    
    fprintf('\n=== LATTICE GENERATION COMPLETED SUCCESSFULLY! ===\n');
    fprintf('Total generation time: %.2f seconds (%.2f hours)\n', generation_time, generation_time/3600);
    
    % Verify all lattices were created
    fprintf('\nVerifying generated lattices...\n');
    missing_count = 0;
    for p_idx = 1:length(p_values)
        p = p_values(p_idx);
        for v = 1:length(variants)
            variant = variants{v};
            filename = sprintf('Lattice_%s_p%.4f_L%d.mat', variant, p, L);
            filepath = fullfile(output_dir, filename);
            if ~exist(filepath, 'file')
                fprintf('  Missing: %s\n', filename);
                missing_count = missing_count + 1;
            end
        end
    end
    
    if missing_count == 0
        fprintf('  All %d lattice files created successfully ✓\n', total_lattices);
    else
        fprintf('  Warning: %d lattice files are missing\n', missing_count);
    end
    
    fprintf('\nLattice files saved to: %s/\n', output_dir);
    fprintf('Ready for random walk analysis!\n');
    
catch ME
    fprintf('\n=== LATTICE GENERATION FAILED ===\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Full error details:\n');
    fprintf('%s\n', ME.getReport());
    return;
end

fprintf('\nNext step: Run run_random_walk_analysis_1.m to analyze these lattices\n');
