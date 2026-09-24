% RW3D_kappa_mixing_study.m
%
% Tunable gel-point study via kappa-mixed lattice growth.
%
% For each value of kappa in [0, 0.2, 0.4, 0.6, 0.8, 1.0], this script
% sweeps a range of occupation probabilities p, builds a 3D lattice using
% generate_kappa_mixed_lattice, runs random walkers on the UNOCCUPIED
% sites via RW3D_P_SP, computes the ensemble-averaged MSD, and saves both
% the per-(kappa,p) MSD MAT files and a combined alpha table.
%
% After completion, run analyze_kappa_gel_points.m to extract p_c'(kappa).
%
% Usage (MATLAB command line or batch):
%   >> RW3D_kappa_mixing_study           % uses MODE = 'quick'
%   >> MODE = 'production'; RW3D_kappa_mixing_study
%
% Batch (no display):
%   /Applications/MATLAB_R2025a.app/bin/matlab -nodisplay -r \
%       "MODE='quick'; RW3D_kappa_mixing_study; exit"
%
% Output files (written to OUT_DIR):
%   MSD_kappa<K>_p<P>_L<L>_seed<S>.mat   — raw MSD for each (kappa,p,seed)
%   kappa_study_alpha_table.mat           — alpha values for all conditions
%   kappa_study_alpha_table.csv           — same, for Python/Excel

% =========================================================================
% CONFIGURATION
% =========================================================================
MODE = 'production';
if ~exist('MODE','var')
    MODE = 'quick';      % 'quick' or 'production'
end

switch MODE
    case 'quick'
        % Fast exploratory run — confirm monotonicity before committing to
        % full production.  ~2-4 h on a modern Mac (no parallel toolbox).
        % With parfor and 8 cores: ~30-60 min.
        L      = 100;       % lattice side length
        LW     = 200000;    % steps per walker
        NW     = 500;       % walkers per (kappa, p)
        SEEDS  = 1;         % random seeds (replicates)
        WAIT   = [20, 5];   % RW3D_P_SP wait time params [mean, std]

    case 'production'
        % Full resolution — matches existing Clusters1 dataset quality.
        % ~several days on a single core; use parfor + HPC cluster.
        L      = 500;
        LW     = 1000000;
        NW     = 3000;
        SEEDS  = 3;
        WAIT   = [20, 5];

    otherwise
        error('MODE must be ''quick'' or ''production''');
end

% kappa values to study (0 = random, 1 = fully templated)
%
% Spacing rationale: gel-point data from the initial quick run shows most
% of the p_c'(kappa) transition is concentrated in kappa=[0.80, 1.00].
% Below kappa=0.80, p_c' barely moves (~0.680 to ~0.720).  The new
% points resolve the transition; the old points (0, 0.2, 0.4, 0.6, 0.8,
% 1.0) are loaded from existing MAT files and not recomputed.
%
% Seed-fraction interpretation:
%   kappa=0.80 -> 20% of new sites are random seeds  -> p_c'~0.72
%   kappa=0.90 -> 10% seeds  ->  expected ~0.75-0.80
%   kappa=0.94 ->  6% seeds  ->  expected ~0.82-0.87
%   kappa=0.97 ->  3% seeds  ->  expected ~0.90-0.95
%   kappa=1.00 ->  1 seed    ->  p_c'~0.98 (single-seed Eden-like regime)
% Spacing rationale — seed counts at typical n_new ~ 50,000:
%   kappa=0.97 -> ~1500 seeds   kappa=0.980 -> ~1000 seeds
%   kappa=0.990 -> ~500 seeds   kappa=0.995 -> ~250 seeds
%   kappa=0.998 -> ~100 seeds   kappa=1.000 -> 1 seed
% Log-like spacing in [0.97,1.00] to resolve the steep transition.
KAPPA_VALUES = [0.00, 0.20, 0.40, 0.60, 0.70, 0.80, ...
                0.85, 0.88, 0.91, 0.94, 0.97, ...
                0.980, 0.990, 0.995, 0.996, 0.997, 0.998, 1.00];

