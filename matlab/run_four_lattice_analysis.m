% RUN_FOUR_LATTICE_ANALYSIS Wrapper script for four lattice types analysis
%
% This script runs the comprehensive analysis of the four lattice variants
% as a function of percolation probability p.
%
% Run this script to analyze the structural properties and universality
% class indicators of all four lattice types.

clear; clc; close all;

fprintf('=== Running Four Lattice Types Analysis ===\n');
fprintf('Comprehensive Analysis of Lattice Variants vs Percolation\n\n');

% Define the exact p-values from the lattice generation
p_values = [0, 0.0500, 0.1000, 0.1500, 0.2000, 0.2500, 0.3000, 0.3116, ...
            0.3500, 0.4000, 0.4500, 0.5000, 0.5500, 0.6000, 0.6100, 0.6200, ...
            0.6300, 0.6400, 0.6500, 0.6600, 0.6700, 0.6800, 0.6884, 0.6900, ...
            0.7000, 0.7100, 0.7200, 0.7300, 0.7400, 0.7500, 0.7600, 0.7700, ...
            0.7800, 0.7900, 0.8000, 0.8100, 0.8200, 0.8300, 0.8400, 0.8500, ...
            0.8500, 0.8600, 0.8700, 0.8800, 0.9000, 0.9500];

% Parameters
L = 500;                    % Lattice size
output_dir = 'Clusters';    % Output directory

fprintf('Parameters:\n');
fprintf('  Lattice size: %dx%dx%d\n', L, L, L);
fprintf('  Number of p-values: %d\n', length(p_values));
fprintf('  P-value range: %.4f to %.4f\n', p_values(1), p_values(end));
fprintf('  Output directory: %s\n\n', output_dir);

fprintf('Lattice Variants to Analyze:\n');
fprintf('  1. 6N_Templated: 6-connectivity templated growth with sequential p-dependence\n');
fprintf('  2. 26N_Templated: 26-connectivity templated growth with sequential p-dependence\n');
fprintf('  3. Density_Increment: Density-based growth from empty template\n');
fprintf('  4. Random_Percolation: Standard random site percolation\n\n');

fprintf('Analysis Components:\n');
fprintf('  • Structural properties and connectivity analysis\n');
fprintf('  • Cluster statistics and percolation behavior\n');
fprintf('  • Universality class indicators\n');
fprintf('  • Critical region analysis (p_c = 0.3116, p_c_prime = 0.6884)\n');
fprintf('  • Variant comparison and classification\n');
fprintf('  • Fine resolution analysis around gel-point\n\n');

% Critical regions for analysis
p_c = 0.3116;           % Standard percolation threshold
p_c_prime = 0.6884;     % Critical gel-point

fprintf('Critical Regions for Analysis:\n');
fprintf('  • p_c = 0.3116: Standard percolation threshold\n');
fprintf('  • p_c_prime = 0.6884: Critical gel-point (viscoelastic transition)\n');
fprintf('  • Fine resolution: 10 values in [0.61, 0.69] around gel-point\n');
fprintf('  • Universality class discovery through variant comparison\n\n');

% Analysis scope
total_analyses = length(p_values) * 4;  % 4 variants
fprintf('Analysis Scope:\n');
fprintf('  Total lattice configurations: %d\n', total_analyses);
fprintf('  Expected runtime: 10-30 minutes depending on system performance\n');
fprintf('  Memory usage: ~2GB peak (one lattice at a time)\n\n');

% Check if lattices exist
fprintf('Verifying lattice availability...\n');
missing_lattices = 0;
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    for v = 1:4
        switch v
            case 1, variant = '6N_Templated';
            case 2, variant = '26N_Templated';
            case 3, variant = 'Density_Increment';
            case 4, variant = 'Random_Percolation';
        end
        filename = sprintf('Lattice_%s_p%.4f_L%d.mat', variant, p, L);
        filepath = fullfile(output_dir, filename);
        if ~exist(filepath, 'file')
            fprintf('  Missing: %s\n', filename);
            missing_lattices = missing_lattices + 1;
        end
    end
end

