function void_percolation_threshold(mode)
% VOID_PERCOLATION_THRESHOLD
% Geometric cross-check for the tunable gel-point paper.
%
% For each nucleation density kappa, rebuild the SAME lattices the walker
% saw (generate_kappa_mixed_lattice, cumulative build over an ascending
% p-grid, seeds 1..NS with rng(seed)) and measure the GEOMETRIC void-
% spanning threshold p_c'_geom(kappa): the p at which the unoccupied
% (fluid) sublattice loses a face-to-face spanning cluster.
%
% This is the structural partner of the DYNAMICAL gel point p_c'_MR(kappa)
% (the alpha = 0.5 crossing from the MSD). If the two agree for kappa <~ 0.8
% and peel apart approaching the Eden limit, that is a second, independent
% signature of the same crossover.
%
% Spanning test: bwlabeln(void, 6) then check whether one void label
% touches both opposite faces. z-spanning is the primary estimator;
% any-axis spanning is also recorded. (Requires Image Processing Toolbox
% for bwlabeln; a union-find fallback can be added if unavailable.)
%
% Validation anchor: kappa = 0 must return p_c'_geom ~ 0.6884 = 1 - p_c.
%
% Usage:
%   void_percolation_threshold            % production (L=500)
%   void_percolation_threshold('quick')   % smoke test (L=150, subset)
%
% Outputs (written next to this file):
%   void_span_rows.csv      kappa,p,seed,spans_z,spans_any,free_frac
%   void_pc_geom.csv        kappa,pc_geom_z,pc_geom_any,nseed,L
%
% Reuses, unchanged: generate_kappa_mixed_lattice.m
% ---------------------------------------------------------------------
if nargin < 1, mode = 'production'; end
here = fileparts(mfilename('fullpath')); addpath(here);

switch lower(mode)
    case 'quick'
        L   = 150;
        KAP = [0 0.4 0.8 0.97 1.0];
        NS  = 2;
    otherwise
        L   = 500;
        KAP = [0 0.2 0.4 0.6 0.7 0.8 0.85 0.88 0.91 0.94 0.97 0.98 0.99 0.995 0.996 0.997 0.998 1.0];
        NS  = 3;
end

% ascending p-grid; cumulative build carries the lattice upward (matches
% how the MSD lattices were generated). Fine spacing spans every kappa's
% expected threshold (~0.68 up towards ~0.95); capped to keep the Eden-
% region rebuild tractable.
PGRID   = 0.56:0.01:0.96;
STOPRUN = 2;   % per seed: stop after this many consecutive non-spanning p

fprintf('VOID PERCOLATION THRESHOLD  (mode=%s, L=%d, NS=%d, %d kappa)\n', ...
        mode, L, NS, numel(KAP));

rows = struct('kappa',{},'p',{},'seed',{},'spans_z',{},'spans_any',{},'free_frac',{});
summ = struct('kappa',{},'pc_geom_z',{},'pc_geom_any',{},'nseed',{},'L',{});

for ik = 1:numel(KAP)
    kappa = KAP(ik);
    fprintf('\n==== kappa = %.4g ====\n', kappa);

    % per-p spanning probability, averaged over seeds
    Pz   = zeros(1,numel(PGRID));
    Pany = zeros(1,numel(PGRID));
    cnt  = zeros(1,numel(PGRID));

    for si = 1:NS
        rng(si);                 % reproducible growth, seed convention 1..NS
        base = [];               % reset cumulative build per seed
        zeros_run = 0;
        for jp = 1:numel(PGRID)
            p = PGRID(jp);
            lattice = generate_kappa_mixed_lattice(L, p, kappa, base);
            base = logical(lattice);             % carry upward (cumulative), logical to save memory
            voidmask = ~base;
            free_frac = nnz(voidmask) / numel(voidmask);

            sz  = span_axis(voidmask, 3);
            sx  = span_axis(voidmask, 1);
            sy  = span_axis(voidmask, 2);
            sany = sx || sy || sz;

            Pz(jp)   = Pz(jp)   + sz;
            Pany(jp) = Pany(jp) + sany;
            cnt(jp)  = cnt(jp)  + 1;

            rows(end+1) = struct('kappa',kappa,'p',p,'seed',si, ...
                'spans_z',double(sz),'spans_any',double(sany), ...
                'free_frac',free_frac); %#ok<AGROW>

            if ~sz, zeros_run = zeros_run + 1; else, zeros_run = 0; end
            if zeros_run >= STOPRUN
                % remaining higher-p points are non-spanning (monotone)
                for jr = jp+1:numel(PGRID)
                    Pz(jr) = Pz(jr) + 0; Pany(jr) = Pany(jr) + 0; cnt(jr) = cnt(jr) + 1;
                    rows(end+1) = struct('kappa',kappa,'p',PGRID(jr),'seed',si, ...
                        'spans_z',0,'spans_any',0,'free_frac',NaN); %#ok<AGROW>
                end
                break
            end
        end
        fprintf('  seed %d done\n', si);
    end

    Pz   = Pz   ./ max(cnt,1);
    Pany = Pany ./ max(cnt,1);
    pcz  = cross_half(PGRID, Pz);
    pca  = cross_half(PGRID, Pany);
    fprintf('  p_c''_geom (z) = %.4f   (any) = %.4f\n', pcz, pca);

    summ(end+1) = struct('kappa',kappa,'pc_geom_z',pcz,'pc_geom_any',pca, ...
        'nseed',NS,'L',L); %#ok<AGROW>

    % --- incremental save after every kappa: safe to Ctrl-C partway ---
    writetable(struct2table(summ), fullfile(here,'void_pc_geom.csv'));
    writetable(struct2table(rows), fullfile(here,'void_span_rows.csv'));
    fprintf('  [saved through kappa=%.4g]\n', kappa);
end

fprintf('\nDone. Wrote void_span_rows.csv and void_pc_geom.csv\n');
fprintf('Validation: kappa=0 should give p_c''_geom(z) ~ 0.688 (=1-p_c).\n');
end

% ---------------------------------------------------------------------
function s = span_axis(voidmask, ax)
% true if one 6-connected void cluster touches both opposite faces on axis ax
CC = bwlabeln(voidmask, 6);
switch ax
    case 1, a = CC(1,:,:);  b = CC(end,:,:);
    case 2, a = CC(:,1,:);  b = CC(:,end,:);
    case 3, a = CC(:,:,1);  b = CC(:,:,end);
end
a = unique(a(:)); a(a==0) = [];
b = unique(b(:)); b(b==0) = [];
s = ~isempty(intersect(a,b));
end

% ---------------------------------------------------------------------
function pc = cross_half(p, P)
% linear-interpolate the p where spanning probability P crosses 0.5 (down)
pc = NaN;
for i = 1:numel(P)-1
    if P(i) >= 0.5 && P(i+1) < 0.5
        t = (P(i) - 0.5) / (P(i) - P(i+1));
        pc = p(i) + t * (p(i+1) - p(i));
        return
    end
end
end
