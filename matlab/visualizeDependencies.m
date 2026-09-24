function visualizeDependencies(results, data, isolatedPIs)
    % VISUALIZEDEPENDENCIES Create comprehensive visualizations of dependency analysis
    %
    % This function creates multiple plots to visualize the dependency analysis results
    %
    % Inputs:
    %   results - structure from analyzeRugbyDependencies function
    %   data - original data table (optional, for detailed plots)
    %   isolatedPIs - cell array of PI names (optional, for detailed plots)
    
    fprintf('Creating dependency visualization plots...\n');
    
    % === MAIN SUMMARY FIGURE ===
    createSummaryFigure(results);
    
    % === DETAILED VISUALIZATIONS ===
    if nargin >= 2
        createDetailedVisualizationsSuite(results, data, isolatedPIs);
    end
    
    fprintf('All plots created successfully.\n');
end

function createSummaryFigure(results)
    % Create main 4-panel summary figure
    
    figure('Name', 'Rugby League Dependency Analysis Summary', 'Position', [100 100 1200 800]);
    
    % Panel 1: Team Clustering (ICC) Distribution
    subplot(2, 2, 1);
    plotTeamClusteringDistribution(results);
    
    % Panel 2: Between-Season Stability
    subplot(2, 2, 2);
    plotBetweenSeasonStability(results);
    
    % Panel 3: Venue Effects
    subplot(2, 2, 3);
    plotVenueEffects(results);
    
    % Panel 4: Seasonal Progression
    subplot(2, 2, 4);
    plotSeasonalProgression(results);
    
    % Add overall title
    sgtitle('Rugby League Performance Indicator Dependencies', 'FontSize', 16, 'FontWeight', 'bold');
    
    % Save figure
    saveas(gcf, 'rugby_dependency_summary.png');
    saveas(gcf, 'rugby_dependency_summary.fig');
end

function plotTeamClusteringDistribution(results)
    % Plot ICC distribution across PIs
    
    if ~isfield(results, 'teamClustering')
        text(0.5, 0.5, 'Team clustering data not available', 'HorizontalAlignment', 'center');
        title('Team Clustering (ICC)');
        return;
    end
    
    fields = fieldnames(results.teamClustering);
    iccValues = [];
    piNames = {};
    
    for i = 1:length(fields)
        iccValues(end+1) = results.teamClustering.(fields{i}).icc;
        piNames{end+1} = strrep(fields{i}, '_i', '');
    end
    
    % Create horizontal bar plot
    [sortedICC, sortIdx] = sort(iccValues, 'descend');
    sortedNames = piNames(sortIdx);
    
    % Show top 10 for readability
    topN = min(10, length(sortedICC));
    
    barh(1:topN, sortedICC(1:topN));
    set(gca, 'YTick', 1:topN, 'YTickLabel', sortedNames(1:topN));
    xlabel('Intraclass Correlation (ICC)');
    title('Team Clustering Dependencies');
    grid on;
    
    % Add interpretation lines
    hold on;
    plot([0.5 0.5], [0 topN+1], 'r--', 'LineWidth', 2);
    plot([0.3 0.3], [0 topN+1], 'g--', 'LineWidth', 1);
    plot([0.1 0.1], [0 topN+1], 'b--', 'LineWidth', 1);
    
    legend('ICC Values', 'Strong (0.5)', 'Moderate (0.3)', 'Weak (0.1)', 'Location', 'southeast');
    xlim([0 max(0.6, max(sortedICC) * 1.1)]);
    ylim([0.5 topN + 0.5]);
end

