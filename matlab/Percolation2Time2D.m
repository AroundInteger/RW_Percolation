%% MATLAB Code for Mapping Percolation to Gelation Kinetics
% This script transforms loss tangent data from percolation probability (p) 
% to time (t) domain using the relationship: p(t) = p_∞(1-e^(-kt))

% Clear workspace
%clear; clc; close all;

%% Parameters - ADJUST AS NEEDED
p_infinity = 0.9;    % Maximum percolation probability (p_∞)
k = 0.05;            % Rate constant (s^-1)
dimension = '2D';    % Options: '2D' or '3D'

% Set percolation thresholds based on dimension
if strcmp(dimension, '3D')
    p_c = 0.3116;        % True gel point (3D percolation threshold)
    p_c_prime = 0.6884;  % Apparent gel point (3D unoccupied site threshold)
else % 2D
    p_c = 0.5927;        % True gel point (2D percolation threshold)
    p_c_prime = 0.4073;  % Apparent gel point (2D unoccupied site threshold)
end

%% Load and Process Data
% Load data
filename = 'loss_tangent_data_2D.csv';
try
    data = readmatrix(filename);
catch
    error('Error loading file. Please check the filename and format.');
end

dims = size(data);

datai = [];

for ii = 1:2:16

    xi = linspace(0,(0.9-1e-6),200)';
    x = interp1(data(:,ii),data(:,ii+1),xi,"pchip");

    datai = [datai,[xi,x]];

end

data = datai;



%%

% Function to convert percolation probability to time
p_to_time = @(p) (-1/k) * log(1 - p/p_infinity);

% Define frequencies from your figure (rad/S)
frequencies = [0.0010, 0.0019, 0.0037, 0.0072, 0.0139, 0.0268, 0.0518, 0.1000];

% Extract data (assuming alternating columns: p1, delta1, p2, delta2, ...)
num_cols = size(data, 2);
num_frequencies = floor(num_cols/2);

p_values = cell(1, num_frequencies);
delta_values = cell(1, num_frequencies);

for i = 1:num_frequencies
    p_col = i*2 - 1;    % Columns 1, 3, 5, ...
    delta_col = i*2;    % Columns 2, 4, 6, ...
    
    if p_col <= num_cols && delta_col <= num_cols
        p_data = data(:, p_col);
        delta_data = data(:, delta_col);
        
        % Remove NaN values
        valid_indices = ~isnan(p_data) & ~isnan(delta_data);
        p_values{i} = p_data(valid_indices);
        delta_values{i} = delta_data(valid_indices);
    end
end

%% Percolation

% Create figure
figure(2);

% Define colors and line styles for the plot
colors = {
    [0, 0.4470, 0.7410],         % blue solid
    [0.8500, 0.3250, 0.0980],    % orange dotted
    [0.9290, 0.6940, 0.1250],    % yellow dash
    [0.4940, 0.1840, 0.5560],    % purple dash
    [0.4660, 0.6740, 0.1880],    % green dash
    [0.3010, 0.7450, 0.9330],    % light blue dash-dot
    [0.6350, 0.0780, 0.1840],    % burgundy dash-dot
    [0, 0.4470, 0.7410]          % blue dash-dot
};

line_styles = {'-', ':', '--', '--', '--', '-.', '-.', '-.'};
subplot(1,2,1)
% Plot loss tangent vs time for each frequency
hold on;%
legend_entries = cell(1, num_frequencies);

% Find min/max p values for axis limits
all_p = [];
for i = 1:length(p_values)
    all_p = [all_p; p_values{i}(:)];
end
valid_p = all_p(all_p > 0 & all_p < p_infinity);
min_p = min(valid_p);
max_p = max(valid_p);

% Plot each frequency
for i = 1:min(num_frequencies, length(frequencies))
    % Convert percolation probabilities to time
    % Plot loss tangent vs percolation
    plot(p_values{i}, delta_values{i}, line_styles{min(i, length(line_styles))}, ...
        'Color', colors{min(i, length(colors))}, 'LineWidth', 1.5);
    
    % Create legend entry
    legend_entries{i} = sprintf('%.4f rad/s', frequencies(i));
    
end

% Add vertical lines for true and apparent gel points
line([p_c, p_c], [0, 90], 'LineStyle', '--', 'Color', 'k', 'LineWidth', 2);
line([p_c_prime, p_c_prime], [0, 90], 'LineStyle', '--', 'Color', 'k', 'LineWidth', 2);

% Set axis limits
% min_t = p_to_time(min_p) * 0.9;
% max_t = p_to_time(max_p) * 1.1;
xlim([0.1, 0.8]);
ylim([0, 90]);

% Add annotations for gel points
text_offset = (max_p - min_p) * 0.07;
text(p_c + text_offset*0.5, 45, '$p_c$', 'FontSize', 24,'Interpreter','latex');
text(p_c_prime - text_offset*1, 45, '$p''_c$', 'FontSize', 24,'Interpreter','latex');

% Add labels and title
%title(sprintf('Loss tangent \\delta vs Time for %s percolation lattices', dimension), 'FontSize', 14);
grid on;

