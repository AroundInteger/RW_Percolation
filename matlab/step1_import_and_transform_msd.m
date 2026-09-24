%% Step 1: Import MSD Data and Transform to Logspace
% This script imports the MSD data from 'p_output_NEW34.csv' and
% transforms it to logspace with linear interpolation for consistent analysis

clear; clc; close all; format short g

%% 1. Import MSD Data
fprintf('Step 1: Importing MSD data...\n');

% Define file path
%data_file = 'Clusters/p_output_C1.csv';
data_file = 'Clusters/MSD_table_1.csv';

load("Clusters/iMacBook_MSD_table_3.mat")

% % Check if file exists
% if ~exist(data_file, 'file')
%     error('Data file not found: %s', data_file);
% end
% 
% % Import data
% fprintf('Loading CSV file (this may take a moment for large files)...\n');
% msd_data = readtable(data_file);
% 
% Extract column names (p-values) and MSD values
p_values_str = MSD_table.Properties.VariableNames;
msd_values = table2array(MSD_table);

% Convert p-values from strings to numbers
p_values = zeros(1, length(p_values_str));
for i = 1:length(p_values_str)
    % Remove 'MSD_' prefix and convert to number
    p_str = strrep(p_values_str{i}, 'MSD_', '');
    p_str = strrep(p_str, '_', '.');
    p_values(i) = str2double(p_str);
end

% Create time vector (0 to 999999)
time_steps = (0:size(msd_values, 1)-1)';

fprintf('Data loaded successfully!\n');
fprintf('Number of time steps: %d\n', length(time_steps));
fprintf('Number of p-values: %d\n', length(p_values));
fprintf('Data size: %d x %d\n', size(msd_values));

%% 2. Display Data Structure
fprintf('\nStep 2: Data structure overview...\n');

% Show first few p-values
fprintf('First 10 p-values: ');
fprintf('%.4f ', p_values(1:10));
fprintf('\n');

% Show last few p-values
fprintf('Last 10 p-values: ');
fprintf('%.4f ', p_values(end-9:end));
fprintf('\n');

% Show time range
fprintf('Time range: %d to %d steps\n', time_steps(1), time_steps(end));

%% 3. Transform to Logspace
fprintf('\nStep 3: Transforming to logspace...\n');

% Create log-spaced time vector
% We want to focus on the meaningful range (avoid t=0 and very early times)
% log_time_startIDX = 1;  % Start from step 1 to avoid log(0)
% log_time_endIDX = length(time_steps) - 1;  % End at step 999999

time_steps = (1:length(msd_values))';

log_time = log10(time_steps+1);
log_msd = log10(msd_values+1);
log_msd_by_t = log10((msd_values+1)./(time_steps+1));

% Create log-spaced time points
n_log_points = 2000;  % Number of log-spaced points

% Extract MSD values at log-spaced time points
msd_logspaced = zeros(n_log_points, length(p_values));
msd_logspaced_by_t = zeros(n_log_points, length(p_values));
time_logspaced = linspace(min(log_time),max(log_time),n_log_points)';


for p_idx = 1:length(p_values)
    % Use interp1 for smooth interpolation
    msd_logspaced(:, p_idx) = interp1(log_time, log_msd(:, p_idx), time_logspaced, 'pchip');
    msd_logspaced_by_t(:, p_idx) = interp1(log_time, log_msd_by_t(:, p_idx), time_logspaced, 'pchip');
end
%%
% fprintf('Interpolated to %d linearly spaced points\n', n_linear_points);
% fprintf('Linear time range: %.1f to %.1f steps\n', time_linear(1), time_linear(end));
id_p_lt_pcp = p_values <= 0.55;
id_p_gt_pcp = p_values >= 0.7;
id_p_eq_pcp = not(id_p_lt_pcp|id_p_gt_pcp);

figure(1)
plot(log_time,log_msd(:,id_p_lt_pcp),'g-');hold on
plot(log_time,log_msd(:,id_p_eq_pcp),'-k')
plot(log_time,log_msd(:,id_p_gt_pcp),'-r');hold off
figure(2);
subplot(1,3,1);plot(log_time,log_msd_by_t(:,id_p_lt_pcp)-log_msd_by_t(end,id_p_lt_pcp),'-')
subplot(1,3,2);plot(log_time,log_msd_by_t(:,id_p_eq_pcp)-log_msd_by_t(end,id_p_eq_pcp),'-')
subplot(1,3,3);plot(log_time,log_msd_by_t(:,id_p_gt_pcp)-log_msd_by_t(end,id_p_gt_pcp),'-')
figure(3);plot(time_logspaced,msd_logspaced_by_t(:,id_p_lt_pcp)-msd_logspaced_by_t(end,id_p_lt_pcp),'-')
figure(4);plot(log_time,log_msd)
% Save the processed data
% save('MSD_table_1_reduced.mat', 'p_values','time_logspaced', 'msd_logspaced', 'msd_logspaced_by_t');

