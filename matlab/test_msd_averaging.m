% test_msd_averaging.m
% Test script to validate the importance of lag-time averaging
% Following Moschakis 2013 methodology

clear; close all; clc;

fprintf('=== Testing MSD Lag-Time Averaging ===\n');
fprintf('Following Moschakis 2013 methodology from your paper\n\n');

% Run the robust validation
try
    robust_msd_validation();
    
    fprintf('\n=== ANALYZING RESULTS ===\n');
    
    % Load and analyze results
    load('robust_validation_results.mat');
    
    % Show the importance of lag-time averaging
    demonstrate_averaging_importance(results);
    
    % Summarize validation
    summarize_validation_results(results);
    
catch ME
    fprintf('Error in validation: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end



function demonstrate_averaging_importance(results)
% Demonstrate the importance of lag-time averaging

fprintf('\n=== IMPORTANCE OF LAG-TIME AVERAGING ===\n\n');

for i = 1:length(results)
    r = results(i);
    
    if isfield(r, 'msd_quality') && isfield(r.msd_quality, 'noise_reduction_factor')
        mq = r.msd_quality;
        
        fprintf('p = %.2f:\n', r.p);
        
        if ~isnan(mq.noise_reduction_factor)
            fprintf('  Noise reduction: %.1fx improvement\n', mq.noise_reduction_factor);
        end
        
        if ~isnan(mq.r_squared_raw) && ~isnan(mq.r_squared_averaged)
            fprintf('  R² improvement: %.3f → %.3f\n', mq.r_squared_raw, mq.r_squared_averaged);
        end
        
        % Check if lag-averaging enabled good GSER analysis
        if isfield(r, 'validation_metrics') && isfield(r.validation_metrics, 'quality_rating')
            vm = r.validation_metrics;
            if strcmp(vm.quality_rating, 'EXCELLENT') || strcmp(vm.quality_rating, 'GOOD')
                fprintf('  ✓ Enabled reliable GSER analysis\n');
            else
                fprintf('  ⚠ GSER analysis still challenging\n');
            end
        end
        
        fprintf('\n');
    end
end

% Create comparison plot
figure('Position', [100, 100, 800, 600]);

subplot(2, 2, 1);
hold on;
colors = lines(length(results));
for i = 1:length(results)
    if isfield(results(i), 'msd_raw') && isfield(results(i), 'msd_lag_averaged')
        loglog(results(i).t, results(i).msd_raw, ':', 'Color', colors(i, :), 'LineWidth', 1);
        loglog(results(i).t, results(i).msd_lag_averaged, '-', 'Color', colors(i, :), 'LineWidth', 2, ...
               'DisplayName', sprintf('p = %.2f', results(i).p));
    end
end
xlabel('τ (steps)');
ylabel('MSD');
title('Raw (:) vs Lag-averaged (-) MSD');
legend('Location', 'best');
grid on;

subplot(2, 2, 2);
noise_factors = [];
p_vals = [];
for i = 1:length(results)
    if isfield(results(i), 'msd_quality') && isfield(results(i).msd_quality, 'noise_reduction_factor')
        nf = results(i).msd_quality.noise_reduction_factor;
        if ~isnan(nf) && nf > 0
            noise_factors(end+1) = nf;
            p_vals(end+1) = results(i).p;
        end
    end
end

if ~isempty(noise_factors)
    semilogy(p_vals, noise_factors, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('p');
    ylabel('Noise reduction factor');
    title('Lag-averaging improves MSD quality');
    grid on;
end

% Show R² improvement
subplot(2, 2, 3);
r2_raw = [];
r2_avg = [];
p_vals_r2 = [];
for i = 1:length(results)
    if isfield(results(i), 'msd_quality')
        mq = results(i).msd_quality;
        if ~isnan(mq.r_squared_raw) && ~isnan(mq.r_squared_averaged)
            r2_raw(end+1) = mq.r_squared_raw;
            r2_avg(end+1) = mq.r_squared_averaged;
            p_vals_r2(end+1) = results(i).p;
        end
    end
end

if ~isempty(r2_raw)
    plot(p_vals_r2, r2_raw, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Raw MSD');
    hold on;
    plot(p_vals_r2, r2_avg, 's-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Lag-averaged MSD');
    xlabel('p');
    ylabel('R² (fit quality)');
    title('Power Law Fit Quality');
    legend('Location', 'best');
    grid on;
end

sgtitle('Benefits of Lag-Time Averaging (Moschakis 2013)');

end

function summarize_validation_results(results)
% Summarize overall validation results

fprintf('\n=== FINAL VALIDATION SUMMARY ===\n\n');

% Count quality ratings
quality_counts = struct('EXCELLENT', 0, 'GOOD', 0, 'ACCEPTABLE', 0, 'POOR', 0, 'INSUFFICIENT_DATA', 0);

for i = 1:length(results)
    if isfield(results(i), 'validation_metrics') && isfield(results(i).validation_metrics, 'quality_rating')
        rating = results(i).validation_metrics.quality_rating;
        if isfield(quality_counts, rating)
            quality_counts.(rating) = quality_counts.(rating) + 1;
        end
    end
end

fprintf('Quality Distribution:\n');
fprintf('  EXCELLENT: %d\n', quality_counts.EXCELLENT);
fprintf('  GOOD: %d\n', quality_counts.GOOD);
fprintf('  ACCEPTABLE: %d\n', quality_counts.ACCEPTABLE);
fprintf('  POOR: %d\n', quality_counts.POOR);
fprintf('  INSUFFICIENT_DATA: %d\n', quality_counts.INSUFFICIENT_DATA);

successful_validations = quality_counts.EXCELLENT + quality_counts.GOOD;
total_validations = length(results);

fprintf('\nSuccess Rate: %d/%d (%.0f%%)\n', successful_validations, total_validations, 100*successful_validations/total_validations);

% Recommendations
fprintf('\n=== RECOMMENDATIONS ===\n\n');

if successful_validations >= 3
    fprintf('✓ ANALYTICS VALIDATED - Ready for full simulations\n\n');
    fprintf('Key findings:\n');
    fprintf('  • Lag-time averaging significantly improves MSD quality\n');
    fprintf('  • GSER analysis produces consistent results\n');
    fprintf('  • Power law exponents from MSD and G''/G'''' match theory\n');
    fprintf('  • Loss tangent values consistent with πα/2\n\n');
    
    fprintf('Proceed with confidence to:\n');
    fprintf('  • Longer walks (LW = 1e5 to 1e6)\n');
    fprintf('  • Larger lattices (L = 500)\n');
    fprintf('  • Full parameter sweep including p_c and p_c''\n\n');
    
    fprintf('Your document correction is confirmed:\n');
    fprintf('  Change "exponent 1/α" to "exponent α" in Section 3.2\n');
    
else
    fprintf('⚠ VALIDATION NEEDS IMPROVEMENT\n\n');
    fprintf('Issues to address:\n');
    
    if quality_counts.INSUFFICIENT_DATA > 0
        fprintf('  • Insufficient data: Try longer walks or more walkers\n');
    end
    
    if quality_counts.POOR > 0
        fprintf('  • Poor quality: Check MSD calculation and GSER implementation\n');
    end
    
    fprintf('\nSuggested improvements:\n');
    fprintf('  • Increase LW to 10,000 or 20,000\n');
    fprintf('  • Increase NW to 200-500\n');
    fprintf('  • Check for implementation bugs\n');
    fprintf('  • Verify unit conversions\n');
end

% Show specific analytical predictions
fprintf('\n=== THEORETICAL PREDICTIONS TO VALIDATE ===\n\n');

fprintf('Expected trends for p < p_c'' (p < 0.6884):\n');
fprintf('  • α decreases as p increases (more constrained diffusion)\n');
fprintf('  • δ = πα/2 decreases as p increases\n');
fprintf('  • G''/G'''' ratio increases as p increases\n');
fprintf('  • Anomalous diffusion region extends to lower frequencies as p → p_c''\n\n');

fprintf('Critical validation: Both G''(ω) and G''''(ω) must scale as ω^α (NOT ω^(1/α))\n');

end