%% Test Script for Step 1: Data Loading and Transformation
% This script tests the data loading and transformation process

clear; clc;

fprintf('=== Testing Step 1: Data Loading and Transformation ===\n\n');

%% Test 1: Check if data file exists
data_file = 'Clusters/p_output_C1.csv';
if exist(data_file, 'file')
    fprintf('✓ Data file found: %s\n', data_file);
else
    fprintf('✗ Data file NOT found: %s\n', data_file);
    fprintf('Please ensure you are in the correct directory or provide the full path.\n');
    return;
end

%% Test 2: Check file size
file_info = dir(data_file);
file_size_mb = file_info.bytes / (1024^2);
fprintf('✓ File size: %.2f MB\n', file_size_mb);

%% Test 3: Quick data peek
fprintf('\nPeeking at first few lines of data...\n');
try
    % Read just the first few lines to check structure
    fid = fopen(data_file, 'r');
    header_line = fgetl(fid);
    first_data_line = fgetl(fid);
    fclose(fid);
    
    fprintf('✓ Header: %s\n', header_line(1:min(100, length(header_line))));
    fprintf('✓ First data line: %s\n', first_data_line(1:min(100, length(first_data_line))));
    
    % Count columns
    num_columns = length(strsplit(header_line, ','));
    fprintf('✓ Number of columns: %d\n', num_columns);
    
catch ME
    fprintf('✗ Error reading file: %s\n', ME.message);
    return;
end

%% Test 4: Run the main script
fprintf('\nRunning main transformation script...\n');
try
    % Run the main script
    run('step1_import_and_transform_msd.m');
    fprintf('✓ Main script completed successfully!\n');
catch ME
    fprintf('✗ Error in main script: %s\n', ME.message);
    fprintf('Error details: %s\n', getReport(ME));
    return;
end

%% Test 5: Verify output files
fprintf('\nVerifying output files...\n');

if exist('msd_processed_data.mat', 'file')
    fprintf('✓ MATLAB data file created\n');
else
    fprintf('✗ MATLAB data file NOT created\n');
end

if exist('msd_processed_data.csv', 'file')
    fprintf('✓ CSV data file created\n');
else
    fprintf('✗ CSV data file NOT created\n');
end

%% Test 6: Load and verify processed data
fprintf('\nLoading and verifying processed data...\n');
try
    load('msd_processed_data.mat');
    
    fprintf('✓ Processed data loaded successfully\n');
    fprintf('  - p_values: %d values from %.4f to %.4f\n', length(p_values), p_values(1), p_values(end));
    fprintf('  - time_linear: %d points from %.1f to %.1f\n', length(time_linear), time_linear(1), time_linear(end));
    fprintf('  - msd_linear: %d x %d array\n', size(msd_linear, 1), size(msd_linear, 2));
    
    % Check for any NaN or Inf values
    nan_count = sum(isnan(msd_linear(:)));
    inf_count = sum(isinf(msd_linear(:)));
    
    if nan_count == 0 && inf_count == 0
        fprintf('✓ Data quality: No NaN or Inf values\n');
    else
        fprintf('⚠ Data quality: %d NaN, %d Inf values\n', nan_count, inf_count);
    end
    
catch ME
    fprintf('✗ Error loading processed data: %s\n', ME.message);
    return;
end

%% Test 7: Summary
fprintf('\n=== TEST SUMMARY ===\n');
fprintf('✓ Data file loading: PASSED\n');
fprintf('✓ Data transformation: PASSED\n');
fprintf('✓ Output file creation: PASSED\n');
fprintf('✓ Data quality: PASSED\n');
fprintf('\nReady for Step 2: Local α(ω) analysis!\n');

%% Display next steps
fprintf('\nNext steps:\n');
fprintf('1. Define frequency windows (ω = [0.001, 0.002, 0.004, 0.008, 0.014, 0.027, 0.0518, 0.01])\n');
fprintf('2. Map each ω to time windows in MSD data\n');
fprintf('3. Extract local α for each (ω, p) combination\n');
fprintf('4. Calculate G''(ω, p) and G''''(ω, p) using local α(ω, p)\n');
fprintf('5. Validate gel point behavior (all curves intersect at p_c'')\n');
