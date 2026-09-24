% RW3D_FSS_study.m
%
% Finite-size scaling (FSS) study for the tunable gel-point paper.
%
% Sweeps lattice size L over several values for a small set of growth
% conditions along (and at the endpoints of) the kappa nucleation-density
% line, plus the multi-seed 6N-templated class.  For each (condition, L)
% it builds the lattice cumulatively over a p-grid, runs void-phase random
% walkers on the CRITICAL-REGION p-values via RW3D_P_SP, computes the
% ensemble MSD online (parfor reduction), extracts the anomalous exponent
% alpha(p,L), and saves per-(condition,L,p,seed) MSD files plus a combined
% alpha table.
%
% Reuses, unchanged, the exact model functions from the kappa study:
%     generate_kappa_mixed_lattice.m         (kappa-line lattices)
%     generate_templated_growth_3d_logical.m (multi-seed 6N templated)
%     RW3D_P_SP.m                            (void-phase RW engine)
% so FSS results are consistent with the existing production dataset.
%
% After completion run analyze_FSS.m to extract p_c'(L), fit
%     p_c'(L) = p_c'(inf) + a * L^(-1/nu),
% obtain nu per condition (three independent estimators) and assemble nu(kappa).
%
% ---------------------------------------------------------------------------
% Usage (MATLAB command line):
%   >> RW3D_FSS_study                         % production defaults below
%   >> MODE = 'quick'; RW3D_FSS_study         % fast smoke-test (small L/NW/LW)
%
% Headless batch (recommended — this is a multi-day campaign):
%   nohup /Applications/MATLAB_R2025a.app/bin/matlab -nodisplay \
%       -r "RW3D_FSS_study; exit" > fss_study.log 2>&1 &
%
% Resume after interruption: existing per-condition MSD .mat files are
% skipped automatically — just re-run the same command.
% ---------------------------------------------------------------------------

% =========================================================================
% MODE / GLOBAL PARAMETERS
% =========================================================================
if ~exist('MODE','var'); MODE = 'production'; end

switch MODE
    case 'quick'       % SMOKE TEST — validates the full pipeline (sim + analysis)
        % end-to-end in a few minutes. 3 sizes so analyze_FSS's nu fit (needs
        % >=3 L) actually runs; coarse p-grid; small NW/LW. The NUMBERS here are
        % noisy/biased (tiny L, short LW) and are NOT physics — this only proves
        % the code paths work. Trust nu only from the production run.
        L_VALUES  = [40, 70, 110];
        NW        = 200;
        SEEDS     = 1;
        LW_REF    = 1e5;    % reference LW at L_REF (floored to 1e4 at these sizes)
        DP_FINE   = 0.02;   % coarse measurement grid — keeps the smoke test fast
    case 'production'  % the real FSS campaign
        L_VALUES  = [50, 100, 200, 300, 500, 750];
        NW        = 3000;   % walkers per (condition, L, p) — capped to free sites
        SEEDS     = 3;      % independent replicates
        LW_REF    = 1e6;    % reference steps-per-walker at L_REF (matches production)
        DP_FINE   = 0.005;  % fine measurement grid inside the critical window
    otherwise
        error('MODE must be ''quick'' or ''production''');
end

L_REF   = 500;             % reference size for LW scaling
WAIT    = [20, 5];         % RW3D_P_SP wait-time [mean, std] — matches production
MIN_FREE_FRAC = 0.02;      % skip a (cond,L,p) if free-site fraction < this
NW_FLOOR      = 200;       % warn (but still run) if capped NW drops below this

% LW scales with L^2 (finite-size crossover time ~ L^2 / D), rounded to 1000.
lw_of_L = @(L) max(1e4, round(LW_REF * (L / L_REF)^2 / 1000) * 1000);

% =========================================================================
% CONDITIONS
%   type   : 'kappa'      -> generate_kappa_mixed_lattice(L,p,kappa,base)
%            'templated'  -> generate_templated_growth_3d_logical(L,p,base)
%   win    : [lo hi] critical-region p-window (fine grid, dp = 0.005) where
%            walkers are actually run. Widen if the alpha=0.5 crossing lands
%            on a window edge for any L (see analyze_FSS.m warnings).
%   pc_guess is documentation only.
% =========================================================================
C = struct('tag',{},'type',{},'kappa',{},'win',{},'pc_guess',{});
% Windows widened after the smoke test: at small L the gel-point shifts
% UP (finite-size), so templated/Eden and the upper tails must reach higher
% or the crossing is missed. Wider windows cost only a few extra p-points.
C(1) = struct('tag','k0p00',   'type','kappa',     'kappa',0.00, 'win',[0.58 0.78], 'pc_guess',0.683);
C(2) = struct('tag','k0p60',   'type','kappa',     'kappa',0.60, 'win',[0.60 0.82], 'pc_guess',0.700);
C(3) = struct('tag','k0p80',   'type','kappa',     'kappa',0.80, 'win',[0.62 0.88], 'pc_guess',0.720);
C(4) = struct('tag','k0p97',   'type','kappa',     'kappa',0.97, 'win',[0.80 0.98], 'pc_guess',0.900);
C(5) = struct('tag','k1p00',   'type','kappa',     'kappa',1.00, 'win',[0.88 0.998],'pc_guess',0.990);
C(6) = struct('tag','templ6N', 'type','templated', 'kappa',NaN,  'win',[0.82 0.98], 'pc_guess',0.886);
C(7) = struct('tag','k0p99',  'type','kappa',     'kappa',0.99,  'win',[0.82 0.99],  'pc_guess',0.852);
C(8) = struct('tag','k0p995', 'type','kappa',     'kappa',0.995, 'win',[0.84 0.995], 'pc_guess',0.880);

