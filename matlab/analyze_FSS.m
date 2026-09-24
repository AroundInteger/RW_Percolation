function analyze_FSS()
% analyze_FSS.m  (v2 — robust exponents)
%
% Analyses the finite-size-scaling output of RW3D_FSS_study.m.
%
% Per growth condition it (1) averages alpha(p,L) over seeds and locates the
% gel-point p_c'(L) by interpolating alpha through 0.5, and the logistic
% transition width w(L); then (2) estimates the correlation-length exponent nu
% from the LARGE sizes only (L >= LMIN_FIT — the two smallest sizes carry the
% strongest corrections-to-scaling and are dropped from the fits), three ways:
%     (a) threshold-shift  p_c'(L) = p_c'(inf) + a L^(-1/nu)   [+ jackknife CI]
%     (b) width scaling    w(L) ~ L^(-1/nu_w)                  [+ jackknife CI]
%     (c) data collapse    master-curve fit of alpha vs (p-p_c'(inf))L^(1/nu),
%         with the residual measured in ALPHA space (bounded 0..1) so that
%         stretching the x-axis cannot spuriously improve the score.
% It also runs a FIXED-nu test: for nu in NU_FIXED it does the 2-parameter fit
% and reports p_c'(inf) and R^2, so you can see directly whether the data prefer
% nu = 0.88 (3D percolation) or a different effective exponent.
%
% Outputs (matlab/FSS_study/):
%   fss_pcL_table.csv    p_c'(L), width w(L) per (condition,L)  [ALL sizes]
%   fss_nu_summary.csv   pc_inf, nu_shift(+CI), nu_width(+CI), nu_collapse,
%                        and the fixed-nu (0.88 / 1.50) pc_inf & R^2
%   fss_pcL_fits.png     p_c'(L) vs L^(-1/nu_shift) with fits (fit sizes filled)
%   fss_nu_of_kappa.png  nu(kappa): shift & width estimators with jackknife bars
%
% Usage:  >> analyze_FSS
%
% NOTE: k1p00 (Eden) has p_c' -> 1 and no finite-L crossing — reported as a
% bound, not a class exponent.

GEL      = 0.5;
LMIN_FIT = 200;              % drop L = 50, 100 from all exponent fits
NU_GRID  = 0.40:0.01:2.50;   % search range for shift & collapse exponents
NU_FIXED = [0.88 1.50];      % hypotheses for the fixed-nu test

root = fullfile(fileparts(mfilename('fullpath')), '..', 'matlab', 'FSS_study');
csv  = fullfile(root, 'fss_alpha_table.csv');
assert(exist(csv,'file')==2, 'Missing %s — run RW3D_FSS_study first.', csv);
T = readtable(csv);
T.condition = string(T.condition);

conds = unique(T.condition, 'stable');
Lall  = unique(T.L);

% ---- per-(condition,L): mean alpha(p), p_c'(L), width w(L) ----
rows = struct('condition',{},'kappa',{},'L',{},'pcL',{},'p_lo',{},'p_hi',{}, ...
              'width',{},'nfit',{});
curves = struct();
for ci = 1:numel(conds)
    cond = conds(ci);
    sc   = T(T.condition==cond, :);
    kap  = sc.kappa(1);
    for L = Lall(:)'
        s = sc(sc.L==L, :);
        if isempty(s); continue; end
        pu = unique(s.p);
        am = arrayfun(@(pp) mean(s.alpha(s.p==pp),'omitnan'), pu);
        good = isfinite(am); pu = pu(good); am = am(good);
        if numel(pu) < 4; continue; end
        curves.(sc_safe(cond)).(sprintf('L%d',L)) = [pu am];
        m  = pu > 0.5; pm = pu(m); ac = am(m);
        [pcL, plo, phi] = cross_interp(pm, ac, GEL);
        w = fit_logistic_width(pm, ac, pcL);
        rows(end+1) = struct('condition',cond,'kappa',kap,'L',L,'pcL',pcL, ...
            'p_lo',plo,'p_hi',phi,'width',w,'nfit',numel(pm)); %#ok<AGROW>
    end
end
R = struct2table(rows);
writetable(R, fullfile(root,'fss_pcL_table.csv'));

% ---- per-condition FSS fits (large L only) ----
summ = struct('condition',{},'kappa',{},'nLfit',{},'pc_inf',{},'nu_shift',{}, ...
    'nu_shift_ci',{},'nu_width',{},'nu_width_ci',{},'nu_collapse',{}, ...
    'pc_inf_p88',{},'R2_p88',{},'pc_inf_150',{},'R2_150',{},'note',{});
figure('Name','p_c''(L) fits','Position',[80 80 920 640]); hold on;
cmap = lines(numel(conds));

for ci = 1:numel(conds)
    cond = conds(ci);
    kap  = T.kappa(find(T.condition==cond,1));
    rAll = R(R.condition==cond & isfinite(R.pcL), :);     % all sizes with a crossing
    rFit = rAll(rAll.L >= LMIN_FIT, :);                    % sizes used for fitting
    note = '';
    if kap==1, note = 'Eden: pc_inf->1, bound not a class exponent'; end

    if height(rFit) < 3
        summ(end+1) = blank_row(cond,kap,height(rFit), ...
            ternary(isempty(note),'too few L>=LMIN with a crossing',note)); %#ok<AGROW>
        if ~isempty(rAll)
            plot(rAll.L.^(-1/0.88), rAll.pcL, 'o', 'Color', cmap(ci,:), ...
                'MarkerFaceColor','none', 'DisplayName', sprintf('%s (no fit)', cond));
        end
        continue;
    end
    L = rFit.L(:); pc = rFit.pcL(:);

    [nu_shift, pc_inf, aamp] = shift_fit(L, pc, NU_GRID);
    nu_shift_ci = jackknife_shift(L, pc, NU_GRID);

    rw = rFit(isfinite(rFit.width) & rFit.width>0, :);
    if height(rw) >= 3
        nu_width    = width_fit(rw.L, rw.width);
        nu_width_ci = jackknife_width(rw.L, rw.width);
    else
        nu_width = NaN; nu_width_ci = NaN;
    end

    scf = sc_safe(cond);
    if isfield(curves, scf)
        nu_collapse = collapse_master(curves.(scf), pc_inf, NU_GRID, LMIN_FIT);
    else
        nu_collapse = NaN;
    end

    [pc88,R288] = fixed_nu_fit(L, pc, NU_FIXED(1));
    [pc15,R215] = fixed_nu_fit(L, pc, NU_FIXED(2));

    summ(end+1) = struct('condition',cond,'kappa',kap,'nLfit',height(rFit), ...
        'pc_inf',pc_inf,'nu_shift',nu_shift,'nu_shift_ci',nu_shift_ci, ...
        'nu_width',nu_width,'nu_width_ci',nu_width_ci,'nu_collapse',nu_collapse, ...
        'pc_inf_p88',pc88,'R2_p88',R288,'pc_inf_150',pc15,'R2_150',R215, ...
        'note',note); %#ok<AGROW>

    xf_all = rAll.L.^(-1/nu_shift);
    plot(xf_all, rAll.pcL, 'o', 'Color', cmap(ci,:), 'MarkerFaceColor','none', ...
        'HandleVisibility','off');
    plot(L.^(-1/nu_shift), pc, 'o', 'Color', cmap(ci,:), 'MarkerFaceColor', cmap(ci,:), ...
        'DisplayName', sprintf('%s (\\nu=%.2f\\pm%.2f)', cond, nu_shift, nu_shift_ci));
    xx = linspace(0, max(xf_all)*1.05, 50);
    plot(xx, pc_inf + aamp*xx, '-', 'Color', cmap(ci,:), 'HandleVisibility','off');
end
xlabel('L^{-1/\nu}  (open markers = L<200, excluded from fit)'); ylabel('p_c''(L)');
title('Finite-size scaling of the gel-point'); legend('Location','best'); box on; grid on;
saveas(gcf, fullfile(root,'fss_pcL_fits.png'));

S = struct2table(summ);
writetable(S, fullfile(root,'fss_nu_summary.csv'));

kl = S(~isnan(S.kappa) & S.kappa>=0 & S.kappa<1 & startsWith(S.condition,'k') ...
       & isfinite(S.nu_shift), :);
kl = sortrows(kl, 'kappa');
if height(kl) >= 2
    figure('Name','nu(kappa)','Position',[80 80 780 540]); hold on;
    errorbar(kl.kappa-0.004, kl.nu_shift, kl.nu_shift_ci, 'o-', 'LineWidth',1.5, ...
        'DisplayName','\nu_{shift}');
    errorbar(kl.kappa+0.004, kl.nu_width, kl.nu_width_ci, 's--', 'LineWidth',1.5, ...
        'DisplayName','\nu_{width}');
    yline(0.88,'--','\nu = 0.88 (3D percolation)','LabelHorizontalAlignment','left');
    xlabel('\kappa (nucleation-density parameter)'); ylabel('\nu');
    ylim([0 2.6]); legend('Location','best');
    title('Correlation-length exponent along the \kappa line (L\geq200)');
    box on; grid on;
    saveas(gcf, fullfile(root,'fss_nu_of_kappa.png'));
end

fprintf('\n=== FSS SUMMARY (fits use L >= %d) ===\n', LMIN_FIT);
disp(S);
fprintf(['Read it like this:\n' ...
 '  - Sanity: k0p00 pc_inf should sit near 1-p_c = 0.6884.\n' ...
 '  - Which exponent? Compare R2_p88 vs R2_150 per row: whichever fixed nu\n' ...
 '    fits pc_inf(L) better is the preferred effective exponent.\n' ...
 '  - One class? nu_shift and nu_width should agree within CI and be flat in kappa.\n' ...
 '  - k1p00 (Eden) is a bound, excluded from the kappa-line fit.\n']);
end

function [nu,pc_inf,a] = shift_fit(L, pc, NU_GRID)
    best=inf; nu=NaN; pc_inf=NaN; a=NaN;
    for nut = NU_GRID
        A=[ones(numel(L),1), L(:).^(-1/nut)]; b=A\pc(:); sse=sum((pc(:)-A*b).^2);
        if sse<best, best=sse; nu=nut; pc_inf=b(1); a=b(2); end
    end
end

function ci = jackknife_shift(L, pc, NU_GRID)
    n=numel(L); if n<3, ci=NaN; return; end
    est=zeros(n,1);
    for i=1:n
        k=true(n,1); k(i)=false;
        est(i)=shift_fit(L(k),pc(k),NU_GRID);
    end
    ci = sqrt((n-1)/n * sum((est-mean(est)).^2));
end

function nu = width_fit(L, w)
    pf = polyfit(log(L(:)), log(w(:)), 1); nu = -1/pf(1);
end

function ci = jackknife_width(L, w)
    n=numel(L); if n<3, ci=NaN; return; end
    est=zeros(n,1);
    for i=1:n
        k=true(n,1); k(i)=false; est(i)=width_fit(L(k),w(k));
    end
    ci = sqrt((n-1)/n * sum((est-mean(est)).^2));
end

function [pc_inf,R2] = fixed_nu_fit(L, pc, nu)
    A=[ones(numel(L),1), L(:).^(-1/nu)]; b=A\pc(:); res=pc(:)-A*b;
    pc_inf=b(1);
    R2 = 1 - sum(res.^2)/max(sum((pc(:)-mean(pc(:))).^2), eps);
end

function nu = collapse_master(Lstruct, pc_inf, NU_GRID, LMIN)
    nu=NaN; if ~isfinite(pc_inf), return; end
    fn=fieldnames(Lstruct); best=inf;
    for nut=NU_GRID
        X=[]; A=[];
        for i=1:numel(fn)
            L=sscanf(fn{i},'L%d'); if L<LMIN, continue; end
            pa=Lstruct.(fn{i}); p=pa(:,1); a=pa(:,2);
            m = p>0.5 & abs(p-pc_inf)<=0.10 & isfinite(a);
            X=[X;(p(m)-pc_inf)*L^(1/nut)]; A=[A;a(m)]; %#ok<AGROW>
        end
        if numel(X)<8, continue; end
        f=@(q) q(1)+(q(2)-q(1))./(1+exp((X-q(3))./q(4)));
        obj=@(q) sum((f(q)-A).^2);
        q0=[min(A) max(A) 0 max(std(X),eps)];
        try
            opt=optimset('Display','off','MaxFunEvals',3000,'MaxIter',3000);
            q=fminsearch(obj,q0,opt); sse=obj(q);
        catch
            sse=inf;
        end
        if sse<best, best=sse; nu=nut; end
    end
end

function [pc, plo, phi] = cross_interp(p, a, thr)
    pc=NaN; plo=NaN; phi=NaN;
    idx=find(diff(sign(a-thr))<0,1,'first'); if isempty(idx), return; end
    dp=p(idx+1)-p(idx); da=a(idx+1)-a(idx); if da==0, return; end
    pc=p(idx)+(thr-a(idx))*dp/da; plo=p(idx); phi=p(idx+1);
end

function w = fit_logistic_width(p, a, pc0)
    w=NaN; if numel(p)<4 || ~isfinite(pc0), return; end
    f=@(q) q(1)+(q(2)-q(1))./(1+exp((p-q(3))./q(4)));
    obj=@(q) sum((f(q)-a).^2);
    try
        opt=optimset('Display','off','MaxFunEvals',4000,'MaxIter',4000);
        q=fminsearch(obj,[min(a) max(a) pc0 0.03],opt); w=abs(q(4));
        if w>1 || w<=0, w=NaN; end
    catch
        w=NaN;
    end
end

function s = sc_safe(cond)
    s=char(cond); s(~isstrprop(s,'alphanum'))='_';
    if isempty(s) || ~isstrprop(s(1),'alpha'), s=['c' s]; end
end

function r = blank_row(cond,kap,nLfit,note)
    r = struct('condition',cond,'kappa',kap,'nLfit',nLfit,'pc_inf',NaN, ...
        'nu_shift',NaN,'nu_shift_ci',NaN,'nu_width',NaN,'nu_width_ci',NaN, ...
        'nu_collapse',NaN,'pc_inf_p88',NaN,'R2_p88',NaN,'pc_inf_150',NaN, ...
        'R2_150',NaN,'note',note);
end

function out = ternary(cond,a,b)
    if cond, out=a; else, out=b; end
end