% % Display the time lag between true and apparent gel points
% fprintf('Time lag between true and apparent gel points: %.2f seconds\n', delta_t);
% 
% % % Add a text box with the parameters
% % param_text = sprintf('Parameters:\np_\\infty = %.2f\nk = %.4f s^{-1}\np_c = %.4f\np''_c = %.4f\n\\Delta t = %.2f s', ...
% %     p_infinity, k, p_c, p_c_prime, delta_t);
set(gca, 'FontSize', 20);
% annotation('textbox', [0.35, 0.15, 0.2, 0.4], 'String', param_text, 'EdgeColor', 'none', 'FontSize', 20);
xlabel('Percolation $p$ (arb. units)', 'FontSize', 24,'Interpreter','latex');
ylabel('$\delta (^{\circ})$', 'FontSize', 24,'Interpreter','latex');
%legend(legend_entries, 'Location', 'eastoutside','FontSize',16);legend box off
text(0.125, 85, '(a)', 'FontSize', 22);
% % Save the figure
% % saveas(gcf, sprintf('%s_time_mapping.png', strrep(filename, '.csv', '')));
% % saveas(gcf, sprintf('%s_time_mapping.fig', strrep(filename, '.csv', '')));
box on
hold off;


%% Calculate Time Points and Create Plot
% Convert true and apparent gel points to time
t_true = p_to_time(p_c);
t_app = p_to_time(p_c_prime);
delta_t = t_app - t_true;

% % Create figure
% figure('Position', [100, 100, 1000, 600]);

% Define colors and line styles for the plot
colors = {
    [0, 0.4470, 0.7410],         % blue solid
    [0.8500, 0.3250, 0.0980],    % orange dotted
    [0.9290, 0.6940, 0.1250],    % yellow dash
    [0.4940, 0.1840, 0.5560],    % purple dash
    [0.4660, 0.6740, 0.1880],    % green dash
    [0.3010, 0.7450, 0.9330],    % light blue dash-dot
    [0.6350, 0.0780, 0.1840],    % burgundy dash-dot
    [0, 0.4470, 0.7410]          % blue dash-dot
};

line_styles = {'-', ':', '--', '--', '--', '-.', '-.', '-.'};
subplot(1,2,2)
% Plot loss tangent vs time for each frequency
hold on;
legend_entries = cell(1, num_frequencies);

% Find min/max p values for axis limits
all_p = [];
for i = 1:length(p_values)
    all_p = [all_p; p_values{i}(:)];
end
valid_p = all_p(all_p > 0 & all_p < p_infinity);
min_p = min(valid_p);
max_p = max(valid_p);

% Plot each frequency
for i = 1:min(num_frequencies, length(frequencies))
    % Convert percolation probabilities to time
    t_values = (p_to_time(p_values{i}));
    
    % Plot loss tangent vs time
    plot(t_values, delta_values{i}, line_styles{min(i, length(line_styles))}, ...
        'Color', colors{min(i, length(colors))}, 'LineWidth', 1.5);
    
    % Create legend entry
    legend_entries{i} = sprintf('%.4f rad/s', frequencies(i));
end

% Add vertical lines for true and apparent gel points
line([t_true, t_true], [0, 90], 'LineStyle', '--', 'Color', 'k', 'LineWidth', 2);
line([t_app, t_app], [0, 90], 'LineStyle', '--', 'Color', 'k', 'LineWidth', 2);

% Set axis limits
min_t = p_to_time(min_p) * 0.9;
max_t = p_to_time(max_p) * 1.1;
%xlim([min_t, max_t]);
ylim([0, 90]);
xlim([0, 50]);

% Add annotations for gel points
text_offset = (max_t - min_t) * 0.05;
text(t_true + 2, 45, '$t_{true}$', 'FontSize', 22,'Interpreter','latex');
text(t_app - 7, 45, '$t_{app}$', 'FontSize', 22,'Interpreter','latex');

% Add labels and title
% title(sprintf('Loss tangent \\delta vs Time for %s percolation lattices', dimension), 'FontSize', 14);
grid on;

% Display the time lag between true and apparent gel points
fprintf('Time lag between true and apparent gel points: %.2f seconds\n', delta_t);

% Add a text box with the parameters
param_text = sprintf('Parameters:\np_\\infty = %.2f\nk = %.4f s^{-1}\np_c = %.4f\np''_c = %.4f\n\\Deltat = %.2f s', ...
    p_infinity, k, p_c, p_c_prime, delta_t);
set(gca, 'FontSize', 20);
xlabel('Time (s)', 'FontSize', 24,'Interpreter','latex');
ylabel('$\delta (^{\circ})$', 'FontSize', 24,'Interpreter','latex');
% annotation('textbox', [0.5, 0.15, 0.2, 0.4], 'String', param_text, 'EdgeColor', 'none', 'FontSize', 20);
annotation('doublearrow',[0.65,0.715],[1,1]*0.66,'LineWidth',2);
text(15, 63, '$\Delta t$', 'FontSize', 20,'Interpreter','latex');
box on
text(2, 85, '(b)', 'FontSize', 22);
legend(legend_entries, 'Location', 'northeast','FontSize',16);legend box off

fig = gcf;
set(fig,"Position",[100, 100, 1000, 600])

hold off;
% Save the figure
% saveas(gcf, sprintf('%s_time_mapping.png', strrep(filename, '.csv', '')));
% saveas(gcf, sprintf('%s_time_mapping.fig', strrep(filename, '.csv', '')));



%% Function for Processing Multiple Datasets
function process_additional_dataset(filename, p_infinity, k, p_c, p_c_prime, dimension)
    % This function can be called for each of your 7 additional datasets
    % Copy the data loading and plotting code from above, making it 
    % into a reusable function
    
    % Example usage:
    % process_additional_dataset('dataset2.csv', 0.9, 0.05, 0.3116, 0.6884, '3D');
    % process_additional_dataset('dataset3.csv', 0.85, 0.07, 0.3116, 0.6884, '3D');
    
    % Function implementation here...
    % (Copy the relevant code from above)
end