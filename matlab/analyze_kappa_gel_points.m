% analyze_kappa_gel_points.m
%
% Loads the alpha table produced by RW3D_kappa_mixing_study.m, extracts
% the gel-point p_c'(kappa) for each kappa via linear interpolation of
% alpha through 0.5 (delta = 45 deg), and plots the tunable gel-point
% curve.  Also saves a summary CSV.
%
% Run this after RW3D_kappa_mixing_study.m has completed.
%
% Usage:
%   >> analyze_kappa_gel_points          % auto-detects L from quick run
%   >> analyze_kappa_gel_points('production')

function analyze_kappa_gel_points(mode)

if nargin < 1, mode = 'quick'; end

switch mode
    case 'quick';      L = 100;
    case 'production'; L = 500;
    otherwise;         L = 100;
end

BASE_DIR = fullfile(fileparts(mfilename('fullpath')), '..', ...
    'matlab', 'Clusters_kappa', sprintf('L%d', L));

csv_file = fullfile(BASE_DIR, 'kappa_study_alpha_table.csv');
if ~exist(csv_file, 'file')
    error('Cannot find %s.\nRun RW3D_kappa_mixing_study.m first.', csv_file);
end

T = readtable(csv_file);

% Average over seeds
kappa_vals = unique(T.kappa);
p_vals     = unique(T.p_value);

% =========================================================================
% EXTRACT GEL-POINTS VIA INTERPOLATION (alpha = 0.5 crossing)
% =========================================================================
GEL_THRESHOLD = 0.5;    % alpha at gel-point (delta = 45 deg)

gel_points   = NaN(numel(kappa_vals), 1);
gel_p_lo     = NaN(numel(kappa_vals), 1);   % bracket lower bound
gel_p_hi     = NaN(numel(kappa_vals), 1);   % bracket upper bound
alpha_curves = cell(numel(kappa_vals), 1);

fprintf('\n=== GEL-POINT EXTRACTION (alpha = 0.5 criterion) ===\n\n');
fprintf('%-10s  %-10s  %-10s  %-10s  %-10s\n', ...
    'kappa', 'p_c'' (gel)', 'p_lo', 'p_hi', 'bracket width');
fprintf('%s\n', repmat('-', 1, 60));

for ki = 1:numel(kappa_vals)
    kappa = kappa_vals(ki);
    sub   = T(T.kappa == kappa, :);

    % Mean alpha per p (across seeds)
    p_unique   = unique(sub.p_value);
    alpha_mean = zeros(numel(p_unique), 1);
    for pj = 1:numel(p_unique)
        rows = sub.p_value == p_unique(pj);
        alpha_mean(pj) = mean(sub.alpha(rows), 'omitnan');
    end

    alpha_curves{ki} = struct('p', p_unique, 'alpha', alpha_mean);

    % Find crossing: only consider p > 0.5 to avoid any early-time artefacts
    mask = p_unique > 0.5 & isfinite(alpha_mean);
    p_m  = p_unique(mask);
    a_m  = alpha_mean(mask);

    % Need alpha to be decreasing through GEL_THRESHOLD
    crossings = find(diff(sign(a_m - GEL_THRESHOLD)) < 0);

    if ~isempty(crossings)
        i = crossings(1);
        % Linear interpolation
        dp  = p_m(i+1) - p_m(i);
        da  = a_m(i+1) - a_m(i);
        pc  = p_m(i) + (GEL_THRESHOLD - a_m(i)) * dp / da;
        gel_points(ki)   = pc;
        gel_p_lo(ki)     = p_m(i);
        gel_p_hi(ki)     = p_m(i+1);
        bracket          = p_m(i+1) - p_m(i);
        fprintf('%-10.4f  %-10.4f  %-10.4f  %-10.4f  %-10.4f\n', ...
            kappa, pc, p_m(i), p_m(i+1), bracket);
    else
        fprintf('%-10.4f  %-10s  (no crossing of alpha=0.5 found)\n', ...
            kappa, 'N/A');
    end
end

fprintf('\n');

% Tunable range summary
valid = isfinite(gel_points);
if sum(valid) >= 2
    pc_min = min(gel_points(valid));
    pc_max = max(gel_points(valid));
    fprintf('Tunable range: p_c'' in [%.4f, %.4f],  Delta p_c'' = %.4f\n\n', ...
        pc_min, pc_max, pc_max - pc_min);
