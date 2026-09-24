function advanced_anomalous_diffusion_analysis()
    % Advanced Anomalous Diffusion Analysis
    % Two-Segment Piece-wise Fitting Framework
    % Locates anomalous diffusion regions and critical transition times (τ_cr)
    
    fprintf('=== ADVANCED ANOMALOUS DIFFUSION ANALYSIS ===\n');
    fprintf('Two-Segment Piece-wise Fitting Framework\n\n');
    
    % Load MSD data
    data_file = 'p_output_NEW34.csv';
    if ~exist(data_file, 'file')
        fprintf('Error: Data file %s not found\n', data_file);
        return;
    end
    
    fprintf('Loading MSD data from %s...\n', data_file);
    data = readtable(data_file);
    
    % Extract p-values from column names
    p_values = [];
    for i = 2:width(data)  % Skip first column (time)
        col_name = data.Properties.VariableNames{i};
        if startsWith(col_name, 'MSD_')
            p_str = extractAfter(col_name, 'MSD_');
            % Convert underscores back to dots for proper decimal parsing
            p_str = strrep(p_str, '_', '.');
            p_val = str2double(p_str);
            if ~isnan(p_val)
                p_values = [p_values, p_val];
            end
        end
    end
    
    % Sort p-values
    [sorted_p, sort_idx] = sort(p_values);
    fprintf('Found %d p-values: %.4f to %.4f\n', length(sorted_p), min(sorted_p), max(sorted_p));
    
    % Initialize results structure
    results = struct();
    results.p = [];
    results.tau_cr = [];
    results.alpha_1 = [];
    results.alpha_2 = [];
    results.r2_1 = [];
    results.r2_2 = [];
    results.rms_error_1 = [];
    results.rms_error_2 = [];
    results.combined_rms = [];
    results.f_test_p = [];
    results.region_type = {};
    results.region2_size = [];      % Number of data points in Region 2
    results.region2_time_range = []; % Time range of Region 2 (t_max - t_min)
    results.region2_quality = [];   % R² value for Region 2 fit
    
    % Critical points
    p_c = 0.3116;
    p_c_prime = 0.6884;
    
    % Analysis parameters
    tolerance = 1e-6;
    max_iterations = 50;
    
    fprintf('\n=== ANALYZING EACH P-VALUE ===\n');
    
    for i = 1:length(sorted_p)
        p = sorted_p(i);
        fprintf('\nAnalyzing p = %.4f (%d/%d)...\n', p, i, length(sorted_p));
        
        % Get MSD data for this p-value
        % Convert p-value to underscore format for column lookup
        p_str = strrep(sprintf('%.4f', p), '.', '_');
        msd_col = sprintf('MSD_%s', p_str);
        if ~ismember(msd_col, data.Properties.VariableNames)
            fprintf('  Warning: Column %s not found, skipping\n', msd_col);
            continue;
        end
        
        msd = data.(msd_col);
        t = (1:height(data))';  % Start from t* = 1 to avoid infinite frequencies
        
        % Filter valid data
        valid_mask = isfinite(msd) & (msd > 0) & (t > 0);
        t_valid = t(valid_mask);
        msd_valid = msd(valid_mask);
        
        if length(t_valid) < 20
            fprintf('  Insufficient data points (%d), skipping\n', length(t_valid));
            continue;
        end
        
        % Determine region type
        if p < p_c_prime - 0.05
            region_type = 'LIQUID';
        elseif abs(p - p_c_prime) <= 0.05
            region_type = 'CRITICAL';
        else
            region_type = 'SOLID';
        end
        
        fprintf('  Region: %s\n', region_type);
        
        % Perform two-segment piece-wise fitting
        [tau_cr, alpha_1, alpha_2, r2_1, r2_2, rms_1, rms_2, combined_rms, f_test_p, region2_size, region2_time_range] = ...
            fit_two_segment_piecewise(t_valid, msd_valid, tolerance, max_iterations);
        
        % Store results
        results.p = [results.p, p];
        results.tau_cr = [results.tau_cr, tau_cr];
        results.alpha_1 = [results.alpha_1, alpha_1];
        results.alpha_2 = [results.alpha_2, alpha_2];
        results.r2_1 = [results.r2_1, r2_1];
        results.r2_2 = [results.r2_2, r2_2];
        results.rms_error_1 = [results.rms_error_1, rms_1];
        results.rms_error_2 = [results.rms_error_2, rms_2];
        results.combined_rms = [results.combined_rms, combined_rms];
        results.f_test_p = [results.f_test_p, f_test_p];
        results.region_type{end+1} = region_type;
        results.region2_size = [results.region2_size, region2_size];
        results.region2_time_range = [results.region2_time_range, region2_time_range];
        results.region2_quality = [results.region2_quality, r2_2];
        
        fprintf('  τ_cr: %.2e\n', tau_cr);
        fprintf('  α₁: %.3f (R² = %.3f)\n', alpha_1, r2_1);
        fprintf('  α₂: %.3f (R² = %.3f)\n', alpha_2, r2_2);
        fprintf('  Region 2: %d points, time range %.2e, quality %.3f\n', region2_size, region2_time_range, r2_2);
        fprintf('  Combined RMS: %.2e\n', combined_rms);
        fprintf('  F-test p-value: %.3f\n', f_test_p);
        
        % Create detailed visualization for key p-values
        if ismember(p, [p_c, p_c_prime, 0.8]) || mod(i, 5) == 1
            create_piecewise_visualization(t_valid, msd_valid, tau_cr, alpha_1, alpha_2, p, region_type);
        end
    end
    
    % Create summary plots
    create_summary_plots(results);
    
    % Save results
    save_advanced_results(results);
    
    fprintf('\n=== ANALYSIS COMPLETE ===\n');
    fprintf('Results saved to: advanced_anomalous_diffusion_results.mat\n');
    fprintf('Summary plots saved to: advanced_analysis_summary.png\n');
