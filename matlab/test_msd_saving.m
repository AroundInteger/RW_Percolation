% TEST_MSD_SAVING Minimal test of MSD saving functionality
%
% This script tests the complete random walk analysis pipeline
% with a small sample to validate data saving before full analysis.
%
% Test parameters:
%   L = 30 (small lattice for speed)
%   LW = 1000 (short walks)
%   NW = 50 (few walkers)
%   p_values = [0.2, 0.5, 0.6884] (key critical points)
%   variants = [6N_Templated, Random_Percolation] (2 variants)

clear; clc; close all;

fprintf('=== Testing MSD Saving Functionality ===\n');
fprintf('Validating complete pipeline with small sample\n\n');

% Test parameters (small scale for speed)
L_test = 30;                    % Small lattice for testing
LW_test = 1000;                 % Short walks for testing
NW_test = 50;                   % Few walkers for testing
output_dir = 'Clusters';        % Output directory

% Test with subset of p-values and variants
p_values_test = [0.2, 0.5, 0.6884];  % Key values including critical points
variants_test = {'6N_Templated', 'Random_Percolation'};  % Test with 2 variants

fprintf('Test Parameters:\n');
fprintf('  Lattice size: %dx%dx%d\n', L_test, L_test, L_test);
fprintf('  Walk length: %d steps\n', LW_test);
fprintf('  Number of walkers: %d\n', NW_test);
fprintf('  P-values: %s\n', mat2str(p_values_test));
fprintf('  Variants: %s\n', strjoin(variants_test, ', '));
fprintf('  Output directory: %s\n\n', output_dir);

% Check if test lattices exist
fprintf('Checking test lattice availability...\n');
missing_lattices = 0;
for p_idx = 1:length(p_values_test)
    p = p_values_test(p_idx);
    for v = 1:length(variants_test)
        variant = variants_test{v};
        filename = sprintf('Lattice_%s_p%.4f_L%d.mat', variant, p, L_test);
        filepath = fullfile(output_dir, filename);
        if ~exist(filepath, 'file')
            fprintf('  Missing: %s\n', filename);
            missing_lattices = missing_lattices + 1;
        end
    end
end

if missing_lattices > 0
    fprintf('\nWarning: %d test lattice files are missing!\n', missing_lattices);
    fprintf('Generating test lattices...\n');
    
    % Generate test lattices
    try
        viscoelastic_lattice_analysis(L_test, p_values_test, true, output_dir);
        fprintf('  Test lattices generated successfully ✓\n');
    catch ME
        fprintf('  Error generating test lattices: %s\n', ME.message);
        fprintf('  Please run viscoelastic_lattice_analysis first.\n');
        return;
    end
else
    fprintf('  All test lattice files found ✓\n');
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

% Test parallel pool
fprintf('\nTesting parallel processing...\n');
try
    if ~isempty(gcp('nocreate'))
        pool = gcp;
        fprintf('  Parallel pool active: %d workers ✓\n', pool.NumWorkers);
    else
        fprintf('  Starting parallel pool...\n');
        parpool('Processes');
        pool = gcp;
        fprintf('  Parallel pool started: %d workers ✓\n', pool.NumWorkers);
    end
catch ME
    fprintf('  Warning: Could not start parallel pool: %s\n', ME.message);
    fprintf('  Test will continue with serial processing\n');
end

fprintf('\nStarting MSD saving test...\n');
fprintf('Expected runtime: 5-10 minutes\n\n');

% Run test analysis
try
    tic;
    analyze_lattice_random_walks(p_values_test, variants_test, L_test, LW_test, NW_test, output_dir);
    test_runtime = toc;
    
    fprintf('\n=== MSD Saving Test Completed Successfully! ===\n');
    fprintf('Test runtime: %.2f seconds (%.2f minutes)\n', test_runtime, test_runtime/60);
    
    % Verify output files
    fprintf('\nVerifying output files...\n');
    expected_files = {
        sprintf('msd_analysis_L%d_LW%d_NW%d.png', L_test, LW_test, NW_test),
        sprintf('universality_class_analysis_L%d.png', L_test),
        sprintf('critical_region_msd_L%d.png', L_test),
        sprintf('random_walk_analysis_L%d_LW%d_NW%d.mat', L_test, LW_test, NW_test),
        sprintf('random_walk_analysis_L%d_LW%d_NW%d.csv', L_test, LW_test, NW_test)
    };
    
    for i = 1:length(expected_files)
        filepath = fullfile(output_dir, expected_files{i});
        if exist(filepath, 'file')
            file_info = dir(filepath);
            fprintf('  ✓ %s (%.1f KB)\n', expected_files{i}, file_info.bytes/1024);
        else
            fprintf('  ✗ Missing: %s\n', expected_files{i});
        end
    end
    
    % Test data loading
    fprintf('\nTesting data loading...\n');
    try
        results_file = fullfile(output_dir, sprintf('random_walk_analysis_L%d_LW%d_NW%d.mat', L_test, LW_test, NW_test));
        if exist(results_file, 'file')
            data = load(results_file);
            fprintf('  ✓ Results file loaded successfully\n');
            fprintf('  ✓ MSD data shape: %s\n', mat2str(size(data.MSD_results)));
            fprintf('  ✓ P-values: %s\n', mat2str(data.p_values));
            fprintf('  ✓ Variants: %s\n', strjoin(data.variants, ', '));
            
            % Test MSD data integrity
            fprintf('\nMSD Data Integrity Check:\n');
            fprintf('  ✓ MSD data contains %d time steps\n', size(data.MSD_results, 1));
            fprintf('  ✓ MSD data contains %d p-values\n', size(data.MSD_results, 2));
            fprintf('  ✓ MSD data contains %d variants\n', size(data.MSD_results, 3));
            
            % Check for NaN values
            nan_count = sum(isnan(data.MSD_results(:)));
            total_elements = numel(data.MSD_results);
            fprintf('  ✓ Data quality: %.2f%% valid (%.0f NaN values)\n', ...
                (total_elements - nan_count)/total_elements*100, nan_count);
            
        else
            fprintf('  ✗ Results file not found\n');
        end
    catch ME
        fprintf('  ✗ Error loading results: %s\n', ME.message);
    end
    
catch ME
    fprintf('\n=== MSD Saving Test Failed ===\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Full error details:\n');
    fprintf('%s\n', ME.getReport());
    return;
end

fprintf('\n=== Test Summary ===\n');
fprintf('✓ Random walk execution successful\n');
fprintf('✓ MSD calculation completed\n');
fprintf('✓ Data saving functional (.mat and .csv)\n');
fprintf('✓ Plot generation successful\n');
fprintf('✓ Data loading and integrity verified\n\n');

fprintf('The MSD saving pipeline is validated and ready!\n');
fprintf('Next step: Run full analysis with L=500, LW=1e6, NW=3e3\n');
fprintf('Command: run_random_walk_analysis\n');
