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

%load("Clusters/iMacBook_MSD_table_10.mat")
load("Clusters/iMacPro_MSD_table_7.mat")
%load("Clusters/iMacPro_MSD_table_noTemplating_1.mat")


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
N_p = length(p_values_str);
p_values = zeros(1, N_p);
for i = 1:length(p_values_str)
    % Remove 'MSD_' prefix and convert to number
    p_str = strrep(p_values_str{i}, 'MSD_', '');
    p_str = strrep(p_str, '_', '.');
    p_values(i) = str2double(p_str);
end

% Create time vector (0 to 999999)
time_steps = (0:size(msd_values, 1)-1)';

figure(1)
semilogy(time_steps,msd_values,'-');

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

log_time = log10(time_steps);
log_msd = log10(msd_values);
log_msd_by_t = log10((msd_values)./(time_steps));

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

% %% figures
% % fprintf('Interpolated to %d linearly spaced points\n', n_linear_points);
% % fprintf('Linear time range: %.1f to %.1f steps\n', time_linear(1), time_linear(end));
% id_p_lt_pcp = p_values <= 0.55;
% id_p_gt_pcp = p_values >= 0.7;
% id_p_eq_pcp = not(id_p_lt_pcp|id_p_gt_pcp);
% 
% figure(1)
% plot(time_steps,log_msd(:,id_p_lt_pcp),'-');
% % plot(log_time,log_msd(:,id_p_eq_pcp),'-k')
% % plot(log_time,log_msd(:,id_p_gt_pcp),'-r');hold off
% 
% % figure(11);subplot(1,2,1);loglog(time_steps,msd_values);subplot(1,2,2);loglog(time_steps,msd_values./time_steps)
% % figure(12);subplot(1,2,1);plot(log_time,log_msd);subplot(1,2,2);plot(log_time,log_msd_by_t)
% figure(13);subplot(1,2,1);plot(time_logspaced,msd_logspaced);subplot(1,2,2);plot(time_logspaced,msd_logspaced_by_t)
% 
% figure(2);
% subplot(1,3,1);plot(log_time,log_msd_by_t(:,id_p_lt_pcp)-log_msd_by_t(end,id_p_lt_pcp),'-')
% subplot(1,3,2);plot(log_time,log_msd_by_t(:,id_p_eq_pcp)-log_msd_by_t(end,id_p_eq_pcp),'-')
% subplot(1,3,3);plot(log_time,log_msd_by_t(:,id_p_gt_pcp)-log_msd_by_t(end,id_p_gt_pcp),'-')
% figure(3);plot(time_logspaced,msd_logspaced_by_t(:,id_p_lt_pcp)-msd_logspaced_by_t(end,id_p_lt_pcp),'-')
% figure(4);plot(log_time,log_msd)
% 
% %% Save the processed data
% %save('Clusters/MSD_table_3_reduced.mat', 'p_values','time_logspaced', 'msd_logspaced', 'msd_logspaced_by_t');
% colmin = min(msd_logspaced);
% colmax = max(msd_logspaced);
% rs_log_msd = rescale(msd_logspaced,"InputMin",colmin,"InputMax",colmax);
% d_rs_log_msd = gradient(rs_log_msd')';
% 
% figure(4);
% subplot(1,3,1);plot([rs_log_msd(:,1:3),d_rs_log_msd(:,1:3)*500]);grid on
% subplot(1,3,2);plot(rs_log_msd(:,id_p_eq_pcp));grid on
% subplot(1,3,3);plot(rs_log_msd(:,id_p_gt_pcp));grid on
% 
% 
% figure(5);
% subplot(1,3,1);plot(d_rs_log_msd(:,id_p_lt_pcp));grid on
% subplot(1,3,2);plot(d_rs_log_msd(:,id_p_eq_pcp));grid on
% subplot(1,3,3);plot(d_rs_log_msd(:,id_p_gt_pcp));grid on
% 
% 
% colmin = min(msd_logspaced_by_t+0.001);
% colmax = max(msd_logspaced_by_t+0.001);
% rs_log_msd_by_t = rescale(msd_logspaced_by_t,"InputMin",colmin,"InputMax",colmax);
% 
% figure(6);
% subplot(1,3,1);plot(rs_log_msd_by_t(:,id_p_lt_pcp));grid on
% subplot(1,3,2);plot(rs_log_msd_by_t(:,id_p_eq_pcp));grid on
% subplot(1,3,3);plot(rs_log_msd_by_t(:,id_p_gt_pcp));grid on
% 
% 
% d_rs_log_msd_by_t = gradient(rs_log_msd_by_t')';
% 
% figure(7);
% subplot(1,3,1);plot(d_rs_log_msd_by_t(:,id_p_lt_pcp));grid on
% subplot(1,3,2);plot(d_rs_log_msd_by_t(:,id_p_eq_pcp));grid on
% subplot(1,3,3);plot(d_rs_log_msd_by_t(:,id_p_gt_pcp));grid on
% grid on
% 
% % s_11 = sum(d_rs_log_msd(:,id_p_lt_pcp),2);
% % s_12 = sum(d_rs_log_msd(:,id_p_eq_pcp),2);
% % s_13 = sum(d_rs_log_msd(:,id_p_gt_pcp),2);
% % s_2 = sum(d_rs_log_msd_by_t,2);
% % figure(8);
% % subplot(1,3,1);plot(s_1(:,id_p_lt_pcp))
% % subplot(1,3,2);plot(s_1(:,id_p_eq_pcp))
% % subplot(1,3,3);plot(s_1(:,id_p_gt_pcp))
% % figure(9);
% % subplot(1,3,1);plot(s_2(:,id_p_lt_pcp))
% % subplot(1,3,2);plot(s_2(:,id_p_eq_pcp))
% % subplot(1,3,3);plot(s_2(:,id_p_gt_pcp))
% 

%% tau_l



tau_l = zeros(N_p,3);

for ip = 1:N_p
    y = sqrt(msd_values(:,ip));

    tau_l_IDX = find(y>=1,1,"first");
    if ~isempty(tau_l_IDX)

        tau_l(ip,:) = [tau_l_IDX,time_steps(tau_l_IDX),y(tau_l_IDX)];
    end

end
p_values_theory = linspace(0,0.95,39)';
tau_l_theory = 1./(1 - p_values_theory);



%%
p_c_prime_adj = 0.89;
gamma_exponent = 0.61;
p_values_theory = linspace(0, p_c_prime_adj-0.01, 1e3)';
tau_l_theory = 1./(p_c_prime_adj - p_values_theory).^gamma_exponent;
P = [p_c_prime_adj,gamma_exponent];
[~,tau_l_fit] = fit_tau_l(P,p_values,tau_l(:,1));

figure(9);plot(p_values',tau_l_fit,'x',p_values,tau_l(:,1)*0.034+1,'o')

%%
fun = @(a) fit_tau_l(a,p_values',tau_l(:,1)*0.034+1);
a0 = [p_c_prime_adj,gamma_exponent,1,0];
options = optimset('MaxFunEvals',2e4,'MaxIter',2e4);

[a,~,~,~] = fminsearch(fun,a0,options);
a
[~,tau_l_fit] = fit_tau_l(a,p_values',tau_l(:,1));

figure(9);plot(p_values',tau_l_fit,'x',p_values,tau_l(:,1)*0.034+1,'o')

%% 



omega_high = 0.1;
omega_low = 0.0005;
N_omega = 10;

t_high = 1/omega_low;
t_low = 1/omega_high;
x = time_logspaced;


window_size_t = linspace(t_low,t_high,N_omega);

alpha_p_omega = zeros(N_p,N_omega);

for ip = 1:N_p
    y = smooth(msd_logspaced(:,ip),11);

    parfor iw = 1:numel(window_size_t)
    

        dybydx = gradient(y,0.0030015);

        dydx = movmean(dybydx,window_size_t(iw));
 
        id_x = x > 3;

        local_alpha = abs(median(dydx(id_x)))

        alpha_p_omega(ip,iw) = local_alpha;

        % figure(5);
        % subplot(2,1,1);plot(t,y);legend
        % subplot(2,1,2);plot(t,[dybydx,dydx]);legend

    end

    % z = y - y(end,:);
    % dz = movmean(gradient(z),11);
    % 
    % if ii > 1
    %     id_z2 = find(dz>0& t > 2,1,"first");
    % else
    %     id_z2 = find(dz<0 & t > 1.5,1,"first");
    % end


end
%%
figure(6);
plot(p_values,alpha_p_omega);legend;grid on

[mn,imn] = min(abs(alpha_p_omega-0.5));
p_values(imn)-0.6884

%% tau_cr



t = time_logspaced;
tau_cr_Idx = nan(N_p,1);
tau_cr_msd = nan(N_p,1);
tau_cr_msdbyt = nan(N_p,1);
tau_cr_t = nan(N_p,1);
omega_high = 0.1;
omega_low = 0.001

t_high = 1/omega_low;
t_low = 1/omega_high;

window_size_t = linspace()

for ip = 1%:N_p

    x = msd_logspaced(:,ip);
    y = msd_logspaced_by_t(:,ip);
    z = y - y(end,:);
    dz = movmean(gradient(z),11);

    if ip > 1
        id_z2 = find(dz>0& t > 2,1,"first");
    else
        id_z2 = find(dz<0 & t > 1.5,1,"first");
    end

    figure(5);subplot(2,1,1);plot(t,dz*1000,t,z,t(id_z2),z(id_z2),'ok');legend

    if ~isempty(id_z2)
        tau_cr_msdbyt(ip) = msd_logspaced_by_t(id_z2,ip);
        tau_cr_msd(ip) = msd_logspaced(id_z2,ip);
        tau_cr_t(ip) = t(id_z2);
        tau_cr_Idx(ip) = id_z2;
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
