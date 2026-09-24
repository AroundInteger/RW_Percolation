% RUN_RESEARCH_ANALYSIS Script to run comprehensive lattice analysis
%
% This script runs the research_lattice_analysis function with the exact
% parameters specified for your research: L=500 and 46 specific p-values.
%
% Run this script to start the comprehensive analysis.

clear; clc; close all;

fprintf('=== Running Research Lattice Analysis ===\n');
fprintf('G\', G\'\', tan(δ), τ_l, and τ_cr Analysis for Universality Class Research\n\n');

% Define the exact p-values from your specification
p_values = [0, 0.0500, 0.1000, 0.1500, 0.2000, 0.2500, 0.3000, 0.3116, ...
            0.3500, 0.4000, 0.4500, 0.5000, 0.5500, 0.6000, 0.6100, 0.6200, ...
            0.6300, 0.6400, 0.6500, 0.6600, 0.6700, 0.6800, 0.6884, 0.6900, ...
            0.7000, 0.7100, 0.7200, 0.7300, 0.7400, 0.7500, 0.7600, 0.7700, ...
            0.7800, 0.7900, 0.8000, 0.8100, 0.8200, 0.8300, 0.8400, 0.8500, ...
            0.8500, 0.8600, 0.8700, 0.8800, 0.9000, 0.9500];

% Parameters
L = 500;                    % Lattice size
save_results = true;        % Save all results
output_dir = 'Clusters';    % Output directory

fprintf('Parameters:\n');
fprintf('  Lattice size: %dx%dx%d\n', L, L, L);
fprintf('  Number of p-values: %d\n', length(p_values));
fprintf('  P-value range: %.4f to %.4f\n', p_values(1), p_values(end));
fprintf('  Output directory: %s\n\n', output_dir);

fprintf('Research Purpose:\n');
fprintf('  • G\', G\'\', tan(δ) calculation as functions of percolation p\n');
fprintf('  • τ_l (local time scale) and τ_cr (cross-over time) analysis\n');
fprintf('  • Critical gel-point verification at p_c_prime = 0.6884\n');
fprintf('  • Universality class discovery through microrheological RW analysis\n');
fprintf('  • High resolution around critical regions (p_c = 0.3116, p_c_prime = 0.6884)\n\n');

% Memory estimation
memory_per_lattice_mb = (L^3 * 8) / (1024^2);
peak_memory_mb = memory_per_lattice_mb * 4; % Only 4 lattices in memory at once
total_storage_gb = (memory_per_lattice_mb * length(p_values) * 4) / 1024; % Total storage needed
fprintf('Memory estimation:\n');
fprintf('  Per lattice: %.1f MB\n', memory_per_lattice_mb);
fprintf('  Peak memory usage: %.1f MB (%.1f GB) - only 4 lattices in memory\n', peak_memory_mb, peak_memory_mb/1024);
fprintf('  Total storage needed: %.1f GB\n', total_storage_gb);

% Check if user wants to proceed
fprintf('\nThis analysis will generate %d lattices of size %dx%dx%d.\n', length(p_values)*4, L, L, L);
fprintf('Estimated runtime: 1-4 hours depending on system performance.\n\n');

% Ask for confirmation (comment out if you want to run automatically)
% response = input('Proceed with analysis? (y/n): ', 's');
% if ~strcmpi(response, 'y')
%     fprintf('Analysis cancelled.\n');
%     return;
% end

fprintf('Starting analysis...\n');
fprintf('Note: Progress bar will show generation status.\n\n');
fprintf('Each lattice variant will be saved individually as:\n');
fprintf('  Lattice_6N_Templated_p0.3116_L500.mat\n');
fprintf('  Lattice_26N_Templated_p0.3116_L500.mat\n');
fprintf('  Lattice_Density_Increment_p0.3116_L500.mat\n');
fprintf('  Lattice_Random_Percolation_p0.3116_L500.mat\n\n');
fprintf('For microrheological analysis, use:\n');
fprintf('  [lat, meta] = load_lattice_for_microrheology(''6N_Templated'', 0.3116, 500);\n');
fprintf('  unoccupied_sites = ~lat;  % Sites for random walk analysis\n\n');

fprintf('Critical Regions for Analysis:\n');
fprintf('  • p_c = 0.3116: Standard percolation threshold\n');
fprintf('  • p_c_prime = 0.6884: Critical gel-point (viscoelastic transition)\n');
fprintf('  • Fine resolution: 0.61-0.69 around gel-point\n');
fprintf('  • τ_l analysis: Local time scale behavior\n');
fprintf('  • τ_cr analysis: Cross-over time detection\n\n');

% Run the comprehensive analysis
try
    research_lattice_analysis(L, p_values, save_results, output_dir);
    fprintf('\n=== Analysis completed successfully! ===\n');
catch ME
    fprintf('\n=== Analysis failed with error ===\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Full error details:\n');
    fprintf('%s\n', ME.getReport());
end

fprintf('\nCheck the Clusters/ directory for all generated results.\n');
