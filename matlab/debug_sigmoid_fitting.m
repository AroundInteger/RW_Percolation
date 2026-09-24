% debug_sigmoid_fitting.m
% Debug script to identify sigmoid fitting issues

clear; close all; clc;

fprintf('\n=== DEBUGGING SIGMOID FITTING ===\n');

% Load the data
mat_file = 'Clusters1/random_walk_analysis_L500_LW1000000_NW3000.mat';
load(mat_file);

alpha_file = 'Clusters1/output/universality_class_analysis.mat';
load(alpha_file);

fprintf('Data loaded successfully:\n');
fprintf('  MSD_results: %s\n', mat2str(size(MSD_results)));
fprintf('  p_values: %s\n', mat2str(size(p_values)));
fprintf('  alpha_results: %s\n', mat2str(size(alpha_results)));
fprintf('  variants: %s\n', strjoin(variants, ', '));

% Define universality classes
templated_variants = {'6N_Templated', '26N_Templated'};
standard_variants = {'Random_Percolation', 'Density_Increment'};

% Extract data for templated class
fprintf('\n=== EXTRACTING TEMPLATED CLASS DATA ===\n');
variant_indices = [];
for i = 1:length(templated_variants)
    idx = find(strcmp(variants, templated_variants{i}));
    if ~isempty(idx)
        variant_indices = [variant_indices, idx];
        fprintf('  Found %s at index %d\n', templated_variants{i}, idx);
    end
end

fprintf('  Variant indices: %s\n', mat2str(variant_indices));

if ~isempty(variant_indices)
    class_alpha = alpha_results(:, variant_indices);
    class_alpha_mean = mean(class_alpha, 2);
    
    fprintf('  class_alpha size: %s\n', mat2str(size(class_alpha)));
    fprintf('  class_alpha_mean size: %s\n', mat2str(size(class_alpha_mean)));
    fprintf('  p_values size: %s\n', mat2str(size(p_values)));
    
    % Check for NaN values
    nan_count = sum(isnan(class_alpha_mean));
    fprintf('  NaN values in alpha: %d\n', nan_count);
    
    % Check data ranges
    fprintf('  p_values range: [%.3f, %.3f]\n', min(p_values), max(p_values));
    fprintf('  alpha range: [%.3f, %.3f]\n', min(class_alpha_mean), max(class_alpha_mean));
    
    % Test sigmoid function
    fprintf('\n=== TESTING SIGMOID FUNCTION ===\n');
    test_params = [0.6884, 0.05, 0.0, 1.0];
    try
        test_alpha = sigmoid_function(test_params, p_values);
        fprintf('  Sigmoid function test successful\n');
        fprintf('  test_alpha size: %s\n', mat2str(size(test_alpha)));
        fprintf('  test_alpha range: [%.3f, %.3f]\n', min(test_alpha), max(test_alpha));
    catch ME
        fprintf('  Sigmoid function test failed: %s\n', ME.message);
    end
end

function alpha = sigmoid_function(params, p_values)
% Sigmoid function for α(p) relationship

p_c = params(1);
width = params(2);
alpha_min = max(0.0, params(3));
alpha_max = min(1.0, params(4));

alpha = alpha_min + (alpha_max - alpha_min) ./ (1 + exp((p_values - p_c) / width));

end