function plotBetweenSeasonStability(results)
    % Plot between-season correlations
    
    if ~isfield(results, 'betweenSeason')
        text(0.5, 0.5, 'Between-season data not available', 'HorizontalAlignment', 'center');
        title('Between-Season Stability');
        return;
    end
    
    fields = fieldnames(results.betweenSeason);
    corrValues = [];
    piNames = {};
    
    for i = 1:length(fields)
        if ~isnan(results.betweenSeason.(fields{i}).mean_corr)
            corrValues(end+1) = results.betweenSeason.(fields{i}).mean_corr;
            piNames{end+1} = strrep(fields{i}, '_i', '');
        end
    end
    
    % Create horizontal bar plot
    [sortedCorr, sortIdx] = sort(corrValues, 'descend');
    sortedNames = piNames(sortIdx);
    
    % Show top 10 for readability
    topN = min(10, length(sortedCorr));
    
    barh(1:topN, sortedCorr(1:topN));
    set(gca, 'YTick', 1:topN, 'YTickLabel', sortedNames(1:topN));
    xlabel('Year-on-Year Correlation');
    title('Between-Season Stability');
    grid on;
    
    % Add interpretation lines
    hold on;
    plot([0.7 0.7], [0 topN+1], 'r--', 'LineWidth', 2);
    plot([0.5 0.5], [0 topN+1], 'g--', 'LineWidth', 1);
    plot([0.3 0.3], [0 topN+1], 'b--', 'LineWidth', 1);
    
    legend('Correlations', 'Strong (0.7)', 'Moderate (0.5)', 'Weak (0.3)', 'Location', 'southeast');
    xlim([min(0, min(sortedCorr) * 1.1) max(1, max(sortedCorr) * 1.1)]);
    ylim([0.5 topN + 0.5]);
end

function plotVenueEffects(results)
    % Plot home/away effect sizes
    
    if ~isfield(results, 'venue')
        text(0.5, 0.5, 'Venue effects data not available', 'HorizontalAlignment', 'center');
        title('Venue Effects');
        return;
    end
    
    fields = fieldnames(results.venue);
    effectSizes = [];
    piNames = {};
    colors = [];
    
    for i = 1:length(fields)
        effectSizes(end+1) = results.venue.(fields{i}).effect_size;
        piNames{end+1} = strrep(fields{i}, '_i', '');
        
        % Color based on direction
        if effectSizes(end) > 0
            colors(end+1, :) = [0.2 0.6 1]; % Blue for home advantage
        else
            colors(end+1, :) = [1 0.4 0.2]; % Orange for away advantage
        end
    end
    
    % Sort by absolute effect size
    [~, sortIdx] = sort(abs(effectSizes), 'descend');
    sortedEffects = effectSizes(sortIdx);
    sortedNames = piNames(sortIdx);
    sortedColors = colors(sortIdx, :);
    
    % Show top 10
    topN = min(10, length(sortedEffects));
    
    for i = 1:topN
        barh(i, sortedEffects(i), 'FaceColor', sortedColors(i, :));
        hold on;
    end
    
    set(gca, 'YTick', 1:topN, 'YTickLabel', sortedNames(1:topN));
    xlabel('Effect Size (Cohen''s d)');
    title('Home/Away Venue Effects');
    grid on;
    
    % Add interpretation lines
    plot([0.8 0.8], [0 topN+1], 'r--', 'LineWidth', 2);
    plot([-0.8 -0.8], [0 topN+1], 'r--', 'LineWidth', 2);
    plot([0.5 0.5], [0 topN+1], 'g--', 'LineWidth', 1);
    plot([-0.5 -0.5], [0 topN+1], 'g--', 'LineWidth', 1);
    plot([0.2 0.2], [0 topN+1], 'b--', 'LineWidth', 1);
    plot([-0.2 -0.2], [0 topN+1], 'b--', 'LineWidth', 1);
    
    legend('Home Advantage', 'Away Advantage', 'Large (±0.8)', 'Medium (±0.5)', 'Small (±0.2)', 'Location', 'best');
    
    maxEffect = max(abs(sortedEffects));
    xlim([-maxEffect*1.2 maxEffect*1.2]);
    ylim([0.5 topN + 0.5]);
end