% p-value sweep — dense near both gel-point regions (~0.683 and ~0.886)
% and extended to 0.99 to capture the high-kappa single-seed regime.
P_VALUES = unique([...
    0, 0.05, 0.10, 0.20, 0.30, 0.3116, 0.40, 0.50, ...
    0.60, 0.62, 0.64, 0.65, 0.66, 0.67, 0.68, 0.6884, ...
    0.70, 0.72, 0.75, 0.78, 0.80, 0.82, 0.84, 0.85, ...
    0.86, 0.87, 0.875, 0.88, 0.885, 0.89, 0.90, ...
    0.92, 0.95, 0.97, 0.99, ...
    0.991, 0.993, 0.995 ...   % extension for kappa=1.0 (p_c' extrapolated ~0.993)
]);

% Output directory (written relative to this script's location)
OUT_DIR = fullfile(fileparts(mfilename('fullpath')), '..', ...
    'matlab', 'Clusters_kappa', sprintf('L%d', L));

if ~exist(OUT_DIR, 'dir')
    mkdir(OUT_DIR);
end

fprintf('\n=== KAPPA MIXING STUDY ===\n');
fprintf('Mode        : %s\n', MODE);
fprintf('L           : %d\n', L);
fprintf('LW          : %d\n', LW);
fprintf('NW          : %d\n', NW);
fprintf('Seeds       : %d\n', SEEDS);
fprintf('kappa values: %s\n', num2str(KAPPA_VALUES));
fprintf('p values    : %d points from %.2f to %.2f\n', ...
    numel(P_VALUES), P_VALUES(1), P_VALUES(end));
fprintf('Output dir  : %s\n\n', OUT_DIR);

% =========================================================================
% PRE-ALLOCATE RESULTS TABLE
% =========================================================================
% alpha_table rows: one per (kappa, p, seed)
n_rows  = numel(KAPPA_VALUES) * numel(P_VALUES) * SEEDS;
res_kappa = zeros(n_rows, 1);
res_p     = zeros(n_rows, 1);
res_seed  = zeros(n_rows, 1);
res_alpha = zeros(n_rows, 1);
res_r2    = zeros(n_rows, 1);
row_idx   = 0;

t = (1:LW)';    % time axis

% =========================================================================
% MAIN LOOP
% =========================================================================
total_sims = numel(KAPPA_VALUES) * numel(P_VALUES) * SEEDS;
sim_count  = 0;

for ki = 1:numel(KAPPA_VALUES)
    kappa = KAPPA_VALUES(ki);
    kappa_str = sprintf('%.4f', kappa);
    kappa_str(kappa_str == '.') = 'p';   % e.g. '0p2000' for file names
    % NOTE: must use 4 d.p. to avoid collisions between e.g. 0.990 and 0.995
    % (both would round to '0p99' with %.2f, causing the skip logic to load
    % the wrong data silently).

    fprintf('--- kappa = %.4f ---\n', kappa);

    for si = 1:SEEDS
        seed = 100 * si;    % distinct seed per replicate
        rng(seed);

        % Build lattice cumulatively: carry forward from previous p value
        base_lattice = [];

        for pi = 1:numel(P_VALUES)
            p = P_VALUES(pi);
            sim_count = sim_count + 1;

            mat_file = fullfile(OUT_DIR, ...
                sprintf('MSD_kappa%s_p%.4f_L%d_seed%d.mat', ...
                        kappa_str, p, L, si));

            % Skip if already computed
            if exist(mat_file, 'file')
                fprintf('  [%d/%d] kappa=%.2f p=%.4f seed=%d — SKIP (exists)\n', ...
                    sim_count, total_sims, kappa, p, si);

                % Still need to load alpha for the table
                tmp = load(mat_file, 'alpha', 'r2');
                row_idx = row_idx + 1;
                res_kappa(row_idx) = kappa;
                res_p(row_idx)     = p;
                res_seed(row_idx)  = si;
                res_alpha(row_idx) = tmp.alpha;
                res_r2(row_idx)    = tmp.r2;
                continue;
            end

            fprintf('  [%d/%d] kappa=%.2f p=%.4f seed=%d ...', ...
                sim_count, total_sims, kappa, p, si);
            tic;

            % -------------------------------------------------------
            % 1. GENERATE LATTICE (cumulative — builds on previous p)
            % -------------------------------------------------------
            lattice      = generate_kappa_mixed_lattice(L, p, kappa, base_lattice);
            base_lattice = logical(lattice);  % logical saves ~875 MB vs double at L=500
            bw           = base_lattice;

            % -------------------------------------------------------
            % 2. PLACE WALKERS ON UNOCCUPIED SITES
            % -------------------------------------------------------
            free_idx = find(~bw);
            N_free   = numel(free_idx);

            if N_free < NW
                % Too few free sites — record NaN and continue
                fprintf(' SKIP (only %d free sites < NW=%d)\n', N_free, NW);
                alpha = NaN;  r2 = NaN;  msd = NaN(LW, 1);
                row_idx = row_idx + 1;
                res_kappa(row_idx) = kappa;
                res_p(row_idx)     = p;
                res_seed(row_idx)  = si;
                res_alpha(row_idx) = alpha;
                res_r2(row_idx)    = r2;
                save(mat_file, 'kappa', 'p', 'L', 'LW', 'NW', ...
                    'alpha', 'r2', 'msd', 't', 'MODE');
                continue;
            end

            % Random starting positions (no replacement)
            rp  = free_idx(randperm(N_free, NW));
            [sx, sy, sz] = ind2sub([L, L, L], rp);
            rsp = [sx, sy, sz];

            % -------------------------------------------------------
            % 3+4. RUN RANDOM WALKS AND ACCUMULATE MSD ONLINE
            %
            % Uses parfor reduction on msd_acc to avoid storing the full
            % (LW × NW) position arrays.  At production scale that would
            % be 3 × LW × NW × 4 bytes ≈ 36 GB — fatal on any workstation.
            %
            % Memory per worker: LW×3 doubles (xyz, ~24 MB at LW=1M) plus
            % LW doubles (d2, ~8 MB) = ~32 MB per core regardless of NW.
            % The L^3 logical bw array (~125 MB at L=500) is broadcast once.
            % -------------------------------------------------------
            msd_acc = zeros(LW, 1, 'double');   % reduction variable

            parfor i_rw = 1:NW  %#ok<PARFOR>
                [xyz, ~] = RW3D_P_SP(bw, LW, L, rsp(i_rw, :), WAIT);
                d2 = (xyz(:,1) - xyz(1,1)).^2 + ...
                     (xyz(:,2) - xyz(1,2)).^2 + ...
                     (xyz(:,3) - xyz(1,3)).^2;
                msd_acc = msd_acc + d2;   % MATLAB parfor reduction (+=)
            end

            msd = msd_acc / NW;

            % -------------------------------------------------------
            % 5. EXTRACT ALPHA FROM POWER-LAW FIT (log-log slope)
            %    Fit over the middle decade: steps LW/100 to LW/10
            %    to avoid early-time transients and long-time saturation.
            % -------------------------------------------------------
            fit_lo = max(2,   round(LW / 100));
            fit_hi = min(LW,  round(LW / 10));
            t_fit  = log10(t(fit_lo:fit_hi));
            m_fit  = log10(max(msd(fit_lo:fit_hi), 1e-12));

            % Guard against NaN/Inf
            valid  = isfinite(t_fit) & isfinite(m_fit);
            if sum(valid) >= 5
                cf     = polyfit(t_fit(valid), m_fit(valid), 1);
                alpha  = cf(1);
                % R^2 for quality assessment
                m_pred = polyval(cf, t_fit(valid));
                ss_res = sum((m_fit(valid) - m_pred).^2);
                ss_tot = sum((m_fit(valid) - mean(m_fit(valid))).^2);
                r2     = 1 - ss_res / max(ss_tot, eps);
            else
                alpha = NaN;
                r2    = NaN;
            end

            elapsed = toc;
            fprintf(' alpha=%.4f, r2=%.3f (%.1f s)\n', alpha, r2, elapsed);

            % -------------------------------------------------------
            % 6. SAVE PER-(KAPPA,P,SEED) RESULTS
            % -------------------------------------------------------
            save(mat_file, 'kappa', 'p', 'L', 'LW', 'NW', ...
                'alpha', 'r2', 'msd', 't', 'MODE', '-v7.3');

            row_idx = row_idx + 1;
            res_kappa(row_idx) = kappa;
            res_p(row_idx)     = p;
            res_seed(row_idx)  = si;
            res_alpha(row_idx) = alpha;
            res_r2(row_idx)    = r2;
        end  % p loop
    end  % seed loop
end  % kappa loop

% =========================================================================
% SAVE COMBINED ALPHA TABLE
% =========================================================================
res_kappa = res_kappa(1:row_idx);
res_p     = res_p(1:row_idx);
res_seed  = res_seed(1:row_idx);
res_alpha = res_alpha(1:row_idx);
res_r2    = res_r2(1:row_idx);

alpha_table = table(res_kappa, res_p, res_seed, res_alpha, res_r2, ...
    'VariableNames', {'kappa', 'p_value', 'seed', 'alpha', 'r2'});

mat_out = fullfile(OUT_DIR, 'kappa_study_alpha_table.mat');
csv_out = fullfile(OUT_DIR, 'kappa_study_alpha_table.csv');
save(mat_out, 'alpha_table', 'KAPPA_VALUES', 'P_VALUES', 'L', 'LW', 'NW');
writetable(alpha_table, csv_out);

fprintf('\nResults saved:\n  %s\n  %s\n', mat_out, csv_out);
fprintf('Run analyze_kappa_gel_points.m to extract p_c''(kappa).\n');
fprintf('=== STUDY COMPLETE ===\n');
