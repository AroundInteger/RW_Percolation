function test_real_data_changepoints()
% Test changepoint detection on real data from ensemble simulations

fprintf('=== Testing Changepoint Detection on Real Data ===\n');

% Parameters
p_values = [0.6884, 0.7500];  % Real data we found
p_c_prime = 0.6884;
output_dir = './real_data_changepoint_results';

% Create output directory
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Initialize results storage
all_results = struct();

% Test each p value
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('\n--- Testing p = %.4f ---\n', p);
    
    % Determine regime
    if p < p_c_prime - 0.05
        regime = 'LIQUID';
        expected_alpha = 1.0;
        expected_delta = 90.0;
    elseif abs(p - p_c_prime) < 0.05
        regime = 'CRITICAL';
        expected_alpha = 0.5;
        expected_delta = 45.0;
    else
        regime = 'SOLID';
        expected_alpha = 0.0;
        expected_delta = 0.0;
    end
    
    fprintf('Regime: %s, Expected α: %.1f, Expected δ: %.1f°\n', regime, expected_alpha, expected_delta);
    
    % Load real data
    data_loaded = false;
    for seed = 1:2
        data_path = sprintf('../ensemble_simulations/seed_%02d/p_%.4f/msd_results_L500_p%.4f.csv', seed, p, p);
        if exist(data_path, 'file')
            fprintf('Loading data from: %s\n', data_path);
            data = readtable(data_path);
            t = data.tau;
            msd = data.msd;
            data_loaded = true;
            break;
        end
    end
    
    if ~data_loaded
        fprintf('No data found for p = %.4f, skipping\n', p);
        continue;
    end
    
    fprintf('Data loaded: %d points, t range: [%.2e, %.2e], MSD range: [%.2e, %.2e]\n', ...
        length(t), min(t), max(t), min(msd), max(msd));
    
    % Subsample data if too large for efficient processing
    if length(t) > 10000
        fprintf('Subsampling data from %d to 10000 points for efficiency\n', length(t));
        indices = round(linspace(1, length(t), 10000));
        t = t(indices);
        msd = msd(indices);
    end
    
    % Run standalone changepoint comparison
    try
        fprintf('\n--- Running Standalone Changepoint Comparison ---\n');
        [results, comparison] = standalone_changepoint_comparison_real_data(t, msd, p, p_c_prime, regime);
        
        % Store results
        all_results.(sprintf('p_%.4f', p)) = struct();
        all_results.(sprintf('p_%.4f', p)).results = results;
        all_results.(sprintf('p_%.4f', p)).comparison = comparison;
        all_results.(sprintf('p_%.4f', p)).regime = regime;
        all_results.(sprintf('p_%.4f', p)).expected_alpha = expected_alpha;
        all_results.(sprintf('p_%.4f', p)).expected_delta = expected_delta;
        all_results.(sprintf('p_%.4f', p)).data_info = struct('n_points', length(t), 't_range', [min(t), max(t)], 'msd_range', [min(msd), max(msd)]);
        
        % Save individual results
        save(fullfile(output_dir, sprintf('changepoint_results_p%.4f.mat', p)), ...
            'results', 'comparison', 't', 'msd', 'p', 'p_c_prime', 'regime', 'expected_alpha', 'expected_delta');
        
    catch ME
        fprintf('Error processing p = %.4f: %s\n', p, ME.message);
        continue;
    end
end

% Generate comparison report
generate_real_data_comparison_report(all_results, p_values, p_c_prime, output_dir);

fprintf('\n=== Test Complete ===\n');
fprintf('Results saved to: %s\n', output_dir);

end

function [results, comparison] = standalone_changepoint_comparison_real_data(t, msd, p, p_c_prime, regime)
% Standalone changepoint comparison for real data

fprintf('=== Standalone Changepoint Comparison for Real Data ===\n');
fprintf('p = %.4f, regime = %s\n', p, regime);

% Test all methods
results = struct();

% Method 1: Current Moving Window α Method
fprintf('\n--- Method 1: Moving Window α Detection ---\n');
[results.method1.tau_cr, results.method1.quality] = method1_moving_window_alpha(t, msd);
fprintf('Method 1: τ_cr = %.2e, quality = %s\n', results.method1.tau_cr, results.method1.quality);

% Method 2: Paper's Second Derivative Method
fprintf('\n--- Method 2: Second Derivative Detection ---\n');
[results.method2.tau_cr, results.method2.quality] = method2_second_derivative(t, msd);
fprintf('Method 2: τ_cr = %.2e, quality = %s\n', results.method2.tau_cr, results.method2.quality);

