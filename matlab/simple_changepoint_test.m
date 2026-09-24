function simple_changepoint_test()
% Simple test to debug changepoint detection

fprintf('=== Simple Changepoint Test ===\n');

% Generate test data
t = logspace(0, 4, 1000)';
p = 0.64;
p_c_prime = 0.6884;

% Generate synthetic MSD data
if p < p_c_prime - 0.05
    % Liquid regime: MSD ∝ t
    alpha = 1.0;
    D_eff = 0.1;
    msd = 6 * D_eff * t.^alpha;
    
    % Add some noise and finite-size effects
    noise_level = 0.05;
    msd = msd .* (1 + noise_level * randn(size(msd)));
    
    % Add finite-size effects at early times
    finite_size_region = t < 100;
    msd(finite_size_region) = msd(finite_size_region) .* (t(finite_size_region)/100).^0.5;
    
elseif abs(p - p_c_prime) < 0.05
    % Critical regime: MSD ∝ t^0.5
    alpha = 0.5;
    D_eff = 0.05;
    msd = 6 * D_eff * t.^alpha;
    
    % Add transition to regular diffusion at late times
    transition_time = 1000;
    transition_region = t > transition_time;
    msd(transition_region) = msd(transition_region) .* (t(transition_region)/transition_time).^0.5;
    
    % Add noise
    noise_level = 0.1;
    msd = msd .* (1 + noise_level * randn(size(msd)));
    
else
    % Solid regime: MSD ≈ constant
    msd_plateau = 10.0;
    msd = msd_plateau * ones(size(t));
    
    % Add small fluctuations
    noise_level = 0.02;
    msd = msd .* (1 + noise_level * randn(size(msd)));
end

% Ensure positive values
msd = max(msd, 1e-6);

fprintf('Generated test data: p = %.4f, %d points\n', p, length(t));

% Test Method 1: Current approach
fprintf('\n--- Testing Current Method ---\n');
try
    [tau_cr1, quality1] = detect_liquid_crossover_parallel(t, msd);
    fprintf('Current method: τ_cr = %.2e, quality = %s\n', tau_cr1, quality1);
catch ME
    fprintf('Current method error: %s\n', ME.message);
end

% Test Method 2: Second derivative approach
fprintf('\n--- Testing Second Derivative Method ---\n');
try
    [tau_cr2, quality2, details2] = detect_curvature_changepoint(t, msd);
    fprintf('Second derivative method: τ_cr = %.2e, quality = %s\n', tau_cr2, quality2);
catch ME
    fprintf('Second derivative method error: %s\n', ME.message);
end

% Test Method 4: Theoretical approach
fprintf('\n--- Testing Theoretical Method ---\n');
try
    [tau_cr4, quality4, details4] = theoretical_changepoint_detection(t, msd, p, p_c_prime);
    fprintf('Theoretical method: τ_cr = %.2e, quality = %s\n', tau_cr4, quality4);
catch ME
    fprintf('Theoretical method error: %s\n', ME.message);
end

% Test Method 5: Bisection approach
fprintf('\n--- Testing Bisection Method ---\n');
try
    [tau_cr5, quality5, details5] = bisection_piecewise_fitting(t, msd, p, p_c_prime);
    fprintf('Bisection method: τ_cr = %.2e, quality = %s\n', tau_cr5, quality5);
catch ME
    fprintf('Bisection method error: %s\n', ME.message);
end

fprintf('\n=== Test Complete ===\n');

end 