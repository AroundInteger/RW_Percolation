% test_analytics.m
% Simple test runner for analytics validation
% Run this first before your full simulations

clear; close all; clc;

fprintf('=== Testing Analytics vs Numerics ===\n\n');

% Run quick validation
try
    quick_analytics_validation();
    
    % Load and examine results
    load('quick_validation_results.mat');
    
    fprintf('=== VALIDATION SUMMARY ===\n');
    
    for i = 1:length(results)
        r = results(i);
        fprintf('\np = %.2f:\n', r.p);
        fprintf('  MSD exponent α = %.3f\n', r.alpha_fit);
        
        if ~isnan(r.validation.alpha_Gp) && ~isnan(r.validation.alpha_Gpp)
            fprintf('  G'' exponent   = %.3f\n', r.validation.alpha_Gp);
            fprintf('  G'''' exponent  = %.3f\n', r.validation.alpha_Gpp);
            
            % Check consistency
            alpha_diff_Gp = abs(r.alpha_fit - r.validation.alpha_Gp);
            alpha_diff_Gpp = abs(r.alpha_fit - r.validation.alpha_Gpp);
            
            if alpha_diff_Gp < 0.1 && alpha_diff_Gpp < 0.1
                fprintf('  ✓ Power law consistency: GOOD\n');
            else
                fprintf('  ⚠ Power law consistency: CHECK NEEDED\n');
            end
            
            % Check ratio consistency
            if r.validation.ratio_std < 0.5
                fprintf('  ✓ G''/G'''' ratio consistency: GOOD\n');
            else
                fprintf('  ⚠ G''/G'''' ratio consistency: NOISY\n');
            end
            
            % Check loss tangent
            delta_diff = abs(r.validation.delta_theory_deg - r.validation.delta_measured_deg);
            if delta_diff < 5
                fprintf('  ✓ Loss tangent: GOOD (theory: %.1f°, measured: %.1f°)\n', ...
                    r.validation.delta_theory_deg, r.validation.delta_measured_deg);
            else
                fprintf('  ⚠ Loss tangent: CHECK (theory: %.1f°, measured: %.1f°)\n', ...
                    r.validation.delta_theory_deg, r.validation.delta_measured_deg);
            end
        else
            fprintf('  ⚠ GSER analysis failed - check MSD quality\n');
        end
    end
    
    fprintf('\n=== NEXT STEPS ===\n');
    fprintf('If most checks show ✓ GOOD:\n');
    fprintf('  → Proceed to longer walks (LW = 1e5 or 1e6)\n');
    fprintf('  → Use your full RW3D_paper_batch_p_seed function\n\n');
    
    fprintf('If checks show ⚠ issues:\n');
    fprintf('  → Examine plots for anomalous regions\n');
    fprintf('  → Check MSD fitting algorithm\n');
    fprintf('  → Verify GSER implementation\n\n');
    
    fprintf('Plots saved as validation figures.\n');
    
catch ME
    fprintf('Error in validation: %s\n', ME.message);
    fprintf('Check that all required functions are available.\n');
end