% TEST_CONSOLIDATED_VERIFICATION
% Test script for the consolidated physical verification system
%
% This script demonstrates the functionality of the consolidated
% physical verification system and provides a simple interface
% for testing individual components.

function test_consolidated_verification()
    fprintf('=== TESTING CONSOLIDATED PHYSICAL VERIFICATION ===\n');
    fprintf('Testing individual components of the verification system\n\n');
    
    % Test 1: Sigmoid function calculation
    fprintf('Test 1: Sigmoid function calculation\n');
    test_sigmoid_function();
    
    % Test 2: Data structure creation
    fprintf('\nTest 2: Data structure creation\n');
    test_data_structures();
    
    % Test 3: Plot generation (if surface data available)
    fprintf('\nTest 3: Plot generation test\n');
    test_plot_generation();
    
    fprintf('\n=== ALL TESTS COMPLETED ===\n');
end

function test_sigmoid_function()
    % Test the sigmoid function for α calculation
    
    % Test parameters
    p_c = 0.6884;
    width = 0.015;
    alpha_min = 0.0;
    alpha_max = 1.0;
    
    % Test p-values
    test_p_values = [0.1, 0.3116, 0.6884, 0.8];
    expected_alphas = [1.0, 1.0, 0.5, 0.0];
    
    fprintf('  Testing sigmoid function for different p-values:\n');
    
    for i = 1:length(test_p_values)
        p_val = test_p_values(i);
        expected = expected_alphas(i);
        calculated = get_alpha_from_sigmoid(p_val, p_c, width, alpha_min, alpha_max);
        
        error = abs(calculated - expected);
        if error < 0.1
            status = '✓';
        else
            status = '⚠';
        end
        
        fprintf('    p = %.4f: α = %.4f (expected %.1f) %s\n', ...
                p_val, calculated, expected, status);
    end
end

function test_data_structures()
    % Test data structure creation and manipulation
    
    % Create test p_values structure
    p_values = struct();
    p_values.liquid = 0.1;
    p_values.p_c = 0.3116;
    p_values.p_c_prime = 0.6884;
    p_values.solid = 0.8;
    
    fprintf('  Created p_values structure with %d regimes:\n', length(fieldnames(p_values)));
    
    regimes = fieldnames(p_values);
    for i = 1:length(regimes)
        regime = regimes{i};
        p_val = p_values.(regime);
        fprintf('    %s: p = %.4f\n', regime, p_val);
    end
    
    % Test actual_alphas structure
    actual_alphas = struct();
    actual_alphas.liquid = 1.0;
    actual_alphas.p_c = 1.0;
    actual_alphas.p_c_prime = 0.5;
    actual_alphas.solid = 0.0;
    
    fprintf('  Created actual_alphas structure:\n');
    for i = 1:length(regimes)
        regime = regimes{i};
        alpha = actual_alphas.(regime);
        fprintf('    %s: α = %.3f\n', regime, alpha);
    end
end

function test_plot_generation()
    % Test plot generation functionality
    
    fprintf('  Testing plot generation components...\n');
    
    % Check if surface data directory exists
    surface_data_dir = 'output_3d_surfaces/surface_data';
    if exist(surface_data_dir, 'dir')
        fprintf('    ✓ Surface data directory found\n');
        
        % Check for required files (prefer .mat files, fallback to .npy)
        required_files = {'viscoelastic_surfaces_comprehensive.mat'};
        fallback_files = {'p_grid.mat', 'omega_grid.mat', 'G_prime_surface.mat', ...
                         'G_double_prime_surface.mat', 'delta_surface.mat', 'tan_delta_surface.mat'};
        
        missing_files = {};
        for i = 1:length(required_files)
            file_path = fullfile(surface_data_dir, required_files{i});
            if ~exist(file_path, 'file')
                missing_files{end+1} = required_files{i};
            end
        end
        
        if isempty(missing_files)
            fprintf('    ✓ All required surface data files found\n');
            fprintf('    ✓ Ready to run full verification\n');
        else
            fprintf('    ⚠ Missing comprehensive file: %s\n', strjoin(missing_files, ', '));
            fprintf('    ⚠ Checking fallback files...\n');
            
            % Check fallback files
            missing_fallback = {};
            for i = 1:length(fallback_files)
                file_path = fullfile(surface_data_dir, fallback_files{i});
                if ~exist(file_path, 'file')
                    missing_fallback{end+1} = fallback_files{i};
                end
            end
            
            if isempty(missing_fallback)
                fprintf('    ✓ All fallback .mat files found\n');
                fprintf('    ✓ Ready to run full verification\n');
            else
                fprintf('    ⚠ Missing fallback files: %s\n', strjoin(missing_fallback, ', '));
                fprintf('    ⚠ Please run:\n');
                fprintf('      1. python viscoelastic_3d_surfaces.py\n');
                fprintf('      2. python convert_npy_to_mat.py\n');
            end
        end
    else
        fprintf('    ⚠ Surface data directory not found\n');
        fprintf('    ⚠ Please run:\n');
        fprintf('      1. python viscoelastic_3d_surfaces.py\n');
        fprintf('      2. python convert_npy_to_mat.py\n');
    end
end

function alpha = get_alpha_from_sigmoid(p_value, p_c, width, alpha_min, alpha_max)
    % Calculate α value using sigmoid function
    % α(p) = α_min + (α_max - α_min) / (1 + exp((p - p_c) / width))
    
    alpha = alpha_min + (alpha_max - alpha_min) / (1 + exp((p_value - p_c) / width));
    
    % Ensure bounds
    alpha = max(alpha_min, min(alpha_max, alpha));
end

% % Main execution
% if ~exist('OCTAVE_VERSION', 'builtin')
%     % This is MATLAB
%     fprintf('Running in MATLAB environment\n');
% else
%     % This is Octave
%     fprintf('Running in Octave environment\n');
% end
% 
% % Run tests
% test_consolidated_verification();
