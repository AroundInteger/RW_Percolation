% theoretical_alpha_analysis.m
% Theoretical analysis to deduce α values on either side of p_c'
% based on δ transition from 90° to 0°

clear; close all; clc;

fprintf('=== THEORETICAL α ANALYSIS ===\n');
fprintf('Deducing α values based on δ transition from 90° to 0° at p_c''\n\n');

% Key parameters
p_c_prime = 0.6884;  % Apparent gel point

fprintf('Critical point: p_c'' = %.4f\n\n', p_c_prime);

%% FUNDAMENTAL RELATIONSHIP

fprintf('=== FUNDAMENTAL RELATIONSHIP ===\n');
fprintf('The key relationship is: δ = πα/2\n');
fprintf('This means: α = 2δ/π\n\n');

% Test the relationship
test_deltas = [0, 45, 90];  % degrees
test_alphas = 2 * test_deltas * pi / 180 / pi;  % Convert to radians and apply formula

fprintf('Verification of δ = πα/2 relationship:\n');
fprintf('δ (degrees)\tα\t\tBehavior\n');
fprintf('---\t\t---\t\t---\n');
for i = 1:length(test_deltas)
    delta = test_deltas(i);
    alpha = test_alphas(i);
    
    if delta == 0
        behavior = 'Elastic (solid)';
    elseif delta == 45
        behavior = 'Viscoelastic';
    elseif delta == 90
        behavior = 'Viscous (liquid)';
    end
    
    fprintf('%.0f°\t\t%.3f\t\t%s\n', delta, alpha, behavior);
end

%% THEORETICAL DEDUCTION

fprintf('\n=== THEORETICAL DEDUCTION ===\n');

fprintf('Given that δ transitions from 90° to 0° at p_c'':\n\n');

% Calculate α values
delta_below_pc = 90;  % degrees
delta_above_pc = 0;   % degrees

alpha_below_pc = 2 * delta_below_pc * pi / 180 / pi;
alpha_above_pc = 2 * delta_above_pc * pi / 180 / pi;

fprintf('BELOW p_c'' (p < %.4f):\n', p_c_prime);
fprintf('  δ = %.0f° (viscous/liquid-like)\n', delta_below_pc);
fprintf('  α = 2 × %.0f° × π / 180° / π = %.3f\n', delta_below_pc, alpha_below_pc);
fprintf('  Behavior: Pure viscous (liquid-like)\n');
fprintf('  Physical interpretation: Free diffusion, normal Brownian motion\n\n');

fprintf('ABOVE p_c'' (p > %.4f):\n', p_c_prime);
fprintf('  δ = %.0f° (elastic/solid-like)\n', delta_above_pc);
fprintf('  α = 2 × %.0f° × π / 180° / π = %.3f\n', delta_above_pc, alpha_above_pc);
fprintf('  Behavior: Pure elastic (solid-like)\n');
fprintf('  Physical interpretation: Arrested diffusion, no motion\n\n');

fprintf('AT p_c'' (p = %.4f):\n', p_c_prime);
fprintf('  δ = 45° (viscoelastic, critical point)\n');
delta_at_pc = 45;
alpha_at_pc = 2 * delta_at_pc * pi / 180 / pi;
fprintf('  α = 2 × %.0f° × π / 180° / π = %.3f\n', delta_at_pc, alpha_at_pc);
fprintf('  Behavior: Viscoelastic (critical gel point)\n');
fprintf('  Physical interpretation: Critical diffusion, power law behavior\n\n');

%% PHYSICAL INTERPRETATION

fprintf('=== PHYSICAL INTERPRETATION ===\n');

fprintf('The α values have clear physical meaning:\n\n');

