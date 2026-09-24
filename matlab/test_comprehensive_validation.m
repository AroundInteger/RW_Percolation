% test_comprehensive_validation.m
% Simple test to verify comprehensive validation works

clear; close all; clc;

fprintf('=== TESTING COMPREHENSIVE VALIDATION ===\n');

try
    % Test with a simple case first
    fprintf('Testing comprehensive validation function...\n');
    
    % Check if the function exists
    if exist('comprehensive_validation', 'file') == 2
        fprintf('✓ comprehensive_validation function found\n');
        
        % Run a quick test
        fprintf('Running comprehensive validation...\n');
        comprehensive_validation();
        
        fprintf('✓ Comprehensive validation completed successfully\n');
    else
        fprintf('❌ comprehensive_validation function not found\n');
        fprintf('Please ensure comprehensive_validation.m is in the MATLAB path\n');
    end
    
catch ME
    fprintf('❌ ERROR in comprehensive validation test:\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('\nStack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
    
    fprintf('\nTroubleshooting:\n');
    fprintf('• Ensure all required functions are available\n');
    fprintf('• Check that robust_msd_validation.m is in the path\n');
    fprintf('• Verify MATLAB has sufficient memory\n');
end

fprintf('\nTest completed.\n'); 