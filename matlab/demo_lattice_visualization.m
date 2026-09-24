% DEMO_LATTICE_VISUALIZATION Demo script for the comprehensive lattice visualization
%
% This script demonstrates how to use the visualize_lattice_types function
% to create comprehensive visualizations of different 3D lattice types.
%
% Run this script to see all the visualization capabilities!

clear; clc; close all;

fprintf('=== Lattice Visualization Demo ===\n\n');

%% Example 1: Quick visualization with default parameters
fprintf('Example 1: Quick visualization with default parameters\n');
fprintf('This will create visualizations for L=60, p=[0.2, 0.3116, 0.5, 0.6884]\n\n');

% Run with default parameters
visualize_lattice_types();

fprintf('\nPress any key to continue to the next example...\n');
pause;

%% Example 2: Custom lattice size and probability values
fprintf('\nExample 2: Custom parameters\n');
fprintf('Creating visualizations for L=80, p=[0.1, 0.3, 0.5, 0.7, 0.9]\n\n');

% Custom parameters
L_custom = 200;
p_custom = [0.1, 0.3116, 0.5, 0.6884, 0.85 ];

visualize_lattice_types(L_custom, p_custom);

fprintf('\nPress any key to continue to the next example...\n');
pause;

%% Example 3: Fine resolution analysis around critical region
fprintf('\nExample 3: Fine resolution around critical region\n');
fprintf('Analyzing the critical region around p=0.3116 with fine steps\n\n');

% Fine resolution around critical region
L_fine = 60;
p_fine = 0.25:0.02:0.4;  % Fine steps around critical region

visualize_lattice_types(L_fine, p_fine);

fprintf('\nPress any key to continue to the next example...\n');
pause;

%% Example 4: Large lattice for detailed analysis
fprintf('\nExample 4: Large lattice for detailed analysis\n');
fprintf('Creating detailed visualizations for L=100 (this may take longer)\n\n');

% Large lattice for detailed analysis
L_large = 300;
p_large = [0.1, 0.3116, 0.5, 0.6884, 0.85];

visualize_lattice_types(L_large, p_large);

%% Summary
fprintf('\n=== Demo Complete ===\n');
fprintf('All visualizations have been created and saved to the Clusters/ directory.\n');
fprintf('\nGenerated visualizations include:\n');
fprintf('1. Comprehensive 2D slice comparisons\n');
fprintf('2. Interactive lattice explorer\n');
fprintf('3. Cluster analysis comparisons\n');
fprintf('4. 3D isosurface comparisons\n');
fprintf('\nYou can now explore the different lattice types and their properties!\n');

%% Tips for further exploration
fprintf('\n=== Tips for Further Exploration ===\n');
fprintf('• Try different lattice sizes: L=40 (fast), L=80 (balanced), L=120 (detailed)\n');
fprintf('• Experiment with different p-value ranges\n');
fprintf('• Use the interactive explorer to examine specific slices\n');
fprintf('• Compare cluster statistics across different lattice types\n');
fprintf('• Analyze the 3D isosurfaces for spatial structure differences\n');
fprintf('\n• To run with custom parameters:\n');
fprintf('  visualize_lattice_types(70, 0.1:0.1:0.9, true);\n');
fprintf('  visualize_lattice_types(50, [0.2, 0.5], false);\n');