%%
N_p = numel(p_values);

t = time_logspaced;
tau_cr_Idx = nan(N_p,1);
tau_cr_msd = nan(N_p,1);
tau_cr_msdbyt = nan(N_p,1);
tau_cr_t = nan(N_p,1);

for ii = 1:N_p
y = msd_logspaced_by_t(:,ii);
z = y - y(end,:);
dz = movmean(gradient(z),11);
if ii > 1
    id_z2 = find(dz>0& t > 2,1,"first");
else 
    id_z2 = find(dz<0 & t > 1.5,1,"first");
end
%figure(5);subplot(2,1,1);plot(t,dz*1000,t,z,t(id_z2),z(id_z2),'ok');legend
if ~isempty(id_z2)
    tau_cr_msdbyt(ii) = msd_logspaced_by_t(id_z2,ii);
    tau_cr_msd(ii) = msd_logspaced(id_z2,ii);
    tau_cr_t(ii) = t(id_z2);
    tau_cr_Idx(ii) = id_z2;
end
id_z1 = abs(z) < 0.03 & t > 3;
%id_z2 = abs(z) < 0.03 & t > 3;

a = t(id_z1)\z(id_z1);

pf = polyfit(t(id_z1),z(id_z1),1);
pv_z = polyval(pf,t);




% fun = @(a) fit_linear_region(a,t(id_z1),z(id_z1));
% a0 = [1,0.1];
% [af,~,~,~] = fminsearch(fun,a0);
% [~,z_fit] = fit_linear_region(af,t,z);
% 
% % find roots
% [~,r1_IDX] = min(abs(z - z_fit));

%subplot(2,1,2);plot(t,z,'.-',t,pv_z,'--',t,pv_z,'-',t,z_fit,'-',t(id_z2),z(id_z2),'ok');legend
end

pf = polyfit(t(id_z1),z(id_z1),1);
pv_z = polyval(pf,t);

figure(6);
subplot(1,2,1);plot(time_logspaced,msd_logspaced(:,:),'-',tau_cr_t,tau_cr_msd,'-ok')
subplot(1,2,2);plot(time_logspaced,msd_logspaced_by_t(:,:),'-',tau_cr_t,tau_cr_msdbyt,'-ok')


    % Find ischange points for trapezoid model
%[Nodes,~,~] = ischange(y,'linear','MaxNumChanges',2);

%% 4. Linear Interpolation for Consistent Spacing
fprintf('\nStep 4: Creating linearly spaced interpolation...\n');

% Create linearly spaced time vector for interpolation
n_linear_points = 2000;  % Number of linearly spaced points
time_linear = unique(linspace(time_logspaced(1), time_logspaced(end), n_linear_points))';

% Interpolate MSD values to linear spacing
msd_linear = zeros(n_linear_points, length(p_values));

for p_idx = 1:length(p_values)
    % Use interp1 for smooth interpolation
    msd_linear(:, p_idx) = interp1(time_logspaced, msd_logspaced(:, p_idx), time_linear, 'pchip');
end

fprintf('Interpolated to %d linearly spaced points\n', n_linear_points);
fprintf('Linear time range: %.1f to %.1f steps\n', time_linear(1), time_linear(end));

%% 5. Quality Check and Visualization
fprintf('\nStep 5: Quality check and visualization...\n');

% Check for any NaN or Inf values
nan_count = sum(isnan(msd_linear(:)));
inf_count = sum(isinf(msd_linear(:)));

fprintf('Data quality check:\n');
fprintf('  NaN values: %d\n', nan_count);
fprintf('  Inf values: %d\n', inf_count);

if nan_count > 0 || inf_count > 0
    warning('Data contains NaN or Inf values - interpolation may have issues');
end

%% 6. Create Sample Plots
fprintf('\nStep 6: Creating sample plots...\n');

% Create figure with subplots
figure('Position', [100, 100, 1200, 800]);

