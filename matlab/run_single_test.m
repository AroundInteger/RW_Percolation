% run_single_test.m
% Test comprehensive validation with just one p value

clear; close all; clc;

fprintf('=== SINGLE P-VALUE COMPREHENSIVE VALIDATION TEST ===\n');
fprintf('Testing the fixed GSER implementation with p = 0.10\n\n');

% Modify the comprehensive validation to test just one p value
% We'll create a simplified version that tests the core functionality

% Parameters
L = 100;           % Lattice size
LW = 10000;        % Walk length
NW = 100;          % Number of walkers
p_values = [0.10]; % Just test one p value
p_c_prime = 0.6884;  % Apparent gel point
seed = 42;

fprintf('Parameters: L=%d, LW=%d, NW=%d\n', L, LW, NW);
fprintf('Testing p value: %.2f (should be < p_c'' = %.4f)\n\n', p_values(1), p_c_prime);

% Initialize results structure
results = struct();

for i = 1:length(p_values)
    p_val = p_values(i);
    fprintf('=== Testing p = %.2f ===\n', p_val);
    
    % Run simulation and get MSD data
    [t, msd_raw, msd_lag_averaged, trajectory_stats] = run_robust_simulation(p_val, L, LW, NW, i);
    
    % Apply GSER analysis
    [gser_results, validation_metrics] = robust_gser_analysis(t, msd_lag_averaged, p_val);
    
    % Perform comprehensive validation checks
    validation_checks = perform_comprehensive_validation_checks(gser_results, validation_metrics, p_val, p_c_prime);
    
    % Store results
    results(i).p = p_val;
    results(i).t = t;
    results(i).msd_raw = msd_raw;
    results(i).msd_lag_averaged = msd_lag_averaged;
    results(i).gser_results = gser_results;
    results(i).validation_metrics = validation_metrics;
    results(i).validation_checks = validation_checks;
    
    % Report results
    report_validation_results(p_val, validation_checks, validation_metrics);
end

fprintf('\n=== SINGLE TEST COMPLETED ===\n');
fprintf('Check the results above to verify the GSER implementation is working.\n');
fprintf('If this passes, you can run the full comprehensive validation.\n');

% Save results
save('single_test_results.mat', 'results', 'p_values', 'p_c_prime');
fprintf('Results saved to single_test_results.mat\n'); 