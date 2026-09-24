% run_analysis_wrapper.m
% Simple wrapper to run the analysis without command line issues

clear; close all; clc;

fprintf('=== RUNNING ANALYSIS ON NEW CLUSTERS1 DATA ===\n');

try
    analyze_mat_results_1;
    fprintf('\n=== ANALYSIS COMPLETED SUCCESSFULLY ===\n');
catch ME
    fprintf('\n=== ANALYSIS FAILED ===\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Full error details:\n');
    fprintf('%s\n', ME.getReport());
end

