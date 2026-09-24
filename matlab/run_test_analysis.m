% run_test_analysis.m
% Simple script to test the modified lattice random walk analysis

fprintf('=== TESTING MODIFIED LATTICE RANDOM WALK ANALYSIS ===\n');

% Test parameters
p_values = [0.1, 0.5, 0.8];
variants = {'standard'};
L = 30;
LW = 5000;
NW = 50;
output_dir = 'test_output';

fprintf('Parameters:\n');
fprintf('  p_values: [%.1f, %.1f, %.1f]\n', p_values(1), p_values(2), p_values(3));
fprintf('  variants: %s\n', variants{1});
fprintf('  L: %d, LW: %d, NW: %d\n', L, LW, NW);
fprintf('  output_dir: %s\n\n', output_dir);

% Run the analysis
try
    analyze_lattice_random_walks_modified(p_values, variants, L, LW, NW, output_dir);
    fprintf('\n=== TEST COMPLETED SUCCESSFULLY ===\n');
catch ME
    fprintf('\n=== TEST FAILED ===\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end