function plotSeasonalProgression(results)
    % Plot seasonal progression effect sizes
    
    if ~isfield(results, 'seasonalProgression')
        text(0.5, 0.5, 'Seasonal progression data not available', 'HorizontalAlignment', 'center');
        title('Seasonal Progression');
        return;
    end
    
    fields = fieldnames(results.seasonalProgression);
    effectSizes = [];
    piNames = {};
    colors = [];
    
    for i = 1:length(fields)
        effectSizes(end+1) = results.seasonalProgression.(fields{i}).effect_size;
        piNames{end+1} = strrep(fields{i}, '_i', '');
        
        % Color based on direction
        if effectSizes(end) > 0
            colors(end+1, :) = [0.2 0.8 0.2]; % Green for improving
        else
            colors(end+1, :) = [0.8 0.2 0.2]; % Red for declining
        end
    end
    
    % Sort by absolute effect size
    [~, sortIdx] = sort(abs(effectSizes), 'descend');
    sortedEffects = effectSizes(sortIdx);
    sortedNames = piNames(sortIdx);
    sortedColors = colors(sortIdx, :);
    
    % Show top 10
    topN = min(10, length(sortedEffects));
    
    for i = 1:topN
        barh(i, sortedEffects(i), 'FaceColor', sortedColors(i, :));
        hold on;
    end
    
    set(gca, 'YTick', 1:topN, 'YTickLabel', sortedNames(1:topN));
    xlabel('Effect Size (Cohen''s d)');
    title('Seasonal Progression (Late - Early)');
    grid on;
    
    % Add interpretation lines
    plot([0.8 0.8], [0 topN+1], 'r--', 'LineWidth', 2);
    plot([-0.8 -0.8], [0 topN+1], 'r--', 'LineWidth', 2);
    plot([0.5 0.5], [0 topN+1], 'g--', 'LineWidth', 1);
    plot([-0.5 -0.5], [0 topN+1], 'g--', 'LineWidth', 1);
    
    legend('Improving', 'Declining', 'Large (±0.8)', 'Medium (±0.5)', 'Location', 'best');
    
    maxEffect = max(abs(sortedEffects));
    xlim([-maxEffect*1.2 maxEffect*1.2]);
    ylim([0.5 topN + 0.5]);
end

function createDetailedVisualizationsSuite(results, data, isolatedPIs)
    % Create detailed visualizations with data
    
    % === TEMPORAL ANALYSIS FIGURE ===
    createTemporalAnalysisFigure(results, data, isolatedPIs);
    
    % === TEAM PERFORMANCE HEATMAP ===
    createTeamPerformanceHeatmap(results, data, isolatedPIs);
    
    % === DEPENDENCY CORRELATION MATRIX ===
    createDependencyCorrelationFigure(results);
    
    % === VENUE AND SEASONAL DETAILED ANALYSIS ===
    createVenueSeasonalDetailedFigure(results, data, isolatedPIs);
end

function createTemporalAnalysisFigure(results, data, isolatedPIs)
    % Detailed temporal analysis visualization
    
    figure('Name', 'Temporal Dependencies Analysis', 'Position', [150 150 1400 800]);
    
    % Get top 6 PIs with strongest temporal effects
    if isfield(results, 'temporal')
        fields = fieldnames(results.temporal);
        autocorrValues = [];
        topPIs = {};
        
        for i = 1:length(fields)
            if results.temporal.(fields{i}).n_team_seasons > 10
                autocorrValues(end+1) = abs(results.temporal.(fields{i}).mean_autocorr);
                topPIs{end+1} = fields{i};
            end
        end
        
        [~, sortIdx] = sort(autocorrValues, 'descend');
        topPIs = topPIs(sortIdx(1:min(6, length(sortIdx))));
        
        for i = 1:length(topPIs)
            subplot(2, 3, i);
            plotTemporalTrend(data, topPIs{i});
        end
        
        sgtitle('Within-Season Temporal Patterns (Top PIs)', 'FontSize', 14);
    end
    
    saveas(gcf, 'temporal_analysis_detailed.png');
end

