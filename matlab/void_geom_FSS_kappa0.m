function void_geom_FSS_kappa0(mode)
% void_geom_FSS_kappa0.m  (B1 — geometric FSS at kappa = 0)
%
% Measures the GEOMETRIC void-spanning threshold p_c'_geom(L) across the
% FSS lattice sizes at kappa = 0, using the same cumulative-build protocol
% and seed convention (rng(100*si)) as RW3D_FSS_study.
%
% This complements the dynamical p_c'_MR(L) from analyze_FSS and supports
% the joint threshold-reconciliation panel at kappa = 0.
%
% Usage:
%   void_geom_FSS_kappa0            % production L list
%   void_geom_FSS_kappa0('quick')   % smoke test
%
% Output (matlab/FSS_study/):
%   void_geom_fss_kappa0.csv          L, seed, pc_geom_z, pc_geom_any  (long)
%   void_geom_fss_kappa0_summary.csv  L, pc_geom_z_mean, pc_geom_z_std, ...

if nargin < 1, mode = 'production'; end
here = fileparts(mfilename('fullpath')); addpath(here);
out_root = fullfile(here, '..', 'matlab', 'FSS_study');
if ~exist(out_root, 'dir'), mkdir(out_root); end

switch lower(mode)
    case 'quick'
        L_VALUES = [80, 120];
        NS = 2;
    otherwise
        L_VALUES = [50, 100, 200, 300, 500, 750];
        NS = 3;
end

KAPPA = 0;
PGRID = 0.56:0.01:0.78;   % kappa=0 threshold ~0.68
STOPRUN = 2;

fprintf('VOID GEOM FSS (kappa=0)  mode=%s  L=%s  NS=%d\n', ...
    mode, mat2str(L_VALUES), NS);

long_rows = struct('L',{},'seed',{},'pc_geom_z',{},'pc_geom_any',{});
summ = struct('L',{},'pc_geom_z_mean',{},'pc_geom_z_std',{}, ...
    'pc_geom_any_mean',{},'pc_geom_any_std',{},'nseed',{});

for L = L_VALUES
    fprintf('\n---- L = %d ----\n', L);
    pcz_seeds = nan(1, NS);
    pca_seeds = nan(1, NS);

    for si = 1:NS
        rng(100 * si);
        base = [];
        zeros_run = 0;
        Pz = zeros(1, numel(PGRID));
        Pany = zeros(1, numel(PGRID));

        for jp = 1:numel(PGRID)
            p = PGRID(jp);
            lattice = generate_kappa_mixed_lattice(L, p, KAPPA, base);
            base = logical(lattice);
            voidmask = ~base;

            sz = span_axis(voidmask, 3);
            sany = span_axis(voidmask, 1) || span_axis(voidmask, 2) || sz;

            Pz(jp) = double(sz);
            Pany(jp) = double(sany);

            if ~sz, zeros_run = zeros_run + 1; else, zeros_run = 0; end
            if zeros_run >= STOPRUN
                break
            end
        end

        pcz = cross_half(PGRID, Pz);
        pca = cross_half(PGRID, Pany);
        pcz_seeds(si) = pcz;
        pca_seeds(si) = pca;
        fprintf('  seed %d  p_c''_geom(z)=%.4f  (any)=%.4f\n', si, pcz, pca);

        long_rows(end+1) = struct('L', L, 'seed', si, ...
            'pc_geom_z', pcz, 'pc_geom_any', pca); %#ok<AGROW>
    end

    summ(end+1) = struct('L', L, ...
        'pc_geom_z_mean', mean(pcz_seeds, 'omitnan'), ...
        'pc_geom_z_std', std(pcz_seeds, 'omitnan'), ...
        'pc_geom_any_mean', mean(pca_seeds, 'omitnan'), ...
        'pc_geom_any_std', std(pca_seeds, 'omitnan'), ...
        'nseed', NS); %#ok<AGROW>

    writetable(struct2table(long_rows), fullfile(out_root, 'void_geom_fss_kappa0.csv'));
    writetable(struct2table(summ), fullfile(out_root, 'void_geom_fss_kappa0_summary.csv'));
end

fprintf('\nDone. Wrote:\n  %s\n  %s\n', ...
    fullfile(out_root, 'void_geom_fss_kappa0.csv'), ...
    fullfile(out_root, 'void_geom_fss_kappa0_summary.csv'));
fprintf('Validation: L=500 should match void_pc_geom.csv kappa=0 (~0.685).\n');
end

function s = span_axis(voidmask, ax)
    CC = bwlabeln(voidmask, 6);
    switch ax
        case 1, a = CC(1,:,:);  b = CC(end,:,:);
        case 2, a = CC(:,1,:);  b = CC(:,end,:);
        case 3, a = CC(:,:,1);  b = CC(:,:,end);
    end
    a = unique(a(:)); a(a==0) = [];
    b = unique(b(:)); b(b==0) = [];
    s = ~isempty(intersect(a, b));
end

function pc = cross_half(p, P)
    pc = NaN;
    for i = 1:numel(P)-1
        if P(i) >= 0.5 && P(i+1) < 0.5
            t = (P(i) - 0.5) / (P(i) - P(i+1));
            pc = p(i) + t * (p(i+1) - p(i));
            return
        end
    end
end