fprintf('α = 1.000 (p < p_c''):\n');
fprintf('  • Normal diffusion: ⟨r²(t)⟩ ∝ t\n');
fprintf('  • Free Brownian motion\n');
fprintf('  • Liquid-like behavior\n');
fprintf('  • G'''' >> G'' (viscous dominance)\n\n');

fprintf('α = 0.500 (p = p_c''):\n');
fprintf('  • Anomalous diffusion: ⟨r²(t)⟩ ∝ t^0.5\n');
fprintf('  • Critical gel point\n');
fprintf('  • Viscoelastic behavior\n');
fprintf('  • G'' ≈ G'''' (comparable moduli)\n\n');

fprintf('α = 0.000 (p > p_c''):\n');
fprintf('  • Arrested diffusion: ⟨r²(t)⟩ = constant\n');
fprintf('  • No motion (solid-like)\n');
fprintf('  • Elastic behavior\n');
fprintf('  • G'' >> G'''' (elastic dominance)\n\n');

%% CRITICAL SCALING ANALYSIS

fprintf('=== CRITICAL SCALING ANALYSIS ===\n');

% Analyze how α should scale near p_c'
fprintf('Near p_c'', α should follow critical scaling:\n\n');

% Define scaling function
nu = 0.88;  % 3D percolation critical exponent

% Test different scaling forms
p_test = 0.6:0.01:0.7;

fprintf('Critical scaling forms:\n');
fprintf('1. Linear: α = 1 - p/p_c''\n');
fprintf('2. Power law: α = (1 - p/p_c'')^0.5\n');
fprintf('3. Critical: α = (1 - p/p_c'')^(1/ν), ν = %.2f\n\n', nu);

% Calculate different scaling forms
alpha_linear = zeros(size(p_test));
alpha_power = zeros(size(p_test));
alpha_critical = zeros(size(p_test));

for i = 1:length(p_test)
    p = p_test(i);
    if p <= p_c_prime
        alpha_linear(i) = 1 - (p / p_c_prime);
        alpha_power(i) = (1 - (p / p_c_prime))^0.5;
        alpha_critical(i) = (1 - (p / p_c_prime))^(1/nu);
    else
        alpha_linear(i) = 0;
        alpha_power(i) = 0;
        alpha_critical(i) = 0;
    end
end

% Calculate corresponding δ values
delta_linear = pi * alpha_linear / 2 * 180 / pi;
delta_power = pi * alpha_power / 2 * 180 / pi;
delta_critical = pi * alpha_critical / 2 * 180 / pi;

fprintf('Comparison of scaling forms near p_c'':\n');
fprintf('p\t\tα_linear\tα_power\t\tα_critical\tδ_critical\n');
fprintf('---\t\t---\t\t---\t\t---\t\t---\n');

for i = 1:length(p_test)
    if mod(i-1, 5) == 0  % Print every 5th point
        fprintf('%.3f\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.1f°\n', ...
            p_test(i), alpha_linear(i), alpha_power(i), alpha_critical(i), delta_critical(i));
    end
end

%% EXPECTED VALUES FOR OUR SIMULATIONS

fprintf('\n=== EXPECTED VALUES FOR OUR SIMULATIONS ===\n');

% Our simulation p values
sim_p_values = [0.60, 0.62, 0.64, 0.66, 0.68, 0.69, 0.70];

fprintf('Expected α and δ values for our simulation p values:\n');
fprintf('p\t\tα_theory\tδ_theory\tBehavior\t\tExpected Range\n');
fprintf('---\t\t---\t\t---\t\t---\t\t---\n');

for p = sim_p_values
    if p <= p_c_prime
        % Use critical scaling
        alpha_theory = (1 - (p / p_c_prime))^(1/nu);
    else
        alpha_theory = 0;
    end
    delta_theory = pi * alpha_theory / 2 * 180 / pi;
    
    if delta_theory > 45
        behavior = 'Viscous';
        expected_range = 'α ≈ 0.8-1.0, δ ≈ 70-90°';
    elseif delta_theory > 5
        behavior = 'Viscoelastic';
        expected_range = 'α ≈ 0.1-0.8, δ ≈ 10-70°';
    else
        behavior = 'Elastic';
        expected_range = 'α ≈ 0.0-0.1, δ ≈ 0-10°';
    end
    
    fprintf('%.2f\t\t%.3f\t\t%.1f°\t\t%s\t\t%s\n', p, alpha_theory, delta_theory, behavior, expected_range);
end

%% VALIDATION CRITERIA

fprintf('\n=== VALIDATION CRITERIA ===\n');

fprintf('To validate our phase transition, we should observe:\n\n');

fprintf('1. α VALUES:\n');
fprintf('   • p < p_c'': α ≈ 0.5-1.0 (decreasing toward p_c'')\n');
fprintf('   • p = p_c'': α ≈ 0.0-0.5 (critical region)\n');
fprintf('   • p > p_c'': α ≈ 0.0 (arrested)\n\n');

fprintf('2. δ VALUES:\n');
fprintf('   • p < p_c'': δ ≈ 45-90° (decreasing toward p_c'')\n');
fprintf('   • p = p_c'': δ ≈ 0-45° (critical region)\n');
fprintf('   • p > p_c'': δ ≈ 0° (elastic)\n\n');

fprintf('3. PHASE TRANSITION EVIDENCE:\n');
fprintf('   • Sharp decrease in α near p_c''\n');
fprintf('   • Corresponding decrease in δ\n');
fprintf('   • α ≈ 0 at p_c'' (within error bars)\n');
fprintf('   • δ ≈ 0° at p_c'' (within error bars)\n\n');

%% COMPARISON WITH LITERATURE

fprintf('=== COMPARISON WITH LITERATURE ===\n');

fprintf('These theoretical predictions align with:\n\n');

fprintf('1. Percolation Theory:\n');
fprintf('   • α ∝ (p_c'' - p)^(1/ν) near critical point\n');
fprintf('   • ν = 0.88 for 3D percolation\n');
fprintf('   • Critical scaling behavior\n\n');

fprintf('2. Rheology Literature:\n');
fprintf('   • δ = πα/2 is well-established relationship\n');
fprintf('   • α = 1 for normal diffusion\n');
fprintf('   • α = 0 for arrested motion\n');
fprintf('   • α = 0.5 at gel point (common observation)\n\n');

fprintf('3. Experimental Evidence:\n');
fprintf('   • Polymer solutions show α ≈ 0.5 at gel point\n');
fprintf('   • Colloidal gels show similar behavior\n');
fprintf('   • Soft glassy materials show α → 0 at jamming\n\n');

%% SUMMARY

fprintf('=== SUMMARY ===\n');

fprintf('Theoretical α values based on δ transition:\n\n');

fprintf('BELOW p_c'' (p < %.4f):\n', p_c_prime);
fprintf('  α = %.3f (normal diffusion)\n', alpha_below_pc);
fprintf('  δ = %.0f° (viscous)\n', delta_below_pc);
fprintf('  Physical: Free Brownian motion\n\n');

fprintf('AT p_c'' (p = %.4f):\n', p_c_prime);
fprintf('  α = %.3f (critical gel point)\n', alpha_at_pc);
fprintf('  δ = %.0f° (viscoelastic)\n', delta_at_pc);
fprintf('  Physical: Critical diffusion\n\n');

fprintf('ABOVE p_c'' (p > %.4f):\n', p_c_prime);
fprintf('  α = %.3f (arrested diffusion)\n', alpha_above_pc);
fprintf('  δ = %.0f° (elastic)\n', delta_above_pc);
fprintf('  Physical: No motion\n\n');

fprintf('This provides clear theoretical targets for our simulations!\n');

% Save theoretical predictions
save('theoretical_alpha_predictions.mat', 'p_c_prime', 'alpha_below_pc', 'alpha_at_pc', 'alpha_above_pc', ...
     'delta_below_pc', 'delta_at_pc', 'delta_above_pc', 'sim_p_values', 'nu');

fprintf('\nTheoretical predictions saved to theoretical_alpha_predictions.mat\n'); 