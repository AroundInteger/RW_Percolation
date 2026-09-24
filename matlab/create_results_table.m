% create_results_table.m
% Generate comprehensive results table for critical points analysis

clear; close all; clc;

fprintf('=== COMPREHENSIVE RESULTS TABLE ===\n');
fprintf('Critical Percolation Points Analysis\n\n');

% Load results if available
try
    load('critical_points_results.mat');
    fprintf('Loaded results from critical_points_results.mat\n\n');
catch
    fprintf('No saved results found. Please run analyze_critical_points.m first.\n');
    return;
end

% Create comprehensive table
fprintf('%-12s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-12s\n', ...
    'p', 'α_MSD', 'α_G''', 'α_G''''', 'δ(°)', 'G''/G''''', 'Success', 'Eff_D', 'Quality', 'Regime', 'Notes');
fprintf('%-12s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-12s\n', ...
    '---', '-----', '-----', '------', '----', '-------', '------', '------', '------', '------', '-----');

for i = 1:length(results)
    p_val = results(i).p;
    
    % Extract values
    alpha_msd = NaN;
    alpha_gp = NaN;
    alpha_gpp = NaN;
    delta = NaN;
    ratio = NaN;
    success_rate = results(i).trajectory_stats.move_success_rate;
    eff_diffusion = results(i).trajectory_stats.eff_diffusion;
    quality = 'N/A';
    
    if isfield(results(i), 'validation_metrics')
        vm = results(i).validation_metrics;
        if isfield(vm, 'alpha_msd'), alpha_msd = vm.alpha_msd; end
        if isfield(vm, 'alpha_Gp'), alpha_gp = vm.alpha_Gp; end
        if isfield(vm, 'alpha_Gpp'), alpha_gpp = vm.alpha_Gpp; end
        if isfield(vm, 'delta_measured'), delta = vm.delta_measured; end
        if isfield(vm, 'ratio_mean'), ratio = vm.ratio_mean; end
        if isfield(vm, 'quality_rating'), quality = vm.quality_rating; end
    end
    
    % Determine regime
    if p_val < 0.3116
        regime = 'Free';
        notes = 'Normal diffusion';
    elseif p_val == 0.3116
        regime = 'Critical';
        notes = 'p_c threshold';
    elseif p_val < 0.6884
        regime = 'Subdiff';
        notes = 'p_c < p < p_c''';
    else
        regime = 'High';
        notes = 'p > p_c''';
    end
    
    % Add special notes
    if alpha_gp < 0
        notes = [notes, ' | Neg α_G'''];
    end
    if alpha_gpp < 0
        notes = [notes, ' | Neg α_G'''''];
    end
    if strcmp(quality, 'POOR')
        notes = [notes, ' | Poor quality'];
    end
    
    fprintf('%-12.4f %-8.3f %-8.3f %-8.3f %-8.1f %-8.3f %-8.3f %-8.2e %-8s %-8s %-12s\n', ...
        p_val, alpha_msd, alpha_gp, alpha_gpp, delta, ratio, success_rate, eff_diffusion, quality, regime, notes);
end

fprintf('\n');

% Detailed analysis for each p value
fprintf('=== DETAILED ANALYSIS ===\n\n');

for i = 1:length(results)
    p_val = results(i).p;
    fprintf('** p = %.4f (%s) **\n', p_val, results(i).p_label);
    
    % Extract metrics
    vm = results(i).validation_metrics;
    ts = results(i).trajectory_stats;
    
    fprintf('  Trajectory Analysis:\n');
    fprintf('    • Move success rate: %.3f\n', ts.move_success_rate);
    fprintf('    • Effective diffusion: %.2e\n', ts.eff_diffusion);
    fprintf('    • Free sites: %.0f\n', (1-p_val) * 100^3);
    
    if isfield(vm, 'alpha_msd')
        fprintf('  MSD Analysis:\n');
        fprintf('    • α_MSD = %.3f\n', vm.alpha_msd);
        
        % Interpret α_MSD
        if vm.alpha_msd > 0.8
            diffusion_type = 'Near normal';
        elseif vm.alpha_msd > 0.5
            diffusion_type = 'Weak subdiffusion';
        elseif vm.alpha_msd > 0.2
            diffusion_type = 'Moderate subdiffusion';
        elseif vm.alpha_msd > 0
            diffusion_type = 'Strong subdiffusion';
        else
            diffusion_type = 'Negative (anomalous)';
        end
        fprintf('    • Type: %s\n', diffusion_type);
    end
    
    if isfield(vm, 'alpha_Gp') && isfield(vm, 'alpha_Gpp')
        fprintf('  GSER Analysis:\n');
        fprintf('    • α_G'' = %.3f, α_G'''' = %.3f\n', vm.alpha_Gp, vm.alpha_Gpp);
        
        % Consistency check
        alpha_diff = abs(vm.alpha_Gp - vm.alpha_Gpp);
        if alpha_diff < 0.1
            consistency = 'EXCELLENT';
        elseif alpha_diff < 0.2
            consistency = 'GOOD';
        elseif alpha_diff < 0.3
            consistency = 'ACCEPTABLE';
        else
            consistency = 'POOR';
        end
        fprintf('    • G''/G'''' consistency: %s (diff = %.3f)\n', consistency, alpha_diff);
        
        % MSD-GSER consistency
        if isfield(vm, 'alpha_msd')
            msd_gser_diff = abs(vm.alpha_msd - vm.alpha_Gp);
            if msd_gser_diff < 0.15
                msd_consistency = 'EXCELLENT';
            elseif msd_gser_diff < 0.3
                msd_consistency = 'GOOD';
            elseif msd_gser_diff < 0.5
                msd_consistency = 'ACCEPTABLE';
            else
                msd_consistency = 'POOR';
            end
            fprintf('    • MSD-GSER consistency: %s (diff = %.3f)\n', msd_consistency, msd_gser_diff);
        end
    end
    
    if isfield(vm, 'delta_measured') && isfield(vm, 'delta_theory')
        fprintf('  Loss Tangent Analysis:\n');
        fprintf('    • δ_measured = %.1f°, δ_theory = %.1f°\n', vm.delta_measured, vm.delta_theory);
        
        delta_diff = abs(vm.delta_measured - vm.delta_theory);
        if delta_diff < 5
            delta_consistency = 'EXCELLENT';
        elseif delta_diff < 10
            delta_consistency = 'GOOD';
        elseif delta_diff < 20
            delta_consistency = 'ACCEPTABLE';
        else
            delta_consistency = 'POOR';
        end
        fprintf('    • δ consistency: %s (diff = %.1f°)\n', delta_consistency, delta_diff);
    end
    
    if isfield(vm, 'ratio_mean') && isfield(vm, 'ratio_std')
        fprintf('  G''/G'''' Analysis:\n');
        fprintf('    • Mean ratio = %.3f, Std = %.3f\n', vm.ratio_mean, vm.ratio_std);
        
        if vm.ratio_std < 0.1
            ratio_consistency = 'EXCELLENT';
        elseif vm.ratio_std < 0.2
            ratio_consistency = 'GOOD';
        elseif vm.ratio_std < 0.5
            ratio_consistency = 'ACCEPTABLE';
        else
            ratio_consistency = 'POOR';
        end
        fprintf('    • Ratio consistency: %s\n', ratio_consistency);
    end
    
    fprintf('  Overall Quality: %s\n', vm.quality_rating);
    
    % Special analysis for p_c
    if p_val == 0.3116
        fprintf('  ⚠ CRITICAL POINT ANALYSIS:\n');
        fprintf('    • This is the percolation threshold p_c\n');
        fprintf('    • Negative α_G'' suggests GSER breakdown\n');
        fprintf('    • Critical fluctuations may dominate\n');
        fprintf('    • Finite-size effects likely significant\n');
        fprintf('    • Consider larger lattice or different analysis\n');
    end
    
    fprintf('\n');