% Plot 1: Original vs Log-spaced vs Linear interpolation (for first p-value)
subplot(2, 2, 1);
p_idx = 1;  % First p-value (p = 0)
plot(time_steps(1:1000), msd_values(1:1000, p_idx), 'b-', 'LineWidth', 1, 'DisplayName', 'Original (first 1000 steps)');
hold on;
plot(time_logspaced, msd_logspaced(:, p_idx), 'ro', 'MarkerSize', 4, 'DisplayName', 'Log-spaced');
plot(time_linear, msd_linear(:, p_idx), 'g-', 'LineWidth', 2, 'DisplayName', 'Linear interpolation');
xlabel('Time Step');
ylabel('MSD');
title(sprintf('MSD Comparison for p = %.4f', p_values(p_idx)));
legend('Location', 'best');
grid on;

% Plot 2: Log-spaced time points distribution
subplot(2, 2, 2);
semilogx(time_logspaced, 1:n_log_points, 'bo-', 'LineWidth', 1);
xlabel('Time Step (log scale)');
ylabel('Point Index');
title('Log-spaced Time Point Distribution');
grid on;

% Plot 3: Sample MSD curves for different p-values
subplot(2, 2, 3);
p_indices = [1, 10, 20, 30];  % Sample p-values
colors = {'b', 'r', 'g', 'm'};
for i = 1:length(p_indices)
    p_idx = p_indices(i);
    plot(time_linear, msd_linear(:, p_idx), colors{i}, 'LineWidth', 1.5, ...
         'DisplayName', sprintf('p = %.4f', p_values(p_idx)));
    hold on;
end
xlabel('Time Step');
ylabel('MSD');
title('Sample MSD Curves (Linear Interpolation)');
legend('Location', 'best');
grid on;

% Plot 4: MSD vs p-value at different time points
subplot(2, 2, 4);
time_indices = [1, n_linear_points/4, n_linear_points/2, 3*n_linear_points/4, n_linear_points];
colors = {'b', 'r', 'g', 'm', 'c'};
for i = 1:length(time_indices)
    t_idx = time_indices(i);
    plot(p_values, msd_linear(t_idx, :), colors{i}, 'LineWidth', 1.5, ...
         'DisplayName', sprintf('t = %.0f', time_linear(t_idx)));
    hold on;
end
xlabel('Percolation Parameter p');
ylabel('MSD');
title('MSD vs p at Different Time Points');
legend('Location', 'best');
grid on;

sgtitle('Step 1: MSD Data Import and Transformation', 'FontSize', 16);

%% 7. Save Processed Data
fprintf('\nStep 7: Saving processed data...\n');

% Save the processed data
save('msd_processed_data.mat', 'p_values', 'time_linear', 'msd_linear', ...
     'time_logspaced', 'msd_logspaced', 'n_log_points', 'n_linear_points');

% Also save as CSV for compatibility
% Create table with time as first column
output_table = array2table([time_linear', msd_linear], 'VariableNames', ...
    ['Time', arrayfun(@(x) sprintf('MSD_%.4f', x), p_values, 'UniformOutput', false)]);

writetable(output_table, 'msd_processed_data.csv');

fprintf('Processed data saved to:\n');
fprintf('  - msd_processed_data.mat (MATLAB format)\n');
fprintf('  - msd_processed_data.csv (CSV format)\n');

%% 8. Summary
fprintf('\n=== STEP 1 COMPLETE ===\n');
fprintf('Original data: %d time steps x %d p-values\n', size(msd_values));
fprintf('Log-spaced: %d time points\n', n_log_points);
fprintf('Linear interpolation: %d time points\n', n_linear_points);
fprintf('Time range: %.1f to %.1f steps\n', time_linear(1), time_linear(end));
fprintf('Ready for next step: Local α(ω) analysis\n');

%% 9. Display Key Parameters for Next Steps
fprintf('\nKey parameters for next steps:\n');
fprintf('p-values: %d values from %.4f to %.4f\n', length(p_values), p_values(1), p_values(end));
fprintf('Critical thresholds: p_c ≈ 0.3116, p_c'' ≈ 0.6884\n');
fprintf('Time resolution: %.1f steps between points\n', (time_linear(end) - time_linear(1)) / (n_linear_points - 1));
fprintf('Frequency range: ω ≈ [%.6f, %.6f] (1/time)\n', 1/time_linear(end), 1/time_linear(1));