end

function [tau_cr, alpha_1, alpha_2, r2_1, r2_2, rms_1, rms_2, combined_rms, f_test_p, region2_size, region2_time_range] = ...
    fit_two_segment_piecewise(t, msd, tolerance, max_iterations)
    % Fit two-segment piece-wise curve to MSD data using forward-looking optimization
    
    % Convert to log space
    log_t = log10(t);
    log_msd = log10(msd);
    
    % Initialize variables
    best_tau_cr = t(round(end/2));  % Start with middle point
    best_combined_rms = inf;
    best_alpha_1 = 0;
    best_alpha_2 = 0;
    best_r2_1 = 0;
    best_r2_2 = 0;
    best_rms_1 = 0;
    best_rms_2 = 0;
    
    fprintf('    Forward-looking optimization: finding optimal Region 2 size\n');
    
    % Try different Region 2 sizes (from small to large)
    min_region2_points = 50;  % Minimum points for reliable fit
    max_region2_points = length(t) - 100;  % Leave some points for Region 1
    
    % Test different Region 2 sizes
    region2_sizes = round(linspace(min_region2_points, max_region2_points, 50));
    
    for i = 1:length(region2_sizes)
        region2_size = region2_sizes(i);
        tau_cr_candidate = t(end - region2_size + 1);
        
        % Define regions
        mask_1 = t < tau_cr_candidate;
        mask_2 = t >= tau_cr_candidate;
        
        if sum(mask_1) < 20 || sum(mask_2) < 20
            continue;  % Skip if either region too small
        end
        
        % Fit segment 1 (power law or polynomial)
        t_1 = t(mask_1);
        msd_1 = msd(mask_1);
        log_t_1 = log10(t_1);
        log_msd_1 = log10(msd_1);
        
        % Try power law fit first
        p_1_power = polyfit(log_t_1, log_msd_1, 1);
        alpha_1_power = p_1_power(1);
        b_1_power = p_1_power(2);
        msd_pred_1_power = alpha_1_power * log_t_1 + b_1_power;
        ss_res_1_power = sum((log_msd_1 - msd_pred_1_power).^2);
        ss_tot_1_power = sum((log_msd_1 - mean(log_msd_1)).^2);
        r2_1_power = 1 - (ss_res_1_power / ss_tot_1_power);
        rms_1_power = sqrt(mean((log_msd_1 - msd_pred_1_power).^2));
        
        % Try 3rd order polynomial fit
        p_1_poly = polyfit(log_t_1, log_msd_1, 3);
        msd_pred_1_poly = polyval(p_1_poly, log_t_1);
        ss_res_1_poly = sum((log_msd_1 - msd_pred_1_poly).^2);
        ss_tot_1_poly = sum((log_msd_1 - mean(log_msd_1)).^2);
        r2_1_poly = 1 - (ss_res_1_poly / ss_tot_1_poly);
        rms_1_poly = sqrt(mean((log_msd_1 - msd_pred_1_poly).^2));
        
        % Choose better fit for Region 1
        if r2_1_power > r2_1_poly
            alpha_1 = alpha_1_power;
            r2_1 = r2_1_power;
            rms_1 = rms_1_power;
            fit_type_1 = 'power_law';
        else
            alpha_1 = NaN;  % Not applicable for polynomial
            r2_1 = r2_1_poly;
            rms_1 = rms_1_poly;
            fit_type_1 = 'polynomial';
        end
        
        % Fit segment 2 (power law only - anomalous diffusion region)
        t_2 = t(mask_2);
        msd_2 = msd(mask_2);
        log_t_2 = log10(t_2);
        log_msd_2 = log10(msd_2);
        
        % Power law fit only for Region 2 (anomalous diffusion region)
        p_2 = polyfit(log_t_2, log_msd_2, 1);
        alpha_2 = p_2(1);
        b_2 = p_2(2);
        msd_pred_2 = alpha_2 * log_t_2 + b_2;
        ss_res_2 = sum((log_msd_2 - msd_pred_2).^2);
        ss_tot_2 = sum((log_msd_2 - mean(log_msd_2)).^2);
        r2_2 = 1 - (ss_res_2 / ss_tot_2);
        rms_2 = sqrt(mean((log_msd_2 - msd_pred_2).^2));
        
        % Combined RMS error
        combined_rms = sqrt((rms_1^2 + rms_2^2) / 2);
        
        % Check if this is the best solution so far
        if combined_rms < best_combined_rms
            best_combined_rms = combined_rms;
            best_tau_cr = tau_cr_candidate;
            best_alpha_1 = alpha_1;
            best_alpha_2 = alpha_2;
            best_r2_1 = r2_1;
            best_r2_2 = r2_2;
            best_rms_1 = rms_1;
            best_rms_2 = rms_2;
        end
        
        % Early stopping: if Region 2 quality is degrading significantly
        if i > 10 && r2_2 < 0.5 && combined_rms > best_combined_rms * 1.2
            fprintf('    Early stopping: Region 2 quality degrading (R² = %.3f)\n', r2_2);
            break;
        end
    end
    
    % Return best solution
    tau_cr = best_tau_cr;
    alpha_1 = best_alpha_1;
    alpha_2 = best_alpha_2;
    r2_1 = best_r2_1;
    r2_2 = best_r2_2;
    rms_1 = best_rms_1;
    rms_2 = best_rms_2;
    combined_rms = best_combined_rms;
    f_test_p = 1.0;  % No model comparison needed
    
    fprintf('    Final: τ_cr = %.2e, RMS = %.2e, Region 2 size = %d points\n', ...
        tau_cr, combined_rms, sum(t >= tau_cr));
    
    % Calculate Region 2 metrics for the best solution
    mask_2 = t >= tau_cr;
    region2_size = sum(mask_2);
    if region2_size > 0
        t_2 = t(mask_2);
        region2_time_range = t_2(end) - t_2(1);
    else
        region2_time_range = 0;
    end
