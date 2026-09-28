function alpha_window_sensitivity()
% alpha_window_sensitivity.m  (M4 — alpha fit-window sensitivity)
%
% Recomputes alpha(p,L) from saved FSS MSD .mat files using three fit
% windows on the log-log MSD slope (no new random walks):
%   default : [L_W/100,  L_W/10]
%   wide    : [L_W/200,  L_W/20]
%   narrow  : [L_W/50,   L_W/5]
%
% For each window it locates p_c'(L) by the alpha = 0.5 crossing and
% extrapolates p_c'(inf) from the shift fit (same NU grid as analyze_FSS).
%
% Outputs (matlab/FSS_study/):
%   alpha_window_pcL.csv     p_c'(L) per (condition, window, L)
%   alpha_window_summary.csv p_c'(inf) per (condition, window)
%
% Usage:  >> alpha_window_sensitivity
%
% Requires the MSD tree from RW3D_FSS_study (mat files under FSS_study/).

GEL      = 0.5;
LMIN_FIT = 200;
NU_GRID  = 0.40:0.01:2.50;

WINDOWS = struct( ...
    'name', {'default','wide','narrow'}, ...
    'lo',   {@(LW) max(2, round(LW/100)), @(LW) max(2, round(LW/200)), @(LW) max(2, round(LW/50))}, ...
    'hi',   {@(LW) round(LW/10),         @(LW) round(LW/20),          @(LW) round(LW/5)});

root = fullfile(fileparts(mfilename('fullpath')), '..', 'matlab', 'FSS_study');
assert(exist(root,'dir')==7, 'Missing %s — run RW3D_FSS_study first.', root);

% discover condition folders
d = dir(fullfile(root, 'k*'));
d = [d; dir(fullfile(root, 'templ*'))];
conds = {d([d.isdir]).name};
if isempty(conds)
    error('No condition subfolders in %s', root);
end

pcL_rows = struct('condition',{},'kappa',{},'window',{},'L',{},'pcL',{});
summ_rows = struct('condition',{},'kappa',{},'window',{},'nLfit',{},'pc_inf',{},'nu_shift',{});

for ci = 1:numel(conds)
    cond = conds{ci};
    Ldirs = dir(fullfile(root, cond, 'L*'));
    if isempty(Ldirs), continue; end

    kap = NaN;
    sample = dir(fullfile(root, cond, 'L*', 'MSD_*.mat'));
    if ~isempty(sample)
        tmp = load(fullfile(sample(1).folder, sample(1).name), 'kappa');
        if isfield(tmp, 'kappa'), kap = tmp.kappa; end
    end

    for wi = 1:numel(WINDOWS)
        win = WINDOWS(wi);
        win_pcL = struct('L',{},'pcL',{});

        for li = 1:numel(Ldirs)
            L = sscanf(Ldirs(li).name, 'L%d');
            mats = dir(fullfile(Ldirs(li).folder, Ldirs(li).name, 'MSD_*.mat'));
            if isempty(mats), continue; end

            p_u = []; a_u = [];
            for mi = 1:numel(mats)
                S = load(fullfile(mats(mi).folder, mats(mi).name), ...
                    'p','msd','t','LW','alpha');
                if ~isfield(S,'msd') || ~isfield(S,'t'), continue; end
                LW = S.LW;
                fit_lo = win.lo(LW);
                fit_hi = min(LW, win.hi(LW));
                tf = log10(S.t(fit_lo:fit_hi));
                mf = log10(max(S.msd(fit_lo:fit_hi), 1e-12));
                ok = isfinite(tf) & isfinite(mf);
                if sum(ok) >= 5
                    cf = polyfit(tf(ok), mf(ok), 1);
                    alpha = cf(1);
                else
                    alpha = NaN;
                end
                p_u(end+1) = S.p; %#ok<AGROW>
                a_u(end+1) = alpha; %#ok<AGROW>
            end

            pu = unique(p_u);
            am = arrayfun(@(pp) mean(a_u(p_u==pp), 'omitnan'), pu);
            good = isfinite(am); pu = pu(good); am = am(good);
            if numel(pu) < 4, continue; end

            m = pu > 0.5;
            [pcL, ~, ~] = cross_interp(pu(m), am(m), GEL);
            pcL_rows(end+1) = struct('condition',string(cond),'kappa',kap, ...
                'window',string(win.name),'L',L,'pcL',pcL); %#ok<AGROW>
            if isfinite(pcL)
                win_pcL(end+1) = struct('L',L,'pcL',pcL); %#ok<AGROW>
            end
        end

        rFit = win_pcL([win_pcL.L] >= LMIN_FIT);
        if numel(rFit) < 3
            summ_rows(end+1) = struct('condition',string(cond),'kappa',kap, ...
                'window',string(win.name),'nLfit',numel(rFit),'pc_inf',NaN,'nu_shift',NaN); %#ok<AGROW>
            continue;
        end
        Lf = [rFit.L]'; pc = [rFit.pcL]';
        [nu_shift, pc_inf, ~] = shift_fit(Lf, pc, NU_GRID);
        summ_rows(end+1) = struct('condition',string(cond),'kappa',kap, ...
            'window',string(win.name),'nLfit',numel(rFit),'pc_inf',pc_inf, ...
            'nu_shift',nu_shift); %#ok<AGROW>
    end
end

writetable(struct2table(pcL_rows), fullfile(root, 'alpha_window_pcL.csv'));
writetable(struct2table(summ_rows), fullfile(root, 'alpha_window_summary.csv'));
fprintf('Wrote alpha_window_pcL.csv and alpha_window_summary.csv under %s\n', root);
end

function [nu,pc_inf,a] = shift_fit(L, pc, NU_GRID)
    best=inf; nu=NaN; pc_inf=NaN; a=NaN;
    for nut = NU_GRID
        A=[ones(numel(L),1), L(:).^(-1/nut)]; b=A\pc(:); sse=sum((pc(:)-A*b).^2);
        if sse<best, best=sse; nu=nut; pc_inf=b(1); a=b(2); end
    end
end

function [pc, plo, phi] = cross_interp(p, a, thr)
    pc=NaN; plo=NaN; phi=NaN;
    idx=find(diff(sign(a-thr))<0,1,'first'); if isempty(idx), return; end
    dp=p(idx+1)-p(idx); da=a(idx+1)-a(idx); if da==0, return; end
    pc=p(idx)+(thr-a(idx))*dp/da; plo=p(idx); phi=p(idx+1);
end