function plotTemporalTrend(data, pi)
    % Plot temporal trend for a specific PI
    
    teams = unique(data.team);
    seasons = unique(data.season);
    
    colors = lines(length(teams));
    
    hold on;
    
    for teamIdx = 1:min(5, length(teams)) % Show only first 5 teams for clarity
        team = teams{teamIdx};
        
        for season = seasons'
            teamSeasonData = data(strcmp(data.team, team) & data.season == season, :);
            
            if height(teamSeasonData) > 3
                teamSeasonData = sortrows(teamSeasonData, 'season_match');
                
                x = teamSeasonData.season_match;
                y = teamSeasonData.(pi);
                
                % Remove NaN values
                validIdx = ~isnan(y);
                x = x(validIdx);
                y = y(validIdx);
                
                if length(x) > 2
                    plot(x, y, 'Color', colors(teamIdx, :), 'LineWidth', 1, 'Marker', 'o', 'MarkerSize', 4);
                end
            end
        end
    end
    
    xlabel('Match in Season');
    ylabel(strrep(pi, '_i', ''));
    title(sprintf('%s Temporal Pattern', strrep(pi, '_i', '')));
    grid on;
    
    % Add trend line
    allSeasonMatches = [];
    allValues = [];
    
    for season = seasons'
        seasonData = data(data.season == season, :);
        seasonData = seasonData(~isnan(seasonData.(pi)), :);
        
        allSeasonMatches = [allSeasonMatches; seasonData.season_match];
        allValues = [allValues; seasonData.(pi)];
    end
    
    if length(allValues) > 10
        p = polyfit(allSeasonMatches, allValues, 1);
        xTrend = linspace(min(allSeasonMatches), max(allSeasonMatches), 100);
        yTrend = polyval(p, xTrend);
        plot(xTrend, yTrend, 'k--', 'LineWidth', 2);
    end
end

function createTeamPerformanceHeatmap(results, data, isolatedPIs)
    % Create team-PI performance heatmap
    
    figure('Name', 'Team Performance Heatmap', 'Position', [200 200 1200 800]);
    
    teams = unique(data.team);
    
    % Select top 10 PIs with highest ICC
    if isfield(results, 'teamClustering')
        fields = fieldnames(results.teamClustering);
        iccValues = [];
        
        for i = 1:length(fields)
            iccValues(end+1) = results.teamClustering.(fields{i}).icc;
        end
        
        [~, sortIdx] = sort(iccValues, 'descend');
        topPIs = fields(sortIdx(1:min(10, length(fields))));
        
        % Calculate team averages for heatmap
        heatmapData = zeros(length(teams), length(topPIs));
        
        for teamIdx = 1:length(teams)
            team = teams{teamIdx};
            teamData = data(strcmp(data.team, team), :);
            
            for piIdx = 1:length(topPIs)
                pi = topPIs{piIdx};
                values = teamData.(pi);
                values = values(~isnan(values));
                
                if ~isempty(values)
                    heatmapData(teamIdx, piIdx) = mean(values);
                end
            end
        end
        
        % Normalize by column (z-score)
        heatmapDataNorm = zscore(heatmapData);
        
        % Create heatmap
        imagesc(heatmapDataNorm);
        colorbar;
        colormap(redblue);
        
        % Set labels
        set(gca, 'XTick', 1:length(topPIs), 'XTickLabel', cellfun(@(x) strrep(x, '_i', ''), topPIs, 'UniformOutput', false));
        set(gca, 'YTick', 1:length(teams), 'YTickLabel', teams);
        
        title('Team Performance Heatmap (Standardized Values)');
        xlabel('Performance Indicators');
        ylabel('Teams');
        
        % Rotate x-axis labels
        xtickangle(45);
    end
    
    saveas(gcf, 'team_performance_heatmap.png');
end

