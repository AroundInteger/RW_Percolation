% run_full_analysis_1.m
% Complete analysis pipeline: Generate lattices + Run random walks
% This runs both steps in sequence for the fine-resolution analysis

clear; clc; close all;

fprintf('=== COMPLETE FINE-RESOLUTION ANALYSIS PIPELINE ===\n');
fprintf('Step 1: Generate lattices with fine p-value resolution\n');
fprintf('Step 2: Run random walk analysis on generated lattices\n\n');

% Step 1: Generate lattices
fprintf('=== STEP 1: GENERATING LATTICES ===\n');
try
    generate_lattices_1;
    fprintf('✓ Lattice generation completed successfully\n\n');
catch ME
    fprintf('✗ Lattice generation failed: %s\n', ME.message);
    return;
end

% Step 2: Run random walk analysis
fprintf('=== STEP 2: RUNNING RANDOM WALK ANALYSIS ===\n');
try
    run_random_walk_analysis_1;
    fprintf('✓ Random walk analysis completed successfully\n\n');
catch ME
    fprintf('✗ Random walk analysis failed: %s\n', ME.message);
    return;
end

fprintf('=== COMPLETE ANALYSIS PIPELINE FINISHED ===\n');
fprintf('All results saved to: matlab/Clusters1/\n');
fprintf('Ready for universality class analysis!\n');