end

% =========================================================================
% SAVE SUMMARY
% =========================================================================
summary = table(kappa_vals, gel_points, gel_p_lo, gel_p_hi, ...
    'VariableNames', {'kappa', 'gel_point_pc_prime', 'bracket_lo', 'bracket_hi'});

out_csv = fullfile(BASE_DIR, 'kappa_gel_point_summary.csv');
writetable(summary, out_csv);
fprintf('Summary saved: %s\n', out_csv);

% =========================================================================
% FIGURES
% =========================================================================
colors = lines(numel(kappa_vals));
fig_dir = BASE_DIR;

% --- Figure 1: alpha vs p for all kappa ---
fig1 = figure('Position', [50, 50, 1100, 500], 'Name', 'Alpha vs p by kappa');
ax1  = axes(fig1);
hold(ax1, 'on');

for ki = 1:numel(kappa_vals)
    c = alpha_curves{ki};
    plot(ax1, c.p, c.alpha, 'o-', 'Color', colors(ki,:), ...
        'LineWidth', 1.8, 'MarkerSize', 5, ...
        'DisplayName', sprintf('\\kappa = %.2f', kappa_vals(ki)));
    if isfinite(gel_points(ki))
        xline(ax1, gel_points(ki), '--', 'Color', colors(ki,:), ...
            'LineWidth', 1.2, 'HandleVisibility', 'off');
    end
end

yline(ax1, GEL_THRESHOLD, 'k-', 'LineWidth', 1.5, ...
    'DisplayName', '\alpha = 0.5 (gel-point criterion)');
xlabel(ax1, 'Occupation probability  p', 'FontSize', 12);
ylabel(ax1, 'Diffusion exponent  \alpha', 'FontSize', 12);
title(ax1, '\alpha(p) for each \kappa  (dashed verticals = gel-points)', 'FontSize', 13);
legend(ax1, 'Location', 'southwest', 'FontSize', 10);
xlim(ax1, [0, 1]);  ylim(ax1, [-0.1, 1.15]);
grid(ax1, 'on');
set(ax1, 'GridAlpha', 0.3);

saveas(fig1, fullfile(fig_dir, 'kappa_alpha_vs_p.png'));
fprintf('Figure saved: kappa_alpha_vs_p.png\n');

% --- Figure 2: p_c'(kappa) — the key tunable gel-point curve ---
valid_ki = find(isfinite(gel_points));

if numel(valid_ki) >= 2
    fig2 = figure('Position', [200, 200, 600, 500], 'Name', 'Tunable gel-point');
    ax2  = axes(fig2);
    hold(ax2, 'on');

    % Plot gel-points
    plot(ax2, kappa_vals(valid_ki), gel_points(valid_ki), ...
        'ko-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'k');

    % Shade bracket uncertainty
    for ki = valid_ki'
        fill(ax2, kappa_vals([ki,ki]), [gel_p_lo(ki), gel_p_hi(ki)], ...
            [0.5 0.5 0.5], 'FaceAlpha', 0.25, 'EdgeColor', 'none', ...
            'HandleVisibility', 'off');
    end

    % Reference lines for known endpoints
    yline(ax2, 0.6884, '--', 'Color', [0.2 0.5 0.9], 'LineWidth', 1.5, ...
        'DisplayName', 'Random percolation  p_c''\approx0.688');
    yline(ax2, 0.886,  '--', 'Color', [0.9 0.2 0.2], 'LineWidth', 1.5, ...
        'DisplayName', 'Templated  p_c''\approx0.886');

    xlabel(ax2, 'Templating fraction  \kappa', 'FontSize', 13);
    ylabel(ax2, 'Gel-point  p_c''(\kappa)',   'FontSize', 13);
    title(ax2, 'Tunable gel-point positioning', 'FontSize', 14, 'FontWeight', 'bold');
    legend(ax2, 'Location', 'northwest', 'FontSize', 10);
    xlim(ax2, [-0.05, 1.05]);
    ylim(ax2, [0.60, 0.95]);
    grid(ax2, 'on');  set(ax2, 'GridAlpha', 0.3);

    saveas(fig2, fullfile(fig_dir, 'kappa_gel_point_curve.png'));
    fprintf('Figure saved: kappa_gel_point_curve.png\n');
end

fprintf('\nDone.\n');
end
