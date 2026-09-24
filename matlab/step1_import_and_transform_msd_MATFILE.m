%% Step 1: Import MSD Data and Transform to Logspace
% This script imports the MSD data from 'p_output_NEW34.csv' and
% transforms it to logspace with linear interpolation for consistent analysis

clear; clc; close all; format short g

%% 1. Import MSD Data
fprintf('Step 1: Importing MSD data...\n');

% % Define file path
% data_file = 'Clusters/p_output_C1.csv';
% 
% % Check if file exists
% if ~exist(data_file, 'file')
%     error('Data file not found: %s', data_file);
% end
% 
% % Import data
% fprintf('Loading CSV file (this may take a moment for large files)...\n');
% msd_data = readtable(data_file);
% 
% % Extract column names (p-values) and MSD values
% p_values_str = msd_data.Properties.VariableNames;
% msd_values = table2array(msd_data);
% 
% % Convert p-values from strings to numbers
% p_values = zeros(1, length(p_values_str));
% for i = 1:length(p_values_str)
%     % Remove 'MSD_' prefix and convert to number
%     p_str = strrep(p_values_str{i}, 'MSD_', '');
%     p_str = strrep(p_str, '_', '.');
%     p_values(i) = str2double(p_str);
% end
% 
% % Create time vector (0 to 999999)
% time_steps = (0:size(msd_values, 1)-1)';
% 
% fprintf('Data loaded successfully!\n');
% fprintf('Number of time steps: %d\n', length(time_steps));
% fprintf('Number of p-values: %d\n', length(p_values));
% fprintf('Data size: %d x %d\n', size(msd_values));

load("msd_processed_data.mat")


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
fprintf('Time range: %d to %d steps\n', time_linear(1), time_linear(end));

%% 3. Transform to Logspace
fprintf('\nStep 3: Transforming to logspace...\n');

% % Create log-spaced time vector
% % We want to focus on the meaningful range (avoid t=0 and very early times)
% log_time_startIDX = 1;  % Start from step 1 to avoid log(0)
% log_time_endIDX = length(time_steps) - 1;  % End at step 999999
% 
% time_steps = (1:length(msd_values))';
% 
% log_time = log10(time_steps+1);
% log_msd = log10(msd_values+1);
% log_msd_by_t = log10((msd_values+1)./(time_steps+1));
% 
% % Create log-spaced time points
% n_log_points = 1000;  % Number of log-spaced points
% 
% % Extract MSD values at log-spaced time points
% msd_logspaced = zeros(n_log_points, length(p_values));
% msd_logspaced_by_t = zeros(n_log_points, length(p_values));
% time_logspaced = linspace(min(log_time),max(log_time),n_log_points)';
% 
% 
% for p_idx = 1:length(p_values)
%     % Use interp1 for smooth interpolation
%     msd_logspaced(:, p_idx) = interp1(log_time, log_msd(:, p_idx), time_logspaced, 'pchip');
%     msd_logspaced_by_t(:, p_idx) = interp1(log_time, log_msd_by_t(:, p_idx), time_logspaced, 'pchip');
% end
% 
% % fprintf('Interpolated to %d linearly spaced points\n', n_linear_points);
% % fprintf('Linear time range: %.1f to %.1f steps\n', time_linear(1), time_linear(end));

msd_linear_by_t = msd_linear./time_linear;
dmsd_linear_by_t = gradient(msd_linear_by_t')';
figure(1);plot(time_linear,msd_linear,'-')
figure(2);plot(time_linear,msd_linear_by_t(:,1:3),'-',time_linear,dmsd_linear_by_t(:,1:3)*100);legend

figure(3);plot(time_linear,dmsd_linear_by_t,'-');legend
% figure(2);plot(log_time,log_msd_by_t(:,1:20)-log_msd_by_t(end,1:20),'-')
% figure(4);plot(time_logspaced,msd_logspaced,'-');
% msd_logspaced_by_t = msd_logspaced./ time_logspaced;
% figure(5);plot(time_logspaced,msd_logspaced_by_t(:,1:20)-msd_logspaced_by_t(end,1:20),'-')


%%

t = time_linear;

for ii = 3
    y = msd_linear_by_t(:,ii);
    z = y - y(end,:);
    dz = movmean(gradient(z));
    if ii > 1
        id_z2 = find(dz>0& t > 2,1,"first");
    else
        id_z2 = find(dz<0 & t > 1,1,"first");
    end
    figure(3);plot(t,dz*1000,t,z,t(id_z2),z(id_z2),'ok');legend


    id_z1 = abs(z) < 0.03 & t > 3;
    %id_z2 = abs(z) < 0.03 & t > 3;

    a = t(id_z1)\z(id_z1);

    pf = polyfit(t(id_z1),z(id_z1),1);
    pv_z = polyval(pf,t);




    fun = @(a) fit_linear_region(a,t(id_z1),z(id_z1));
    a0 = [1,0.1];
    [af,~,~,~] = fminsearch(fun,a0);
    [~,z_fit] = fit_linear_region(af,t,z);

    % find roots
    [~,r1_IDX] = min(abs(z - z_fit));

    figure(4);plot(t,z,'.-',t,pv_z,'--',t,pv_z,'-',t,z_fit,'-',t(r1_IDX),z_fit(r1_IDX),'ro',t(id_z2),z(id_z2),'ok');legend
end

    % Find ischange points for trapezoid model
%[Nodes,~,~] = ischange(y,'linear','MaxNumChanges',2);


% %% 8. Summary
% fprintf('\n=== STEP 1 COMPLETE ===\n');
% fprintf('Original data: %d time steps x %d p-values\n', size(msd_values));
% fprintf('Log-spaced: %d time points\n', n_log_points);
% fprintf('Linear interpolation: %d time points\n', n_linear_points);
% fprintf('Time range: %.1f to %.1f steps\n', time_linear(1), time_linear(end));
% fprintf('Ready for next step: Local α(ω) analysis\n');
% 
% %% 9. Display Key Parameters for Next Steps
% fprintf('\nKey parameters for next steps:\n');
% fprintf('p-values: %d values from %.4f to %.4f\n', length(p_values), p_values(1), p_values(end));
% fprintf('Critical thresholds: p_c ≈ 0.3116, p_c'' ≈ 0.6884\n');
% fprintf('Time resolution: %.1f steps between points\n', (time_linear(end) - time_linear(1)) / (n_linear_points - 1));
% fprintf('Frequency range: ω ≈ [%.6f, %.6f] (1/time)\n', 1/time_linear(end), 1/time_linear(1));
