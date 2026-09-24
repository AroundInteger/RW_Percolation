function test_existing_data_simple()
% Simple test of changepoint detection on existing ensemble simulation data
% Uses available p values: 0.0000, 0.3116, 0.6884, 0.7500

fprintf('=== Simple Changepoint Detection Test on Existing Data ===\n');

% Parameters
p_c_prime = 0.6884;
p_values = [0.0000, 0.3116, 0.6884, 0.7500];

% Test each available p value
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('\n--- Testing p = %.4f ---\n', p);
    
    % Determine regime and expected values
    if p < p_c_prime - 0.05
        regime = 'LIQUID';
        expected_alpha = 1.0;
    elseif abs(p - p_c_prime) < 0.05
        regime = 'CRITICAL';
        expected_alpha = 0.5;
    else
        regime = 'SOLID';
        expected_alpha = 0.0;
    end
    
    fprintf('Regime: %s, Expected α: %.1f\n', regime, expected_alpha);
    
    % Load data from seed_01
    data_path = sprintf('../ensemble_simulations/seed_01/p_%.4f/msd_results_L500_p%.4f.csv', p, p);
    if exist(data_path, 'file')
        fprintf('Loading data from: %s\n', data_path);
        data = readtable(data_path);
        t = data.tau;
        msd = data.msd;
        
        fprintf('Data loaded: %d points, t range: [%.2e, %.2e], MSD range: [%.2e, %.2e]\n', ...
            length(t), min(t), max(t), min(msd), max(msd));
        
        % Subsample data for efficiency
        if length(t) > 10000
            fprintf('Subsampling data from %d to 10000 points\n', length(t));
            indices = round(linspace(1, length(t), 10000));
            t = t(indices);
            msd = msd(indices);
        end
        
        % Simple local α analysis
        try
            fprintf('Running local α analysis...\n');
            [tau_cr, alpha_optimal, quality] = simple_alpha_analysis(t, msd, expected_alpha);
            
            fprintf('Results:\n');
            fprintf('  Changepoint: τ_cr = %.2e\n', tau_cr);
            fprintf('  Optimal α = %.3f\n', alpha_optimal);
            fprintf('  Quality: %s\n', quality);
            fprintf('  α error: %.3f\n', abs(alpha_optimal - expected_alpha));
            
        catch ME
            fprintf('Error processing p = %.4f: %s\n', p, ME.message);
        end
        
    else
        fprintf('No data found for p = %.4f\n', p);
    end
end

fprintf('\n=== Test Complete ===\n');

end

function [tau_cr, alpha_optimal, quality] = simple_alpha_analysis(t, msd, expected_alpha)
% Simple local α analysis for changepoint detection

log_t = log10(t);
log_msd = log10(msd);

% Calculate local α using moving window
window_size = min(20, length(t)/10);
alpha_local = zeros(size(t));

for i = 1:length(t)
    start_idx = max(1, i - window_size/2);
    end_idx = min(length(t), i + window_size/2);
    
    if end_idx - start_idx >= 5
        t_window = log_t(start_idx:end_idx);
        msd_window = log_msd(start_idx:end_idx);
        
        % Simple linear fit
        coeffs = polyfit(t_window, msd_window, 1);
        alpha_local(i) = coeffs(1);
    else
        alpha_local(i) = NaN;
    end
end

% Find region where α is closest to expected value
alpha_error = abs(alpha_local - expected_alpha);
valid_indices = ~isnan(alpha_error);

if any(valid_indices)
    [~, best_idx] = min(alpha_error(valid_indices));
    valid_t = t(valid_indices);
    tau_cr = valid_t(best_idx);
    alpha_optimal = alpha_local(valid_indices);
    alpha_optimal = alpha_optimal(best_idx);
    
    % Determine quality
    min_error = alpha_error(valid_indices);
    min_error = min_error(best_idx);
    
    if min_error < 0.1
        quality = 'EXCELLENT';
    elseif min_error < 0.2
        quality = 'GOOD';
    elseif min_error < 0.3
        quality = 'MARGINAL';
    else
        quality = 'POOR';
    end
else
    tau_cr = 0;
    alpha_optimal = NaN;
    quality = 'POOR';
end

end 