% Method 3: Hybrid Approach
fprintf('\n--- Method 3: Hybrid Detection ---\n');
[results.method3.tau_cr, results.method3.quality] = method3_hybrid(t, msd, results.method1, results.method2);
fprintf('Method 3: τ_cr = %.2e, quality = %s\n', results.method3.tau_cr, results.method3.quality);

% Method 4: Theoretical Prediction-Based Method
fprintf('\n--- Method 4: Theoretical Prediction Method ---\n');
[results.method4.tau_cr, results.method4.quality] = method4_theoretical(t, msd, p, p_c_prime);
fprintf('Method 4: τ_cr = %.2e, quality = %s\n', results.method4.tau_cr, results.method4.quality);

% Method 5: Paper's Bisection Piecewise Fitting
fprintf('\n--- Method 5: Bisection Piecewise Fitting ---\n');
[results.method5.tau_cr, results.method5.quality] = method5_bisection(t, msd, p, p_c_prime);
fprintf('Method 5: τ_cr = %.2e, quality = %s\n', results.method5.tau_cr, results.method5.quality);

% Compare results
fprintf('\n--- Method Comparison ---\n');
methods = fieldnames(results);
tau_values = zeros(length(methods), 1);
qualities = cell(length(methods), 1);

for i = 1:length(methods)
    method_name = methods{i};
    tau_values(i) = results.(method_name).tau_cr;
    qualities{i} = results.(method_name).quality;
    fprintf('  %s: τ_cr = %.2e, quality = %s\n', method_name, tau_values(i), qualities{i});
end

% Calculate agreement
valid_taus = tau_values(~isnan(tau_values));
if length(valid_taus) > 1
    mean_tau = mean(valid_taus);
    std_tau = std(valid_taus);
    cv_tau = std_tau / mean_tau;
    fprintf('\nAgreement Metrics:\n');
    fprintf('  Mean τ_cr: %.2e\n', mean_tau);
    fprintf('  Std τ_cr: %.2e\n', std_tau);
    fprintf('  Coefficient of Variation: %.3f (lower is better)\n', cv_tau);
    
    comparison.mean_tau = mean_tau;
    comparison.std_tau = std_tau;
    comparison.cv_tau = cv_tau;
    comparison.agreement_score = cv_tau;
else
    comparison.mean_tau = NaN;
    comparison.std_tau = NaN;
    comparison.cv_tau = NaN;
    comparison.agreement_score = NaN;
end

% Quality distribution
quality_counts = containers.Map({'EXCELLENT', 'GOOD', 'MARGINAL', 'POOR'}, [0, 0, 0, 0]);
for i = 1:length(methods)
    quality = qualities{i};
    if isKey(quality_counts, quality)
        quality_counts(quality) = quality_counts(quality) + 1;
    end
end

fprintf('\nQuality Distribution:\n');
quality_names = keys(quality_counts);
for i = 1:length(quality_names)
    fprintf('  %s: %d\n', quality_names{i}, quality_counts(quality_names{i}));
end

comparison.quality_distribution = quality_counts;

% Best method selection
quality_scores = containers.Map({'EXCELLENT', 'GOOD', 'MARGINAL', 'POOR'}, [4, 3, 2, 1]);
method_scores = zeros(length(methods), 1);

for i = 1:length(methods)
    quality = qualities{i};
    if isKey(quality_scores, quality)
        method_scores(i) = quality_scores(quality);
    end
end

[~, best_idx] = max(method_scores);
comparison.best_method = methods{best_idx};
comparison.best_tau = tau_values(best_idx);

fprintf('\nBest Method: %s (τ_cr = %.2e)\n', comparison.best_method, comparison.best_tau);

fprintf('\n=== Comparison Complete ===\n');

end

function generate_real_data_comparison_report(all_results, p_values, p_c_prime, output_dir)
% Generate comparison report for real data

fprintf('\n--- Generating Real Data Comparison Report ---\n');

% Initialize summary arrays
n_p = length(p_values);
method_names = {'method1', 'method2', 'method3', 'method4', 'method5'};
n_methods = length(method_names);

tau_matrix = zeros(n_p, n_methods);
quality_matrix = cell(n_p, n_methods);
regime_info = cell(n_p, 1);
agreement_scores = zeros(n_p, 1);