% Per-condition max lattice size. Eden (k1p00) is a BOUND, not a class exponent,
% and its L=750 cell is pathologically slow at p~0.94; cap it at L=500 (already
% run at 5 sizes, ample for a bound).
[C.Lmax] = deal(750);
C(5).Lmax = 500;   % k1p00 -> skip L750
C(7).Lmax = 500;   % k0p99  -> skip L750 (Eden-region rebuild pathologically slow)
C(8).Lmax = 500;   % k0p995 -> skip L750 (Eden-region rebuild pathologically slow)

DP_COARSE = 0.10;    % pre-build grid spacing below the window (cumulative fidelity)
                     % (DP_FINE — the measurement-grid spacing — is set per MODE above)

OUT_ROOT = fullfile(fileparts(mfilename('fullpath')), '..', 'matlab', 'FSS_study');
if ~exist(OUT_ROOT, 'dir'); mkdir(OUT_ROOT); end

fprintf('\n=== RW3D FINITE-SIZE SCALING STUDY [mode = %s] ===\n', MODE);
fprintf('L values : %s\n', num2str(L_VALUES));
fprintf('NW / seeds: %d / %d\n', NW, SEEDS);
fprintf('LW(L)    : L^2 law, ref %d at L=%d  ->  e.g. ', LW_REF, L_REF);
fprintf('%s\n', strjoin(arrayfun(@(L) sprintf('L%d:%d',L,lw_of_L(L)), L_VALUES, 'uni',0), '  '));
fprintf('Conditions: %s\n', strjoin({C.tag}, ', '));
fprintf('Output   : %s\n\n', OUT_ROOT);

% =========================================================================
% PARALLEL POOL
% =========================================================================
if isempty(gcp('nocreate'))
    try, parpool('local'); catch ME
        fprintf('Warning: no parallel pool (%s) — running serially.\n', ME.message);
    end
end

% =========================================================================
% RESULTS TABLE (grown incrementally; final size unknown due to skips)
% =========================================================================
res = struct('condition',{},'kappa',{},'L',{},'p',{},'seed',{}, ...
             'alpha',{},'r2',{},'nfree_frac',{},'nw_used',{},'LW',{});