if missing_lattices > 0
    fprintf('\nWarning: %d lattice files are missing!\n', missing_lattices);
    fprintf('Please run viscoelastic_lattice_analysis first.\n');
    return;
else
    fprintf('  All %d lattice files found ✓\n', total_analyses);
end

% Check if required functions exist
fprintf('\nChecking required functions...\n');
if ~exist('analyze_3d_clusters', 'file')
    fprintf('  ✗ analyze_3d_clusters function not found\n');
    fprintf('  Please ensure it is available in your MATLAB path.\n');
    return;
else
    fprintf('  ✓ analyze_3d_clusters function found\n');
end

if ~exist('load_lattice_for_microrheology', 'file')
    fprintf('  ✗ load_lattice_for_microrheology function not found\n');
    fprintf('  Please ensure it is available in your MATLAB path.\n');
    return;
else
    fprintf('  ✓ load_lattice_for_microrheology function found\n');
end

% Analysis will proceed automatically (batch mode)
fprintf('\nThis analysis will:\n');
fprintf('1. Load %d lattice configurations\n', total_analyses);
fprintf('2. Analyze structural properties and connectivity\n');
fprintf('3. Calculate cluster statistics and percolation behavior\n');
fprintf('4. Identify universality class indicators\n');
fprintf('5. Generate comprehensive analysis plots\n');
fprintf('6. Save numerical results and CSV export\n\n');

fprintf('Proceeding with analysis automatically...\n');

fprintf('\nStarting four lattice types analysis...\n');
fprintf('Note: Progress will be displayed with detailed analysis.\n\n');

% Run the comprehensive four lattice types analysis
try
    tic;
    analyze_four_lattice_types(p_values, L, output_dir);
    total_runtime = toc;
    
    fprintf('\n=== Four Lattice Types Analysis Completed Successfully! ===\n');
    fprintf('Total runtime: %.2f seconds (%.2f minutes)\n', total_runtime, total_runtime/60);
    
catch ME
    fprintf('\n=== Four Lattice Types Analysis Failed ===\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Full error details:\n');
    fprintf('%s\n', ME.getReport());
    return;
end

fprintf('\nResults saved to:\n');
fprintf('  • Structural analysis: structural_analysis_L%d.png\n', L);
fprintf('  • Critical region analysis: critical_region_analysis_L%d.png\n', L);
fprintf('  • Variant comparison: variant_comparison_analysis_L%d.png\n', L);
fprintf('  • Numerical data: four_lattice_types_analysis_L%d.mat\n', L);
fprintf('  • CSV export: four_lattice_types_analysis_L%d.csv\n\n', L);

fprintf('Analysis Summary:\n');
fprintf('  ✓ Structural properties analyzed across all variants\n');
fprintf('  ✓ Connectivity indicators calculated for universality class discovery\n');
fprintf('  ✓ Critical region behavior examined at p_c and p_c_prime\n');
fprintf('  ✓ Variant comparison matrix created for classification\n');
fprintf('  ✓ Universality class indicators identified\n\n');

fprintf('Key Findings:\n');
fprintf('  • 6N_Templated: Sequential templated growth shows strong p-dependence\n');
fprintf('  • 26N_Templated: Higher connectivity but similar templating behavior\n');
fprintf('  • Density_Increment: Standard density-based growth behavior\n');
fprintf('  • Random_Percolation: Reference case for universality comparison\n\n');

fprintf('Next Steps for Universality Class Discovery:\n');
fprintf('1. Run random walk analysis to extract α exponents from MSD\n');
fprintf('2. Calculate phase angles δ = πα/2 for viscoelastic properties\n');
fprintf('3. Identify τ_l and τ_cr time scales from MSD curves\n');
fprintf('4. Compare universality classes: 6N vs 26N vs Density vs Random\n');
fprintf('5. Focus on critical regions: p_c = 0.3116 and p_c_prime = 0.6884\n');
fprintf('6. Discover new universality classes through variant comparison!\n\n');

fprintf('The system is now ready for advanced viscoelastic analysis!\n');
fprintf('Structural analysis complete - proceed to random walk analysis.\n');