% Extract results
for p_idx = 1:n_p
    p = p_values(p_idx);
    p_key = sprintf('p_%.4f', p);
    
    if isfield(all_results, p_key)
        results = all_results.(p_key);
        
        % Store regime info
        regime_info{p_idx} = results.regime;
        
        % Extract tau values and qualities
        for m_idx = 1:n_methods
            method_name = method_names{m_idx};
            if isfield(results.results, method_name)
                tau_matrix(p_idx, m_idx) = results.results.(method_name).tau_cr;
                quality_matrix{p_idx, m_idx} = results.results.(method_name).quality;
            else
                tau_matrix(p_idx, m_idx) = NaN;
                quality_matrix{p_idx, m_idx} = 'N/A';
            end
        end
        
        % Store agreement score
        if isfield(results.comparison, 'agreement_score')
            agreement_scores(p_idx) = results.comparison.agreement_score;
        else
            agreement_scores(p_idx) = NaN;
        end
    end
end

% Create comparison plot
figure('Position', [100, 100, 1200, 800]);

% Plot 1: Tau values comparison
subplot(2, 3, 1);
colors = {'b', 'r', 'g', 'm', 'c'};
for m_idx = 1:n_methods
    valid_idx = ~isnan(tau_matrix(:, m_idx));
    if any(valid_idx)
        semilogy(p_values(valid_idx), tau_matrix(valid_idx, m_idx), 'o-', ...
            'Color', colors{mod(m_idx-1, length(colors))+1}, 'LineWidth', 2, 'MarkerSize', 8);
        hold on;
    end
end
xlabel('p');
ylabel('τ_{cr}');
title('Changepoint Detection on Real Data');
legend(method_names, 'Location', 'best');
grid on;

% Plot 2: Quality comparison
subplot(2, 3, 2);
quality_scores = containers.Map({'EXCELLENT', 'GOOD', 'MARGINAL', 'POOR', 'N/A'}, [4, 3, 2, 1, 0]);
quality_numeric = zeros(size(quality_matrix));
for i = 1:size(quality_matrix, 1)
    for j = 1:size(quality_matrix, 2)
        quality = quality_matrix{i, j};
        if isKey(quality_scores, quality)
            quality_numeric(i, j) = quality_scores(quality);
        end
    end
end
imagesc(quality_numeric);
colorbar;
set(gca, 'XTick', 1:n_methods, 'XTickLabel', method_names);
set(gca, 'YTick', 1:n_p, 'YTickLabel', p_values);
xlabel('Method');
ylabel('p');
title('Quality Heatmap');
colormap(flipud(gray));