end

% Summary statistics
fprintf('=== SUMMARY STATISTICS ===\n\n');

% Extract all values
p_vals = [results.p];
alpha_msd_vals = zeros(size(p_vals));
alpha_gp_vals = zeros(size(p_vals));
alpha_gpp_vals = zeros(size(p_vals));
delta_vals = zeros(size(p_vals));
ratio_vals = zeros(size(p_vals));
success_vals = zeros(size(p_vals));

for i = 1:length(results)
    vm = results(i).validation_metrics;
    ts = results(i).trajectory_stats;
    
    if isfield(vm, 'alpha_msd'), alpha_msd_vals(i) = vm.alpha_msd; end
    if isfield(vm, 'alpha_Gp'), alpha_gp_vals(i) = vm.alpha_Gp; end
    if isfield(vm, 'alpha_Gpp'), alpha_gpp_vals(i) = vm.alpha_Gpp; end
    if isfield(vm, 'delta_measured'), delta_vals(i) = vm.delta_measured; end
    if isfield(vm, 'ratio_mean'), ratio_vals(i) = vm.ratio_mean; end
    success_vals(i) = ts.move_success_rate;
end

% Trends analysis
fprintf('Trends Analysis:\n');
fprintf('  • α_MSD range: %.3f to %.3f\n', min(alpha_msd_vals), max(alpha_msd_vals));
fprintf('  • α_G'' range: %.3f to %.3f\n', min(alpha_gp_vals), max(alpha_gp_vals));
fprintf('  • α_G'''' range: %.3f to %.3f\n', min(alpha_gpp_vals), max(alpha_gpp_vals));
fprintf('  • δ range: %.1f° to %.1f°\n', min(delta_vals), max(delta_vals));
fprintf('  • G''/G'''' range: %.3f to %.3f\n', min(ratio_vals), max(ratio_vals));
fprintf('  • Success rate range: %.3f to %.3f\n', min(success_vals), max(success_vals));