function createDependencyCorrelationFigure(results)
    % Create correlation matrix of different dependency types
    
    figure('Name', 'Dependency Correlation Analysis', 'Position', [250 250 1000 600]);
    
    % Extract data for correlation analysis
    piNames = {};
    iccValues = [];
    stabilityValues = [];
    venueEffects = [];
    seasonalEffects = [];
    
    % Get common PIs across all analyses
    if isfield(results, 'teamClustering')
        fields = fieldnames(results.teamClustering);
        
        for i = 1:length(fields)
            pi = fields{i};
            piNames{end+1} = strrep(pi, '_i', '');
            
            % ICC values
            iccValues(end+1) = results.teamClustering.(pi).icc;
            
            % Stability values
            if isfield(results, 'betweenSeason') && isfield(results.betweenSeason, pi)
                stabilityValues(end+1) = results.betweenSeason.(pi).mean_corr;
            else
                stabilityValues(end+1) = NaN;
            end
            
            % Venue effects
            if isfield(results, 'venue') && isfield(results.venue, pi)
                venueEffects(end+1) = abs(results.venue.(pi).effect_size);
            else
                venueEffects(end+1) = NaN;
            end
            
            % Seasonal effects
            if isfield(results, 'seasonalProgression') && isfield(results.seasonalProgression, pi)
                seasonalEffects(end+1) = abs(results.seasonalProgression.(pi).effect_size);
            else
                seasonalEffects(end+1) = NaN;
            end
        end
    end
    
    % Create correlation matrix
    dependencyMatrix = [iccValues' stabilityValues' venueEffects' seasonalEffects'];
    
    % Remove rows with NaN values
    validRows = ~any(isnan(dependencyMatrix), 2);
    dependencyMatrix = dependencyMatrix(validRows, :);
    validPINames = piNames(validRows);
    
    if size(dependencyMatrix, 1) > 3
        % Calculate correlation matrix
        corrMatrix = corrcoef(dependencyMatrix);
        
        subplot(1, 2, 1);
        imagesc(corrMatrix);
        colorbar;
        colormap(redblue);
        caxis([-1 1]);
        
        dependencyLabels = {'Team Clustering', 'Season Stability', 'Venue Effects', 'Seasonal Progression'};
        set(gca, 'XTick', 1:4, 'XTickLabel', dependencyLabels);
        set(gca, 'YTick', 1:4, 'YTickLabel', dependencyLabels);
        title('Dependency Type Correlations');
        xtickangle(45);
        
        % Add correlation values as text
        for i = 1:4
            for j = 1:4
                text(j, i, sprintf('%.2f', corrMatrix(i, j)), 'HorizontalAlignment', 'center', 'Color', 'k');
            end
        end
        
        % Scatter plot of key relationships
        subplot(1, 2, 2);
        scatter(iccValues(validRows), stabilityValues(validRows), 50, 'filled');
        xlabel('Team Clustering (ICC)');
        ylabel('Between-Season Stability (r)');
        title('ICC vs Stability Relationship');
        grid on;
        
        % Add trend line if sufficient data
        if sum(~isnan(stabilityValues(validRows))) > 5
            validStability = ~isnan(stabilityValues(validRows));
            p = polyfit(iccValues(validRows & validStability'), stabilityValues(validRows & validStability'), 1);
            xTrend = linspace(min(iccValues(validRows)), max(iccValues(validRows)), 100);
            yTrend = polyval(p, xTrend);
            hold on;
            plot(xTrend, yTrend, 'r--', 'LineWidth', 2);
        end
    end
    
    saveas(gcf, 'dependency_correlations.png');
end

function createVenueSeasonalDetailedFigure(results, data, isolatedPIs)
    % Detailed venue and seasonal analysis
    
    figure('Name', 'Venue and Seasonal Effects Detail', 'Position', [300 300 1400 600]);
    
    % Get top PIs for venue effects
    if isfield(results, 'venue')
        fields = fieldnames(results.venue);
        effectSizes = [];
        
        for i = 1:length(fields)
            effectSizes(end+1) = abs(results.venue.(fields{i}).effect_size);
        end
        
        [~, sortIdx] = sort(effectSizes, 'descend');
        topVenuePIs = fields(sortIdx(1:min(3, length(fields))));
        
        % Plot venue effects details
        for i = 1:length(topVenuePIs)
            subplot(2, 3, i);
            plotVenueDetail(data, topVenuePIs{i});
        end
    end
    
    % Get top PIs for seasonal effects
    if isfield(results, 'seasonalProgression')
        fields = fieldnames(results.seasonalProgression);
        effectSizes = [];
        
        for i = 1:length(fields)
            effectSizes(end+1) = abs(results.seasonalProgression.(fields{i}).effect_size);
        end
        
        [~, sortIdx] = sort(effectSizes, 'descend');
        topSeasonalPIs = fields(sortIdx(1:min(3, length(fields))));
        
        % Plot seasonal effects details
        for i = 1:length(topSeasonalPIs)
            subplot(2, 3, i + 3);
            plotSeasonalDetail(data, topSeasonalPIs{i});
        end
    end
    
    saveas(gcf, 'venue_seasonal_details.png');