% =========================================================================
% MAIN LOOP:  condition -> L -> seed -> p
% =========================================================================
for ci = 1:numel(C)
    cond = C(ci);

    % Build this condition's p-grid: coarse pre-build below window + fine window
    p_pre  = 0:DP_COARSE:(cond.win(1) - DP_COARSE);
    p_meas = cond.win(1):DP_FINE:cond.win(2);
    p_all  = unique(round([p_pre, p_meas] * 1e6) / 1e6);      % monotonic build grid
    is_meas = ismember(round(p_all*1e6)/1e6, round(p_meas*1e6)/1e6);

    fprintf('\n############ CONDITION %s (type=%s, kappa=%.4g, pc_guess~%.3f) ############\n', ...
        cond.tag, cond.type, cond.kappa, cond.pc_guess);

    for L = L_VALUES
        if L > cond.Lmax, continue; end   % honour per-condition Lmax
        LW = lw_of_L(L);
        t  = (1:LW)';
        out_dir = fullfile(OUT_ROOT, cond.tag, sprintf('L%d', L));
        if ~exist(out_dir, 'dir'); mkdir(out_dir); end

        fprintf('\n---- %s  L=%d  LW=%d ----\n', cond.tag, L, LW);

        for si = 1:SEEDS
            rng(100 * si);              % distinct, reproducible seed per replicate
            base_lattice = [];          % reset cumulative build per (L, seed)

            for pj = 1:numel(p_all)
                p = p_all(pj);

                % --- Build lattice cumulatively at EVERY grid point ---
                switch cond.type
                    case 'kappa'
                        lattice = generate_kappa_mixed_lattice(L, p, cond.kappa, base_lattice);
                    case 'templated'
                        lattice = generate_templated_growth_3d_logical(L, p, base_lattice);
                end
                base_lattice = logical(lattice);

                % Only RUN walkers on measurement (critical-region) p-values
                if ~is_meas(pj); continue; end

                mat_file = fullfile(out_dir, ...
                    sprintf('MSD_%s_p%.4f_L%d_seed%d.mat', cond.tag, p, L, si));
                if exist(mat_file, 'file')
                    tmp = load(mat_file, 'alpha','r2','nfree_frac','nw_used','LW');
                    res(end+1) = pack_row(cond, L, p, si, tmp.alpha, tmp.r2, ...
                                          tmp.nfree_frac, tmp.nw_used, tmp.LW); %#ok<SAGROW>
                    fprintf('  p=%.4f seed=%d  SKIP (exists, alpha=%.3f)\n', p, si, tmp.alpha);
                    continue;
                end

                bw       = base_lattice;
                free_idx = find(~bw);
                N_free   = numel(free_idx);
                nfree_frac = N_free / L^3;

                if nfree_frac < MIN_FREE_FRAC || N_free < 2
                    alpha = NaN; r2 = NaN; msd = NaN(LW,1); nw_used = 0;
                    fprintf('  p=%.4f seed=%d  SKIP (free frac %.3f < %.3f)\n', ...
                        p, si, nfree_frac, MIN_FREE_FRAC);
                else
                    nw_used = min(NW, N_free);
                    if nw_used < NW_FLOOR
                        fprintf('  [warn] p=%.4f L=%d: only %d free sites -> NW capped to %d\n', ...
                            p, L, N_free, nw_used);
                    end
                    rp        = free_idx(randperm(N_free, nw_used));
                    [sx,sy,sz]= ind2sub([L, L, L], rp);
                    rsp       = [sx, sy, sz];

                    msd_acc = zeros(LW, 1, 'double');
                    tic;
                    parfor iw = 1:nw_used  %#ok<PARFOR>
                        [xyz, ~] = RW3D_P_SP(bw, LW, L, rsp(iw,:), WAIT);
                        d2 = (xyz(:,1)-xyz(1,1)).^2 + ...
                             (xyz(:,2)-xyz(1,2)).^2 + ...
                             (xyz(:,3)-xyz(1,3)).^2;
                        msd_acc = msd_acc + d2;
                    end
                    msd = msd_acc / nw_used;

                    % alpha from log-log slope over the middle decade [LW/100, LW/10]
                    fit_lo = max(2,  round(LW/100));
                    fit_hi = min(LW, round(LW/10));
                    tf = log10(t(fit_lo:fit_hi));
                    mf = log10(max(msd(fit_lo:fit_hi), 1e-12));
                    ok = isfinite(tf) & isfinite(mf);
                    if sum(ok) >= 5
                        cf = polyfit(tf(ok), mf(ok), 1);
                        alpha  = cf(1);
                        mpred  = polyval(cf, tf(ok));
                        ssr    = sum((mf(ok)-mpred).^2);
                        sst    = sum((mf(ok)-mean(mf(ok))).^2);
                        r2     = 1 - ssr/max(sst, eps);
                    else
                        alpha = NaN; r2 = NaN;
                    end
                    fprintf('  p=%.4f seed=%d  alpha=%.4f r2=%.3f  (nw=%d, %.1fs)\n', ...
                        p, si, alpha, r2, nw_used, toc);
                end

                condition = cond.tag; kappa = cond.kappa; %#ok<NASGU>
                save(mat_file, 'condition','kappa','L','LW','NW','nw_used', ...
                     'p','alpha','r2','msd','t','nfree_frac','MODE','-v7.3');

                res(end+1) = pack_row(cond, L, p, si, alpha, r2, ...
                                      nfree_frac, nw_used, LW); %#ok<SAGROW>
            end % p
        end % seed
    end % L
end % condition

% =========================================================================
% SAVE COMBINED ALPHA TABLE
% =========================================================================
T = struct2table(res);
mat_out = fullfile(OUT_ROOT, 'fss_alpha_table.mat');
csv_out = fullfile(OUT_ROOT, 'fss_alpha_table.csv');
save(mat_out, 'T', 'C', 'L_VALUES', 'NW', 'SEEDS', 'LW_REF', 'L_REF', 'WAIT');
writetable(T, csv_out);

fprintf('\nSaved:\n  %s\n  %s\n', mat_out, csv_out);
fprintf('Now run:  analyze_FSS   (extracts p_c''(L), fits nu, assembles nu(kappa))\n');
fprintf('=== FSS STUDY COMPLETE ===\n');

% -------------------------------------------------------------------------
function row = pack_row(cond, L, p, si, alpha, r2, nfree_frac, nw_used, LW)
    row = struct('condition',{cond.tag}, 'kappa',cond.kappa, 'L',L, 'p',p, ...
                 'seed',si, 'alpha',alpha, 'r2',r2, 'nfree_frac',nfree_frac, ...
                 'nw_used',nw_used, 'LW',LW);
end
