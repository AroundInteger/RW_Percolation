function analyze_FSS()
% analyze_FSS.m
%
% Analyses the finite-size scaling output of RW3D_FSS_study.m.
%
% For each growth condition it:
%   (1) averages alpha(p,L) over seeds and locates the gel-point p_c'(L) by
%       linear interpolation of alpha through 0.5 (delta = 45 deg), mirroring
%       analyze_kappa_gel_points.m;
%   (2) estimates the correlation-length exponent nu THREE independent ways:
%         (a) threshold-shift fit   p_c'(L) = p_c'(inf) + a * L^(-1/nu)
%             (robust nu grid-search; linear in p_c'(inf), a at fixed nu)
%         (b) transition-width fit  w(L) ~ L^(-1/nu_w)   (log-log slope)
%             where w(L) is the logistic width of alpha(p) at size L
%         (c) best data collapse    alpha vs (p - p_c'(inf)) * L^(1/nu_c);
%   (3) assembles nu(kappa) along the kappa line and reports the templated
%       class separately.
%
% Outputs:
%   FSS_study/fss_pcL_table.csv     p_c'(L) and width w(L) per (condition,L)
%   FSS_study/fss_nu_summary.csv    p_c'(inf), nu_shift, nu_width, nu_collapse
%   FSS_study/fss_pcL_fits.png      p_c'(L) vs L^(-1/nu) with fits
%   FSS_study/fss_nu_of_kappa.png   nu(kappa) with error bars + collapses
%
% Usage:  >> analyze_FSS
%
% NOTE on the Eden limit (kappa = 1): this is a single connected cluster with
% p_c' -> 1 as L -> inf and is NOT a conventional critical point; its "nu"
% is reported for completeness but should be treated as a bound, not a
% universality-class exponent (see the paper's methods/discussion).

GEL = 0.5;                       % alpha at gel-point
NU_GRID = 0.40:0.005:1.60;       % search range for the shift-fit exponent

root = fullfile(fileparts(mfilename('fullpath')), '..', 'matlab', 'FSS_study');
csv  = fullfile(root, 'fss_alpha_table.csv');
assert(exist(csv,'file')==2, 'Missing %s — run RW3D_FSS_study first.', csv);
T = readtable(csv);
if iscell(T.condition), T.condition = string(T.condition); else, T.condition = string(T.condition); end

conds = unique(T.condition, 'stable');
Lall  = unique(T.L);

% ---- per-(condition,L): mean alpha(p), p_c'(L), width w(L) ----
rows = struct('condition',{},'kappa',{},'L',{},'pcL',{},'p_lo',{},'p_hi',{}, ...
              'width',{},'nfit',{});
curves = struct();   % curves.(safe(cond)).(safe L) = [p alpha]

for ci = 1:numel(conds)
    cond = conds(ci);
    sc   = T(T.condition==cond, :);
    kap  = sc.kappa(1);
    for L = Lall(:)'
        s = sc(sc.L==L, :);
        if isempty(s); continue; end
        pu = unique(s.p);
        am = arrayfun(@(pp) mean(s.alpha(s.p==pp),'omitnan'), pu);
        good = isfinite(am);
        pu = pu(good); am = am(good);
        if numel(pu) < 4; continue; end
        curves.(sc_safe(cond)).(sprintf('L%d',L)) = [pu am];

        % gel-point: first downward crossing of alpha=0.5 for p>0.5
        m  = pu > 0.5;
        pm = pu(m); ac = am(m);
        [pcL, plo, phi] = cross_interp(pm, ac, GEL);

        % logistic width w: alpha = amin + (amax-amin)/(1+exp((p-pc)/w))
        w = fit_logistic_width(pm, ac, pcL);

        rows(end+1) = struct('condition',cond,'kappa',kap,'L',L,'pcL',pcL, ...
            'p_lo',plo,'p_hi',phi,'width',w,'nfit',numel(pm)); %#ok<AGROW>
    end
end
R = struct2table(rows);
writetable(R, fullfile(root,'fss_pcL_table.csv'));

% ---- per-condition FSS fits ----
summ = struct('condition',{},'kappa',{},'pc_inf',{},'a',{},'nu_shift',{}, ...
              'nu_width',{},'nu_collapse',{},'nL',{},'note',{});
figure('Name','p_c''(L) fits','Position',[80 80 900 620]); hold on;
cmap = lines(numel(conds));

for ci = 1:numel(conds)
    cond = conds(ci);
    kap = T.kappa(find(T.condition==cond, 1));   % robust: T always has this condition
    r = R(R.condition==cond & isfinite(R.pcL), :);
    note = '';
    if height(r) < 3
        summ(end+1) = struct('condition',cond,'kappa',kap,'pc_inf',NaN,'a',NaN, ...
            'nu_shift',NaN,'nu_width',NaN,'nu_collapse',NaN,'nL',height(r), ...
            'note','too few L with a crossing'); %#ok<AGROW>
        continue;
    end
    L = r.L(:); pc = r.pcL(:);

    % (a) shift-fit nu via grid search (linear in pc_inf, a at fixed nu)
    bestSSE = inf; nu_shift = NaN; pc_inf = NaN; aamp = NaN;
    for nu = NU_GRID
        x = L.^(-1/nu);
        A = [ones(numel(x),1), x];
        b = A \ pc;                       % [pc_inf; a]
        sse = sum((pc - A*b).^2);
        if sse < bestSSE
            bestSSE = sse; nu_shift = nu; pc_inf = b(1); aamp = b(2);
        end
    end

    % (b) width-scaling nu_w: log w = const - (1/nu_w) log L
    rw = r(isfinite(r.width) & r.width>0, :);
    if height(rw) >= 3
        pf = polyfit(log(rw.L), log(rw.width), 1);
        nu_width = -1/pf(1);
    else
        nu_width = NaN;
    end

    % (c) collapse nu_c: minimise spread of alpha vs x=(p-pc_inf) L^(1/nu)
    scf = sc_safe(cond);
    if isfield(curves, scf)
        nu_collapse = collapse_nu(curves.(scf), pc_inf, NU_GRID);
    else
        nu_collapse = NaN;
    end

    if kap==1, note = 'Eden limit: pc_inf->1; nu is a bound, not a class exponent'; end

    summ(end+1) = struct('condition',cond,'kappa',kap,'pc_inf',pc_inf,'a',aamp, ...
        'nu_shift',nu_shift,'nu_width',nu_width,'nu_collapse',nu_collapse, ...
        'nL',height(r),'note',note); %#ok<AGROW>

    % plot pc'(L) vs L^(-1/nu_shift) with fit line
    x = L.^(-1/nu_shift);
    plot(x, pc, 'o', 'Color', cmap(ci,:), 'MarkerFaceColor', cmap(ci,:), ...
        'DisplayName', sprintf('%s (\\nu=%.2f)', cond, nu_shift));
    xf = linspace(0, max(x)*1.05, 50);
    plot(xf, pc_inf + aamp*xf, '-', 'Color', cmap(ci,:), 'HandleVisibility','off');
end
xlabel('L^{-1/\nu}'); ylabel('p_c''(L)');
title('Finite-size scaling of the gel-point'); legend('Location','best'); box on; grid on;
saveas(gcf, fullfile(root,'fss_pcL_fits.png'));

S = struct2table(summ);
writetable(S, fullfile(root,'fss_nu_summary.csv'));

% ---- nu(kappa) figure (kappa-line conditions only) ----
kl = S(~isnan(S.kappa) & S.kappa>=0 & S.kappa<=1 & startsWith(S.condition,'k'), :);
kl = sortrows(kl, 'kappa');
if height(kl) >= 2
    figure('Name','nu(kappa)','Position',[80 80 760 520]); hold on;
    nu_mat = [kl.nu_shift, kl.nu_width, kl.nu_collapse];
    nu_mean = mean(nu_mat, 2, 'omitnan');
    nu_std  = std(nu_mat, 0, 2, 'omitnan');
    errorbar(kl.kappa, nu_mean, nu_std, 'o-', 'LineWidth', 1.5, 'MarkerFaceColor','auto');
    yline(0.88, '--', '\nu \approx 0.88 (3D percolation)', 'LabelHorizontalAlignment','left');
    xlabel('\kappa (nucleation-density parameter)'); ylabel('\nu (mean of 3 estimators)');
    title('Correlation-length exponent along the \kappa line'); box on; grid on;
    saveas(gcf, fullfile(root,'fss_nu_of_kappa.png'));
end

% ---- console summary ----
fprintf('\n=== FSS SUMMARY ===\n');
disp(S);
fprintf(['Interpretation guide:\n' ...
    '  - Random (k0p00) nu_shift should sit near 0.88 (3D percolation) as a sanity check.\n' ...
    '  - Two classes?  Compare k0p00 vs templ6N nu across all three estimators.\n' ...
    '  - nu(kappa) flat  -> one class, tunable non-universal threshold (story A).\n' ...
    '  - nu(kappa) sloped -> kappa-dependent exponents (story B) — demand tight agreement\n' ...
    '    of the three estimators before claiming this.\n' ...
    '  - k1p00 (Eden): treat as a bound, not a class exponent.\n' ...
    '  - If any p_c''(L) hits a window edge (p_lo/p_hi in fss_pcL_table.csv), widen that\n' ...
    '    condition''s win in RW3D_FSS_study.m and re-run that condition.\n']);
end

% =========================================================================
% helpers
% =========================================================================
function [pc, plo, phi] = cross_interp(p, a, thr)
    pc = NaN; plo = NaN; phi = NaN;
    idx = find(diff(sign(a - thr)) < 0, 1, 'first');   % downward crossing
    if isempty(idx); return; end
    dp = p(idx+1)-p(idx); da = a(idx+1)-a(idx);
    if da == 0; return; end
    pc  = p(idx) + (thr - a(idx))*dp/da;
    plo = p(idx); phi = p(idx+1);
end

function w = fit_logistic_width(p, a, pc0)
    % logistic: a = amin + (amax-amin)/(1+exp((p-pc)/w)); return |w|
    w = NaN;
    if numel(p) < 4 || ~isfinite(pc0); return; end
    amin0 = min(a); amax0 = max(a); w0 = 0.03;
    f = @(q) q(1) + (q(2)-q(1))./(1+exp((p - q(3))./q(4)));
    obj = @(q) sum((f(q) - a).^2);
    try
        opt = optimset('Display','off','MaxFunEvals',4000,'MaxIter',4000);
        q = fminsearch(obj, [amin0, amax0, pc0, w0], opt);
        w = abs(q(4));
        if w > 1 || w <= 0; w = NaN; end        % reject nonsensical fits
    catch
        w = NaN;
    end
end

function nu = collapse_nu(Lstruct, pc_inf, NU_GRID)
    % Best-collapse nu: bin the scaling variable x=(p-pc_inf)L^(1/nu) and
    % minimise the mean within-bin variance of alpha across sizes.
    nu = NaN;
    if ~isfinite(pc_inf); return; end
    fn = fieldnames(Lstruct);
    if numel(fn) < 3; return; end
    bestV = inf;
    for nut = NU_GRID
        X = []; A = [];
        for i = 1:numel(fn)
            L = sscanf(fn{i}, 'L%d');
            pa = Lstruct.(fn{i});
            p = pa(:,1); a = pa(:,2);
            m = p > 0.5 & isfinite(a);
            X = [X; (p(m)-pc_inf)*L^(1/nut)]; %#ok<AGROW>
            A = [A; a(m)];                    %#ok<AGROW>
        end
        if numel(X) < 12; continue; end
        edges = linspace(min(X), max(X), 15);
        [~,~,bin] = histcounts(X, edges);
        v = 0; n = 0;
        for b = 1:numel(edges)-1
            aa = A(bin==b);
            if numel(aa) >= 2; v = v + var(aa)*numel(aa); n = n + numel(aa); end
        end
        if n > 0
            v = v/n;
            if v < bestV; bestV = v; nu = nut; end
        end
    end
end

function s = sc_safe(cond)
    s = char(cond); s(~isstrprop(s,'alphanum')) = '_';
    if isempty(s) || ~isstrprop(s(1),'alpha'); s = ['c' s]; end
end
