%% MATLAB Code for Mapping Percolation to Gelation Kinetics
% This script transforms loss tangent data from percolation probability (p)
% to time (t) domain using the relationship: p(t) = p_∞(1-e^(-kt))

% Clear workspace
clear; clc; close all;

%% get data for figure

N = 100000;
Nc = 5;

x_data = zeros(N,Nc,4);
y_data = zeros(N,Nc,4);

for loop = 1:4

    switch loop
        case 1
            fig_file = 'GPrPGrPc3D_01_b.fig';
        case 2
            fig_file = 'GPrPGrPc3D_035_b.fig';
        case 3
            fig_file = 'GPrPGrPc3D_05_b.fig';
        case 4
            fig_file = 'GPrPGrPc3D_065_b.fig';
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

hFig = figure( 2 ); set( hFig, 'Position', [100 100 1000 1000], 'Name', ' G'' G" ');
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
p_value = [0.1,0.35,0.5,0.65];
for loop = 1:4

    %lk1 = x_gpp(1,loop);lk2 = x_gpp(end,loop);
    subplot(2,2,loop)
    loglog(x_data(:,4,loop),y_data(:,4,loop),'-','LineWidth',2.0,'Color',colors{idx});hold on       %G'
    loglog(x_data(:,5,loop),y_data(:,5,loop),'--','LineWidth',2.0,'Color',colors{idx+1});hold on    %G''
    %loglog([x_gp(end,loop),x_gp(end,loop)],[1e-4,1],'--k','LineWidth',2.0);hold on
    loglog(x_data(:,3,loop),y_data(:,3,loop),':k^','LineWidth',2.0,'MarkerFaceColor','k','MarkerSize',10);hold on                         %G' Triangle on MSD
    if loop > 2
    loglog(x_data(:,2,loop),y_data(:,2,loop),'-.','LineWidth',2.0,'Color',colors{5});hold on        %G'
    end
    %loglog(x_data(:,1,loop),y_data(:,1,loop),'-.','LineWidth',2.0,'Color',colors{7});hold off
    loglog(x_data(:,1,loop),y_data(:,1,loop),'--.m','LineWidth',2.0);hold off       %G'
    axis([1e-3,1.01e3,1e-6,1]);grid on
    text(5e-3, 0.45, sprintf('(%s)',char(str+loop-1)), 'FontSize', 22);
    text(1.5e-2, 1e-5, strcat('$p$',sprintf(' = %0.2f',p_value(loop))), 'FontSize', 22,'Interpreter','latex');
    xticks(logspace(-3,3,7))
    yticks(logspace(-6,0,4))

    set(gca, 'FontSize', 18);

    %($\sigma_\eta$)

    if loop == 3
        ylabel('$G^{''}(\omega),G^{''''}(\omega)\phantom{00}(Pa)$','FontSize',24,'Interpreter','latex','Position',[0.0001,10])
        xlabel('$\omega\phantom{00}(rad/s)$','FontSize',24,'Interpreter','latex','Position',[3000,2e-7])
    elseif loop == 4
        legend('$G^{''}(\omega)$','$G^{''''}(\omega)$','FontSize',20,'Location','east','Interpreter','latex');legend box off

    end
end
hold off






% Save the figure
% saveas(gcf, sprintf('%s_time_mapping.png', strrep(filename, '.csv', '')));
% saveas(gcf, sprintf('%s_time_mapping.fig', strrep(filename, '.csv', '')));



