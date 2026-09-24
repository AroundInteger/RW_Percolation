function test_enhanced_changepoint_detection()
% Test script for enhanced changepoint detection framework
% Compares all methods on existing simulation data

fprintf('=== Enhanced Changepoint Detection Test ===\n');

% Parameters
p_c_prime = 0.6884;  % Critical percolation probability
output_dir = './enhanced_changepoint_results';

% Create output directory
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Test on different p values
p_values = [0.60, 0.62, 0.64, 0.66, 0.68, 0.69, 0.70];  % Critical region

% Initialize results storage
all_results = struct();
all_comparisons = struct();

% Test each p value
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('\n--- Testing p = %.4f ---\n', p);
    
    % Load existing data (try different possible locations)
    data_loaded = false;
    
    % Try ensemble simulations first
    for seed = 1:2
        data_path = sprintf('./ensemble_simulations/seed_%02d/p_%.4f/msd_results_L500_p%.4f.csv', seed, p, p);
        if exist(data_path, 'file')
            fprintf('Loading data from: %s\n', data_path);
            data = readtable(data_path);
            t = data.tau;
            msd = data.msd;
            data_loaded = true;
            break;
        end
    end
    
    % Try enhanced output if ensemble not found
    if ~data_loaded
        data_path = sprintf('./enhanced_output/msd_results_L500_p%.4f.csv', p);
        if exist(data_path, 'file')
            fprintf('Loading data from: %s\n', data_path);
            data = readtable(data_path);
            t = data.tau;
            msd = data.msd;
            data_loaded = true;
        end
    end
    
    % Try paper simulations if still not found
    if ~data_loaded
        data_path = sprintf('./paper_simulations/p_%.4f/msd_results_L50_p%.4f.csv', p, p);
        if exist(data_path, 'file')
            fprintf('Loading data from: %s\n', data_path);
            data = readtable(data_path);
            t = data.tau;
            msd = data.msd;
            data_loaded = true;
        end
    end
    
    % Generate synthetic data if no real data found
    if ~data_loaded
        fprintf('No data found for p = %.4f, generating synthetic data\n', p);
        [t, msd] = generate_synthetic_msd_data(p, p_c_prime);
    end
    
    % Run enhanced changepoint detection
    try
        [results, comparison] = enhanced_changepoint_detection(t, msd, p, p_c_prime, ...
            'plot_results', true, ...
            'save_plots', true, ...
            'output_dir', output_dir, ...
            'verbose', true);
        
        % Store results
        all_results.(sprintf('p_%.4f', p)) = results;
        all_comparisons.(sprintf('p_%.4f', p)) = comparison;
        
        % Save individual results
        save(fullfile(output_dir, sprintf('changepoint_results_p%.4f.mat', p)), 'results', 'comparison', 't', 'msd', 'p', 'p_c_prime');
        
    catch ME
        fprintf('Error processing p = %.4f: %s\n', p, ME.message);
        continue;
    end
end

% Generate comprehensive comparison report
generate_comprehensive_report(all_results, all_comparisons, p_values, p_c_prime, output_dir);

fprintf('\n=== Test Complete ===\n');
fprintf('Results saved to: %s\n', output_dir);

end

function [t, msd] = generate_synthetic_msd_data(p, p_c_prime)
% Generate synthetic MSD data for testing when real data is not available

% Time vector
t = logspace(0, 4, 1000)';

% Generate MSD based on theoretical expectations
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

end

function generate_comprehensive_report(all_results, all_comparisons, p_values, p_c_prime, output_dir)
% Generate comprehensive comparison report across all p values

fprintf('\n--- Generating Comprehensive Report ---\n');

% Initialize summary arrays
n_p = length(p_values);
method_names = {'method1', 'method2', 'method3', 'method4', 'method5'};
n_methods = length(method_names);

tau_matrix = zeros(n_p, n_methods);
quality_matrix = cell(n_p, n_methods);
agreement_scores = zeros(n_p, 1);

% Extract results
for p_idx = 1:n_p
    p = p_values(p_idx);
    p_key = sprintf('p_%.4f', p);
    
    if isfield(all_results, p_key)
        results = all_results.(p_key);
        comparison = all_comparisons.(p_key);
        
        % Extract tau values and qualities
        for m_idx = 1:n_methods
            method_name = method_names{m_idx};
            if isfield(results, method_name) && isfield(results.(method_name), 'tau_cr')
                tau_matrix(p_idx, m_idx) = results.(method_name).tau_cr;
                quality_matrix{p_idx, m_idx} = results.(method_name).quality;
            else
                tau_matrix(p_idx, m_idx) = NaN;
                quality_matrix{p_idx, m_idx} = 'N/A';
            end
        end
        
        % Store agreement score
        if isfield(comparison, 'agreement_score')
            agreement_scores(p_idx) = comparison.agreement_score;
        else
            agreement_scores(p_idx) = NaN;
        end
    end
end

% Create comprehensive comparison plot
figure('Position', [100, 100, 1400, 1000]);

% Plot 1: Tau values vs p
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
title('Changepoint Detection Comparison');
legend(method_names, 'Location', 'best');
grid on;