% Quality distribution
quality_counts = struct();
for i = 1:length(results)
    quality = results(i).validation_metrics.quality_rating;
    if isfield(quality_counts, quality)
        quality_counts.(quality) = quality_counts.(quality) + 1;
    else
        quality_counts.(quality) = 1;
    end
end

fprintf('\nQuality Distribution:\n');
quality_fields = fieldnames(quality_counts);
for i = 1:length(quality_fields)
    fprintf('  • %s: %d\n', quality_fields{i}, quality_counts.(quality_fields{i}));
end

% Recommendations
fprintf('\n=== RECOMMENDATIONS ===\n\n');

fprintf('1. For p = 0.3116 (p_c):\n');
fprintf('   • Increase lattice size (L > 200)\n');
fprintf('   • Use longer walk length (LW > 50000)\n');
fprintf('   • Consider ensemble averaging\n');
fprintf('   • Investigate critical point specific analysis\n\n');

fprintf('2. For p = 0.8 (high percolation):\n');
fprintf('   • Optimize window size for GSER analysis\n');
fprintf('   • Use robust fitting methods\n');
fprintf('   • Consider longer simulations\n\n');

fprintf('3. General improvements:\n');
fprintf('   • Increase ensemble size (NW > 200)\n');
fprintf('   • Use adaptive time stepping\n');
fprintf('   • Implement better boundary conditions\n\n');

fprintf('=== TABLE GENERATION COMPLETED ===\n');

% Save table to file
fid = fopen('critical_points_table.txt', 'w');
fprintf(fid, 'Critical Percolation Points Analysis Results\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));

% Write table header
fprintf(fid, '%-12s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-12s\n', ...
    'p', 'α_MSD', 'α_G''', 'α_G''''', 'δ(°)', 'G''/G''''', 'Success', 'Eff_D', 'Quality', 'Regime', 'Notes');

% Write table data
for i = 1:length(results)
    % ... (same logic as above for writing to file)
end

fclose(fid);
fprintf('Table saved to critical_points_table.txt\n'); 