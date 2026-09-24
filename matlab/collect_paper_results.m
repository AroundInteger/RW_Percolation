% collect_paper_results.m
% Collects and analyzes all batch results

function collect_paper_results()
    p = [0, 0.3116, 0.6884, 0.75];
    Np = numel(p);
    msd_all = [];
    t = [];
    
    fprintf('Collecting results from %d simulations...\n', Np);
    
    % Load all results
    for i_p = 1:Np
        mat_file = sprintf('msd_results_L100_p%.4f.mat', p(i_p));
        if exist(mat_file, 'file')
            load(mat_file);
            msd_all(:, i_p) = msd;
            if isempty(t)
                t = (1:length(msd))';
            end
            fprintf('Loaded: %s (final MSD = %.2f)\n', mat_file, msd(end));
        else
            warning('File not found: %s', mat_file);
        end
    end
    
    % Create combined results
    if ~isempty(msd_all)
        % Save combined results
        save('paper_results_combined.mat', 't', 'msd_all', 'p');
        
        % Create summary CSV
        var_names = [{'step'}, arrayfun(@(x) sprintf('p_%.4f', x), p, 'UniformOutput', false)];
        
        % Create table with separate columns for each p-value
        table_data = [t, msd_all];
        T = array2table(table_data, 'VariableNames', var_names);
        writetable(T, 'paper_results_combined.csv');
        
        % Plot all curves
        figure('Position', [100, 100, 1200, 800]);
        colors = {'blue', 'yellow', 'red', 'magenta'};
        for i_p = 1:Np
            loglog(t, msd_all(:, i_p), 'Color', colors{i_p}, 'LineWidth', 2, 'DisplayName', sprintf('p = %.4f', p(i_p)));
            hold on;
        end
        
        xlabel('Time Step τ', 'FontSize', 14);
        ylabel('Mean Squared Displacement ⟨Δr²(τ)⟩', 'FontSize', 14);
        title('3D Percolation Paper Simulations: 1M Steps, 1000 Walkers', 'FontSize', 16, 'FontWeight', 'bold');
        legend('Location', 'northwest', 'FontSize', 12);
        grid on;
        
        % Save plot
        saveas(gcf, 'paper_msd_comparison.png', 'png');
        saveas(gcf, 'paper_msd_comparison.fig', 'fig');
        
        fprintf('Combined results saved:\n');
        fprintf('  - paper_results_combined.mat\n');
        fprintf('  - paper_results_combined.csv\n');
        fprintf('  - paper_msd_comparison.png\n');
        fprintf('  - paper_msd_comparison.fig\n');
    else
        error('No results found to collect');
    end
end 