end

function create_piecewise_visualization(t, msd, tau_cr, alpha_1, alpha_2, p, region_type)
    % Create detailed visualization of piece-wise fit
    
    figure('Position', [100, 100, 1200, 800]);
    
    % Main plot: MSD vs time
    subplot(2, 2, 1);
    loglog(t, msd, 'b-', 'LineWidth', 1.5);
    hold on;
    
    % Mark τ_cr
    ylims = ylim;
    plot([tau_cr, tau_cr], ylims, 'r--', 'LineWidth', 2);
    
    % Fit segments
    mask_1 = t <= tau_cr;
    mask_2 = t > tau_cr;
    
    if sum(mask_1) > 0
        t_1 = t(mask_1);
        msd_1 = msd(mask_1);
        log_t_1 = log10(t_1);
        log_msd_1 = log10(msd_1);
        p_1 = polyfit(log_t_1, log_msd_1, 1);
        msd_fit_1 = 10.^(p_1(1) * log10(t_1) + p_1(2));
        plot(t_1, msd_fit_1, 'g-', 'LineWidth', 2);
    end
    
    if sum(mask_2) > 0
        t_2 = t(mask_2);
        msd_2 = msd(mask_2);
        log_t_2 = log10(t_2);
        log_msd_2 = log10(msd_2);
        
        % Power law fit only for Region 2 (anomalous diffusion region)
        p_2 = polyfit(log_t_2, log_msd_2, 1);
        msd_fit_2 = 10.^(p_2(1) * log10(t_2) + p_2(2));
        fit_type = 'Power Law';
        
        plot(t_2, msd_fit_2, 'm-', 'LineWidth', 2);
    end
    
    xlabel('Time t');
    ylabel('MSD');
    title(sprintf('Piece-wise Fit: p = %.4f (%s)', p, region_type));
    legend('Data', 'τ_{cr}', 'Segment 1', 'Segment 2', 'Location', 'best');
    grid on;
    
    % Residuals plot
    subplot(2, 2, 2);
    residuals = [];
    t_res = [];
    
    if sum(mask_1) > 0
        residuals = [residuals; log_msd_1 - (p_1(1) * log_t_1 + p_1(2))];
        t_res = [t_res; log_t_1];
    end
    
    if sum(mask_2) > 0
        residuals = [residuals; log_msd_2 - (p_2(1) * log_t_2 + p_2(2))];
        t_res = [t_res; log_t_2];
    end
    
    plot(t_res, residuals, 'ko', 'MarkerSize', 4);
    hold on;
    plot([log10(tau_cr), log10(tau_cr)], ylim, 'r--', 'LineWidth', 2);
    xlabel('log_{10}(t)');
    ylabel('Residuals');
    title('Fit Residuals');
    grid on;
    
    % α values vs p
    subplot(2, 2, 3);
    plot(p, alpha_1, 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
    hold on;
    plot(p, alpha_2, 'mo', 'MarkerSize', 8, 'MarkerFaceColor', 'm');
    xlabel('p');
    ylabel('α');
    title('Power Law Exponents');
    legend('α₁', 'α₂', 'Location', 'best');
    grid on;
    
    % τ_cr vs p
    subplot(2, 2, 4);
    plot(p, tau_cr, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    xlabel('p');
    ylabel('τ_{cr}');
    title('Critical Transition Time');
    set(gca, 'YScale', 'log');
    grid on;
    
    % Save figure
    filename = sprintf('advanced_analysis_p%.4f.png', p);
    saveas(gcf, filename);
    fprintf('    Saved: %s\n', filename);
end

function create_summary_plots(results)
    % Create summary plots of all results
    
    figure('Position', [100, 100, 1600, 1200]);
    
    % τ_cr vs p
    subplot(3, 3, 1);
    plot(results.p, results.tau_cr, 'ro-', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('p');
    ylabel('τ_{cr}');
    title('Critical Transition Time vs p');
    set(gca, 'YScale', 'log');
    grid on;
    
    % α₁ vs p
    subplot(3, 3, 2);
    plot(results.p, results.alpha_1, 'go-', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('p');
    ylabel('α₁');
    title('Segment 1 Exponent vs p');
    grid on;
    
    % α₂ vs p
    subplot(3, 3, 3);
    plot(results.p, results.alpha_2, 'mo-', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('p');
    ylabel('α₂');
    title('Segment 2 Exponent vs p');
    grid on;
    
    % Region 2 size vs p
    subplot(3, 3, 4);
    plot(results.p, results.region2_size, 'bo-', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('p');
    ylabel('Region 2 Size (points)');
    title('Region 2 Size vs p');
    grid on;
    
    % Region 2 time range vs p
    subplot(3, 3, 5);
    plot(results.p, results.region2_time_range, 'co-', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('p');
    ylabel('Region 2 Time Range');
    title('Region 2 Time Range vs p');
    set(gca, 'YScale', 'log');
    grid on;
    
    % Region 2 quality vs p
    subplot(3, 3, 6);
    plot(results.p, results.region2_quality, 'ko-', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('p');
    ylabel('Region 2 Quality (R²)');
    title('Region 2 Fit Quality vs p');
    grid on;
    
    % Combined RMS vs p
    subplot(3, 3, 7);
    plot(results.p, results.combined_rms, 'bo-', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('p');
    ylabel('Combined RMS Error');
    title('Fit Quality vs p');
    set(gca, 'YScale', 'log');
    grid on;
    
    % R² values vs p
    subplot(3, 3, 8);
    plot(results.p, results.r2_1, 'go-', 'LineWidth', 2, 'MarkerSize', 6);
    hold on;
    plot(results.p, results.r2_2, 'mo-', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('p');
    ylabel('R²');
    title('R² Values vs p');
    legend('R²₁', 'R²₂', 'Location', 'best');
    grid on;
    
    % F-test p-values vs p
    subplot(3, 3, 9);
    plot(results.p, results.f_test_p, 'ko-', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('p');
    ylabel('F-test p-value');
    title('Statistical Significance vs p');
    grid on;
    
    % Add critical point annotations
    p_c = 0.3116;
    p_c_prime = 0.6884;
    
    for i = 1:9
        subplot(3, 3, i);
        hold on;
        ylims = ylim;
        plot([p_c, p_c], ylims, 'k--', 'LineWidth', 1);
        plot([p_c_prime, p_c_prime], ylims, 'k--', 'LineWidth', 1);
        text(p_c, ylims(2)*0.9, 'p_c', 'HorizontalAlignment', 'center');
        text(p_c_prime, ylims(2)*0.9, 'p_c''', 'HorizontalAlignment', 'center');
    end
    
    % Save summary plot
    saveas(gcf, 'advanced_analysis_summary.png');
    fprintf('Saved summary plot: advanced_analysis_summary.png\n');
end

function save_advanced_results(results)
    % Save results to MAT file
    
    % Create results table
    results_table = table(results.p', results.tau_cr', results.alpha_1', results.alpha_2', ...
        results.r2_1', results.r2_2', results.combined_rms', results.f_test_p', ...
        results.region_type', results.region2_size', results.region2_time_range', results.region2_quality', ...
        'VariableNames', {'p', 'tau_cr', 'alpha_1', 'alpha_2', 'r2_1', 'r2_2', ...
        'combined_rms', 'f_test_p', 'region_type', 'region2_size', 'region2_time_range', 'region2_quality'});
    
    % Save to MAT file
    save('advanced_anomalous_diffusion_results.mat', 'results', 'results_table');
    
    % Also save as CSV
    writetable(results_table, 'advanced_anomalous_diffusion_results.csv');
    
    fprintf('Results saved to:\n');
    fprintf('  advanced_anomalous_diffusion_results.mat\n');
    fprintf('  advanced_anomalous_diffusion_results.csv\n');
    
    % Print summary statistics
    fprintf('\n=== SUMMARY STATISTICS ===\n');
    fprintf('Total p-values analyzed: %d\n', length(results.p));
    fprintf('Mean τ_cr: %.2e\n', mean(results.tau_cr));
    fprintf('Mean α₁: %.3f\n', mean(results.alpha_1));
    fprintf('Mean α₂: %.3f\n', mean(results.alpha_2));
    fprintf('Mean combined RMS: %.2e\n', mean(results.combined_rms));
    fprintf('Mean R²₁: %.3f\n', mean(results.r2_1));
    fprintf('Mean R²₂: %.3f\n', mean(results.r2_2));
    fprintf('Mean Region 2 size: %.1f points\n', mean(results.region2_size));
    fprintf('Mean Region 2 time range: %.2e\n', mean(results.region2_time_range));
    fprintf('Mean Region 2 quality: %.3f\n', mean(results.region2_quality));
end 