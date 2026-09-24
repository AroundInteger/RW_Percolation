clear; close all;

%%
load('percolation_comparison_results.mat')%%

r = results;
%%
r.validation_metrics
%% Plots

hold on
for loop = 1:2

figure(1);loglog(r(loop).t,[r(loop).msd_raw,r(loop).msd_lag_averaged],'-')
figure(2);plot(r(loop).gser_results.omega,[r(loop).gser_results.G_prime,r(loop).gser_results.G_double_prime],'-')
figure(2);plot(r(loop).p,[r(loop).gser_results.G_prime,r(loop).gser_results.G_double_prime],'-')

end
hold off