% Plot 3: Agreement scores
subplot(2, 3, 3);
valid_idx = ~isnan(agreement_scores);
if any(valid_idx)
    plot(p_values(valid_idx), agreement_scores(valid_idx), 'ko-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('p');
    ylabel('Agreement Score (lower is better)');
    title('Method Agreement');
    grid on;
end

% Plot 4: Best method frequency
subplot(2, 3, 4);
best_methods = cell(n_p, 1);
for p_idx = 1:n_p
    p_key = sprintf('p_%.4f', p_values(p_idx));
    if isfield(all_results, p_key)
        best_methods{p_idx} = all_results.(p_key).comparison.best_method;
    else
        best_methods{p_idx} = 'N/A';
    end
end

% Count best methods
method_counts = containers.Map(method_names, zeros(1, n_methods));
for i = 1:length(best_methods)
    method = best_methods{i};
    if isKey(method_counts, method)
        method_counts(method) = method_counts(method) + 1;
    end
end

bar(cell2mat(values(method_counts)));
set(gca, 'XTickLabel', keys(method_counts));
ylabel('Count');
title('Best Method Frequency');
grid on;

% Plot 5: Regime comparison
subplot(2, 3, 5);
regime_performance = containers.Map({'LIQUID', 'CRITICAL', 'SOLID'}, [0, 0, 0]);
for p_idx = 1:n_p
    regime = regime_info{p_idx};
    if isKey(regime_performance, regime)
        regime_performance(regime) = regime_performance(regime) + 1;
    end
end

bar(cell2mat(values(regime_performance)));
set(gca, 'XTickLabel', keys(regime_performance));
ylabel('Count');
title('Regime Distribution');
grid on;

% Plot 6: Overall summary
subplot(2, 3, 6);
% Calculate overall success rate
success_count = 0;
total_count = 0;
for p_idx = 1:n_p
    for m_idx = 1:n_methods
        if ~isnan(tau_matrix(p_idx, m_idx))
            total_count = total_count + 1;
            if strcmp(quality_matrix{p_idx, m_idx}, 'EXCELLENT') || strcmp(quality_matrix{p_idx, m_idx}, 'GOOD')
                success_count = success_count + 1;
            end
        end
    end
end

success_rate = success_count / total_count * 100;
text(0.5, 0.5, sprintf('Overall Success Rate: %.1f%%\n(%d/%d methods)\nReal Data Analysis', success_rate, success_count, total_count), ...
    'HorizontalAlignment', 'center', 'FontSize', 12);
axis off;

sgtitle(sprintf('Real Data Changepoint Detection Analysis (p_c'' = %.4f)', p_c_prime));

% Save plot
saveas(gcf, fullfile(output_dir, 'real_data_changepoint_analysis.png'));
saveas(gcf, fullfile(output_dir, 'real_data_changepoint_analysis.fig'));

% Generate text report
report_file = fullfile(output_dir, 'real_data_comparison_report.txt');
fid = fopen(report_file, 'w');

fprintf(fid, '=== Real Data Changepoint Detection Analysis ===\n\n');
fprintf(fid, 'Analysis Parameters:\n');
fprintf(fid, '  p_c_prime = %.4f\n', p_c_prime);
fprintf(fid, '  p_values = [%.4f, %.4f]\n', p_values);
fprintf(fid, '  Methods tested: %s\n\n', strjoin(method_names, ', '));

fprintf(fid, 'Results Summary:\n');
fprintf(fid, '%-10s %-10s %-15s %-15s %-15s %-15s %-15s\n', 'p', 'Regime', method_names{:});
fprintf(fid, '%-10s %-10s %-15s %-15s %-15s %-15s %-15s\n', '----------', '----------', '---------------', '---------------', '---------------', '---------------', '---------------');

for p_idx = 1:n_p
    p = p_values(p_idx);
    regime = regime_info{p_idx};
    fprintf(fid, '%-10.4f %-10s', p, regime);
    for m_idx = 1:n_methods
        if ~isnan(tau_matrix(p_idx, m_idx))
            fprintf(fid, ' %-14.2e', tau_matrix(p_idx, m_idx));
        else
            fprintf(fid, ' %-14s', 'N/A');
        end
    end
    fprintf(fid, '\n');
end

fprintf(fid, '\nQuality Summary:\n');
fprintf(fid, '%-10s %-10s %-15s %-15s %-15s %-15s %-15s\n', 'p', 'Regime', method_names{:});
fprintf(fid, '%-10s %-10s %-15s %-15s %-15s %-15s %-15s\n', '----------', '----------', '---------------', '---------------', '---------------', '---------------', '---------------');

for p_idx = 1:n_p
    p = p_values(p_idx);
    regime = regime_info{p_idx};
    fprintf(fid, '%-10.4f %-10s', p, regime);
    for m_idx = 1:n_methods
        fprintf(fid, ' %-14s', quality_matrix{p_idx, m_idx});
    end
    fprintf(fid, '\n');
end

fprintf(fid, '\nBest Method Frequency:\n');
for m_idx = 1:n_methods
    method = method_names{m_idx};
    count = method_counts(method);
    fprintf(fid, '  %s: %d times\n', method, count);
end

fprintf(fid, '\nAgreement Scores (lower is better):\n');
for p_idx = 1:n_p
    p = p_values(p_idx);
    if ~isnan(agreement_scores(p_idx))
        fprintf(fid, '  p = %.4f: %.3f\n', p, agreement_scores(p_idx));
    else
        fprintf(fid, '  p = %.4f: N/A\n', p);
    end
end

fprintf(fid, '\nData Information:\n');
for p_idx = 1:n_p
    p = p_values(p_idx);
    p_key = sprintf('p_%.4f', p);
    if isfield(all_results, p_key)
        data_info = all_results.(p_key).data_info;
        fprintf(fid, '  p = %.4f: %d points, t = [%.2e, %.2e], MSD = [%.2e, %.2e]\n', ...
            p, data_info.n_points, data_info.t_range(1), data_info.t_range(2), ...
            data_info.msd_range(1), data_info.msd_range(2));
    end
end

fprintf(fid, '\nConclusions:\n');
fprintf(fid, '1. Real data analysis provides validation of changepoint detection methods\n');
fprintf(fid, '2. Method performance on real data vs synthetic data comparison\n');
fprintf(fid, '3. Regime-specific behavior in real percolation systems\n');
fprintf(fid, '4. Overall success rate: %.1f%%\n\n', success_rate);

fprintf(fid, '=== End Report ===\n');
fclose(fid);

fprintf('Real data comparison report saved to: %s\n', report_file);

end 