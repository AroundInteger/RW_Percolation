% RUN_RANDOM_WALK_ANALYSIS Wrapper script for comprehensive RW analysis
%
% This script runs the random walk analysis on all generated lattices
% to discover universality classes through MSD behavior analysis.
%
% Run this script to start the random walk analysis.

clear; clc; close all;

fprintf('=== Running Random Walk Analysis ===\n');
fprintf('Universality Class Discovery through MSD Analysis\n\n');

% Define the exact p-values from the lattice generation
p_values = [0, 0.0500, 0.1000, 0.1500, 0.2000, 0.2500, 0.3000, 0.3116, ...
            0.3500, 0.4000, 0.4500, 0.5000, 0.5500, 0.6000, 0.6100, 0.6200, ...
            0.6300, 0.6400, 0.6500, 0.6600, 0.6700, 0.6800, 0.6884, 0.6900, ...
            0.7000, 0.7100, 0.7200, 0.7300, 0.7400, 0.7500, 0.7600, 0.7700, ...
            0.7800, 0.7900, 0.8000, 0.8100, 0.8200, 0.8300, 0.8400, 0.8500, ...
            0.8600, 0.8700, 0.8800, 0.8900, 0.9000, 0.9100, 0.9200, ... 
            0.9300, 0.9400, 0.9500, 0.9600, 0.9700, 0.9800, 0.9900];

% Define the 4 lattice variants to analyze
variants = {'6N_Templated', '26N_Templated', 'Density_Increment', 'Random_Percolation'};

% Parameters
L = 500;                    % Lattice size
LW = 1e6;                  % Walk length (1 million steps)
NW = 3e3;                  % Number of walkers (3000)
output_dir = 'Clusters1';   % Output directory

fprintf('Parameters:\n');
fprintf('  Lattice size: %dx%dx%d\n', L, L, L);
fprintf('  Walk length: %d steps\n', LW);
fprintf('  Number of walkers: %d\n', NW);
fprintf('  P-values: %d values from %.4f to %.4f\n', length(p_values), p_values(1), p_values(end));
fprintf('  Variants: %s\n', strjoin(variants, ', '));
fprintf('  Output directory: %s\n\n', output_dir);

fprintf('Research Purpose:\n');
fprintf('  • Extract α exponents from MSD slopes (MSD ∝ t^α)\n');
fprintf('  • Calculate phase angles δ = πα/2 for viscoelastic analysis\n');
fprintf('  • Identify τ_l (local time scale) and τ_cr (cross-over time)\n');
fprintf('  • Compare universality classes across lattice variants\n');
fprintf('  • Discover new universality classes through variant comparison\n\n');

% Critical regions for analysis
p_c = 0.3116;           % Standard percolation threshold
p_c_prime = 0.6884;     % Critical gel-point

fprintf('Critical Regions for Analysis:\n');
fprintf('  • p_c = 0.3116: Standard percolation threshold\n');
fprintf('  • p_c_prime = 0.6884: Critical gel-point (viscoelastic transition)\n');
fprintf('  • Fine resolution: 10 values in [0.61, 0.69] around gel-point\n');
fprintf('  • alpha analysis: Extract exponents from MSD power law behavior\n');
fprintf('  • delta analysis: Phase angles for G'', G'''', tan(delta) calculation\n\n');

% Analysis scope
total_analyses = length(p_values) * length(variants);
fprintf('Analysis Scope:\n');
fprintf('  Total lattice configurations: %d\n', total_analyses);
fprintf('  Expected runtime: 2-8 hours depending on system performance\n');
fprintf('  Memory usage: ~4GB peak (one lattice + walkers at a time)\n\n');

% Check if lattices exist
fprintf('Verifying lattice availability...\n');
missing_lattices = 0;
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    for v = 1:length(variants)
        variant = variants{v};
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
    fprintf('Please run generate_lattices_1.m first to create the lattices.\n');
    return;
else
    fprintf('  All %d lattice files found ✓\n', total_analyses);
end

% Check if RW3D_P_SP function exists
if ~exist('RW3D_P_SP', 'file')
    fprintf('\nError: RW3D_P_SP function not found!\n');
    fprintf('This function is required for random walk simulation.\n');
    fprintf('Please ensure it is available in your MATLAB path.\n');
    return;
else
    fprintf('  RW3D_P_SP function found ✓\n');
end

% Check parallel pool
fprintf('\nParallel Processing Setup:\n');
if ~isempty(gcp('nocreate'))
    pool = gcp;
    fprintf('  Parallel pool active: %d workers\n', pool.NumWorkers);
else
    fprintf('  Starting parallel pool...\n');
    try
        pool = gcp('nocreate');
        if isempty(pool)
            parpool('Processes');
            pool = gcp;
        end
        fprintf('  Parallel pool started: %d workers\n', pool.NumWorkers);
    catch ME
        fprintf('  Warning: Could not start parallel pool: %s\n', ME.message);
        fprintf('  Analysis will continue with serial processing (slower)\n');
    end
end

% Analysis will proceed automatically (batch mode)
fprintf('\nThis analysis will:\n');
fprintf('1. Load %d lattice configurations\n', total_analyses);
fprintf('2. Run %d random walks per configuration\n', NW);
fprintf('3. Calculate MSD for %d time steps\n', LW);
fprintf('4. Extract alpha exponents and phase angles\n');
fprintf('5. Generate universality class analysis plots\n\n');

fprintf('Proceeding with analysis automatically...\n');

fprintf('\nStarting random walk analysis...\n');
fprintf('Note: Progress will be displayed with detailed timing.\n\n');

% Run the comprehensive random walk analysis
try
    tic;
    analyze_lattice_random_walks(p_values, variants, L, LW, NW, output_dir);
    total_runtime = toc;
    
    fprintf('\n=== Random Walk Analysis Completed Successfully! ===\n');
    fprintf('Total runtime: %.2f seconds (%.2f hours)\n', total_runtime, total_runtime/3600);
    
catch ME
    fprintf('\n=== Random Walk Analysis Failed ===\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Full error details:\n');
    fprintf('%s\n', ME.getReport());
    return;
end

fprintf('\nResults saved to:\n');
fprintf('  • MSD analysis plots: msd_analysis_L%d_LW%d_NW%d.png\n', L, LW, NW);
fprintf('  • Universality class analysis: universality_class_analysis_L%d.png\n', L);
fprintf('  • Critical region analysis: critical_region_msd_L%d.png\n', L);
fprintf('  • Numerical data: random_walk_analysis_L%d_LW%d_NW%d.mat\n', L, LW, NW);
fprintf('  • CSV export: random_walk_analysis_L%d_LW%d_NW%d.csv\n\n', L, LW, NW);

fprintf('Next Steps for Universality Class Discovery:\n');
fprintf('1. Analyze alpha exponent behavior across p-values and variants\n');
fprintf('2. Calculate phase angles delta = pi*alpha/2 for viscoelastic properties\n');
fprintf('3. Identify tau_l and tau_cr time scales from MSD curves\n');
fprintf('4. Compare universality classes: 6N vs 26N vs Density vs Random\n');
fprintf('5. Focus on critical regions: p_c = 0.3116 and p_c_prime = 0.6884\n');
fprintf('6. Discover new universality classes through variant comparison!\n\n');

fprintf('The system is now ready for advanced viscoelastic analysis!\n');
fprintf('G'', G'''', tan(delta), tau_l, and tau_cr calculations can proceed.\n');
