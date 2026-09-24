%% MATLAB Code for Mapping Percolation to Gelation Kinetics
% This script transforms loss tangent data from percolation probability (p)
% to time (t) domain using the relationship: p(t) = p_∞(1-e^(-kt))

% Clear workspace
clear; clc; close all;

%% get data for figure

N = 100000;

N = 100000;
Nc = 3;

x_data = zeros(N,Nc,4);
y_data = zeros(N,Nc,4);

for loop = 1:4

    switch loop
        case 1
            fig_file = 'GPrG2Pr0_7.fig';
        case 2
            fig_file = 'GPrG2Pr0_74.fig';
        case 3
            fig_file = 'GPrG2Pr0_78.fig';
        case 4
            fig_file = 'GPrG2Pr0_82.fig';
    end

    fig = openfig(fig_file);
    datObj = findobj(fig,'-property','XData')

    dims = size(datObj);

    for idx = 1:dims(1)
        L = length(datObj(idx).XData);
        Lidx = 1:L;

        x_data(Lidx,idx,loop) = datObj(idx).XData';
        y_data(Lidx,idx,loop) = datObj(idx).YData';
    end

    close all


end

%% Percolation

% Create figure

hFig = figure( 6 ); set( hFig, 'Position', [100 100 1000 1000], 'Name', 'G''G''');
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
idx = 1;
str = 'a';
p_value = [0.7,0.74,0.78,0.82]
for loop = 1:4

    subplot(2,2,loop)
    loglog(x_data(:,3,loop),y_data(:,3,loop),'-','LineWidth',2.0,'Color',colors{idx});hold on
    loglog(x_data(:,2,loop),y_data(:,2,loop),'--','LineWidth',2.0,'Color',colors{idx+1});hold on
    %loglog([x_gp(end,loop),x_gp(end,loop)],[1e-4,1],'--k','LineWidth',2.0);hold on
    loglog(x_data(:,1,loop),y_data(:,1,loop),':k','LineWidth',2.0);hold off
    axis([1e-4,2e2,1e-4,1]);grid on
    text(1e-3, 0.5, sprintf('(%s)',char(str+loop-1)), 'FontSize', 22);
    text(1, 1e-3, strcat('$p$',sprintf(' = %0.2f',p_value(loop))), 'FontSize', 22,'Interpreter','latex');
    xticks(logspace(-4,2,4))
    yticks(logspace(-4,0,5))

    set(gca, 'FontSize', 18);

    %($\sigma_\eta$)

    if loop == 3
        ylabel('$G^{''}(\omega),G^{''''}(\omega)\phantom{00}(Pa)$','FontSize',24,'Interpreter','latex','Position',[0.00001,5])
        xlabel('$\omega\phantom{00}(rad/s)$','FontSize',24,'Interpreter','latex','Position',[400,0.00003])
    elseif loop == 4
        legend('$G^{''}(\omega)$','$G^{''''}(\omega)$','FontSize',20,'Location','west','Interpreter','latex');legend box off

    end
end
hold off