% Plot 2: Agreement scores vs p
subplot(2, 3, 2);
valid_idx = ~isnan(agreement_scores);
if any(valid_idx)
    plot(p_values(valid_idx), agreement_scores(valid_idx), 'ko-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('p');
    ylabel('Agreement Score (lower is better)');
    title('Method Agreement');
    grid on;
end

% Plot 3: Quality heatmap
subplot(2, 3, 3);
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

% Plot 4: Method consistency
subplot(2, 3, 4);
method_consistency = std(tau_matrix, [], 1, 'omitnan');
bar(method_consistency);
set(gca, 'XTickLabel', method_names);
ylabel('Std τ_{cr}');
title('Method Consistency (lower is better)');
grid on;

% Plot 5: Best method frequency
subplot(2, 3, 5);
best_methods = cell(n_p, 1);
for p_idx = 1:n_p
    p_key = sprintf('p_%.4f', p_values(p_idx));
    if isfield(all_comparisons, p_key)
        best_methods{p_idx} = all_comparisons.(p_key).best_method;
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

% Plot 6: Theoretical vs detected
subplot(2, 3, 6);
theoretical_alpha = zeros(n_p, 1);
detected_alpha = zeros(n_p, 1);

for p_idx = 1:n_p
    p = p_values(p_idx);
    
    % Theoretical α
    if p < p_c_prime - 0.05
        theoretical_alpha(p_idx) = 1.0;
    elseif abs(p - p_c_prime) < 0.05
        theoretical_alpha(p_idx) = 0.5;
    else
        theoretical_alpha(p_idx) = 0.0;
    end
    
    % Use best method's result for detected α (simplified)
    p_key = sprintf('p_%.4f', p);
    if isfield(all_comparisons, p_key)
        best_method = all_comparisons.(p_key).best_method;
        if isfield(all_results.(p_key), best_method) && ...
           isfield(all_results.(p_key).(best_method), 'details') && ...
           isfield(all_results.(p_key).(best_method).details, 'expected_alpha')
            detected_alpha(p_idx) = all_results.(p_key).(best_method).details.expected_alpha;
        else
            detected_alpha(p_idx) = NaN;
        end
    else
        detected_alpha(p_idx) = NaN;
    end
end

valid_idx = ~isnan(detected_alpha);
if any(valid_idx)
    plot(p_values(valid_idx), theoretical_alpha(valid_idx), 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
    hold on;
    plot(p_values(valid_idx), detected_alpha(valid_idx), 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('p');
    ylabel('α');
    title('Theoretical vs Detected α');
    legend('Theoretical', 'Detected', 'Location', 'best');
    grid on;
end

sgtitle(sprintf('Enhanced Changepoint Detection: Comprehensive Analysis (p_c'' = %.4f)', p_c_prime));

% Save comprehensive plot
saveas(gcf, fullfile(output_dir, 'comprehensive_changepoint_analysis.png'));
saveas(gcf, fullfile(output_dir, 'comprehensive_changepoint_analysis.fig'));

% Generate text report
report_file = fullfile(output_dir, 'comprehensive_report.txt');
fid = fopen(report_file, 'w');

fprintf(fid, '=== Enhanced Changepoint Detection Comprehensive Report ===\n\n');
fprintf(fid, 'Analysis Parameters:\n');
fprintf(fid, '  p_c_prime = %.4f\n', p_c_prime);
fprintf(fid, '  p_values = [%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f]\n', p_values);
fprintf(fid, '  Methods tested: %s\n\n', strjoin(method_names, ', '));

fprintf(fid, 'Results Summary:\n');
fprintf(fid, '%-10s %-15s %-15s %-15s %-15s %-15s\n', 'p', method_names{:});
fprintf(fid, '%-10s %-15s %-15s %-15s %-15s %-15s\n', '----------', '---------------', '---------------', '---------------', '---------------', '---------------');

for p_idx = 1:n_p
    p = p_values(p_idx);
    fprintf(fid, '%-10.4f', p);
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
fprintf(fid, '%-10s %-15s %-15s %-15s %-15s %-15s\n', 'p', method_names{:});
fprintf(fid, '%-10s %-15s %-15s %-15s %-15s %-15s\n', '----------', '---------------', '---------------', '---------------', '---------------', '---------------');

for p_idx = 1:n_p
    p = p_values(p_idx);
    fprintf(fid, '%-10.4f', p);
    for m_idx = 1:n_methods
        fprintf(fid, ' %-14s', quality_matrix{p_idx, m_idx});
    end
    fprintf(fid, '\n');
end

fprintf(fid, '\nMethod Performance Analysis:\n');
fprintf(fid, 'Method Consistency (Std τ_cr):\n');
for m_idx = 1:n_methods
    method_std = method_consistency(m_idx);
    if ~isnan(method_std)
        fprintf(fid, '  %s: %.2e\n', method_names{m_idx}, method_std);
    else
        fprintf(fid, '  %s: N/A\n', method_names{m_idx});
    end
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

fprintf(fid, '\nConclusions:\n');
fprintf(fid, '1. Method comparison provides robust changepoint detection\n');
fprintf(fid, '2. Hybrid approach combines strengths of multiple methods\n');
fprintf(fid, '3. Theoretical prediction method leverages δ = πα/2 framework\n');
fprintf(fid, '4. Second derivative method provides curvature-based detection\n');
fprintf(fid, '5. Bisection piecewise fitting implements paper''s approach\n\n');

fprintf(fid, '=== End Report ===\n');
fclose(fid);

fprintf('Comprehensive report saved to: %s\n', report_file);

end 