end

function plotVenueDetail(data, pi)
    % Plot detailed venue analysis for specific PI
    
    homeData = data(strcmp(data.match_location, 'home'), :);
    awayData = data(strcmp(data.match_location, 'away'), :);
    
    homeValues = homeData.(pi);
    awayValues = awayData.(pi);
    
    homeValues = homeValues(~isnan(homeValues));
    awayValues = awayValues(~isnan(awayValues));
    
    if ~isempty(homeValues) && ~isempty(awayValues)
        % Create box plot
        boxplot([homeValues; awayValues], [ones(size(homeValues)); 2*ones(size(awayValues))], ...
            'Labels', {'Home', 'Away'});
        
        title(sprintf('%s by Venue', strrep(pi, '_i', '')));
        ylabel('Performance Value');
        grid on;
        
        % Add means as red diamonds
        hold on;
        plot(1, mean(homeValues), 'rd', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        plot(2, mean(awayValues), 'rd', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    end
end

function plotSeasonalDetail(data, pi)
    % Plot detailed seasonal analysis for specific PI
    
    earlyData = data(data.season_match <= 6, :);
    lateData = data(data.season_match >= 12, :);
    
    earlyValues = earlyData.(pi);
    lateValues = lateData.(pi);
    
    earlyValues = earlyValues(~isnan(earlyValues));
    lateValues = lateValues(~isnan(lateValues));
    
    if ~isempty(earlyValues) && ~isempty(lateValues)
        % Create box plot
        boxplot([earlyValues; lateValues], [ones(size(earlyValues)); 2*ones(size(lateValues))], ...
            'Labels', {'Early Season', 'Late Season'});
        
        title(sprintf('%s Seasonal Progression', strrep(pi, '_i', '')));
        ylabel('Performance Value');
        grid on;
        
        % Add means as red diamonds
        hold on;
        plot(1, mean(earlyValues), 'rd', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        plot(2, mean(lateValues), 'rd', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    end
end

% === UTILITY FUNCTIONS ===

function cmap = redblue(n)
    % Create red-blue colormap
    if nargin < 1
        n = 256;
    end
    
    % Create colormap from blue to white to red
    if n == 1
        cmap = [0 0 1];
    elseif n == 2
        cmap = [0 0 1; 1 0 0];
    else
        m = ceil(n/2);
        bottom = [linspace(0, 1, m)', linspace(0, 1, m)', ones(m, 1)];
        top = [ones(m, 1), linspace(1, 0, m)', linspace(1, 0, m)'];
        cmap = [bottom(1:end-1, :); top];
        cmap = cmap(1:n, :);
    end
end

% === MAIN USAGE EXAMPLES ===

function runCompleteAnalysisWithVisualization()
    % Example of complete workflow
    
    fprintf('Running complete rugby dependency analysis with visualizations...\n');
    
    % Run main analysis
    results = analyzeRugbyDependencies('3_seasons_isolated.csv');
    
    % Load data for detailed visualizations
    data = readtable('3_seasons_isolated.csv');
    allColumns = data.Properties.VariableNames;
    isolatedPIs = allColumns(contains(allColumns, '_i') & ~strcmp(allColumns, 'final_points_i'));
    
    % Create all visualizations
    visualizeDependencies(results, data, isolatedPIs);
    
    fprintf('Complete analysis and visualization finished.\n');
    fprintf('Check the following files:\n');
    fprintf('- rugby_dependency_summary.png/fig\n');
    fprintf('- temporal_analysis_detailed.png\n');
    fprintf('- team_performance_heatmap.png\n');
    fprintf('- dependency_correlations.png\n');
    fprintf('- venue_seasonal_details.png\n');
end