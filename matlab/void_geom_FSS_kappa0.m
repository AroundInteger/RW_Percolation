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
%   void_geom_fss_kappa0.csv   L, pc_geom_z, pc_geom_any, nseed

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

summ = struct('L',{},'pc_geom_z',{},'pc_geom_any',{},'nseed',{});

for L = L_VALUES
    fprintf('\n---- L = %d ----\n', L);
    Pz = zeros(1, numel(PGRID));
    Pany = zeros(1, numel(PGRID));
    cnt = zeros(1, numel(PGRID));

    for si = 1:NS
        rng(100 * si);
        base = [];
        zeros_run = 0;
        for jp = 1:numel(PGRID)
            p = PGRID(jp);
            lattice = generate_kappa_mixed_lattice(L, p, KAPPA, base);
            base = logical(lattice);
            voidmask = ~base;

            sz = span_axis(voidmask, 3);
            sany = span_axis(voidmask, 1) || span_axis(voidmask, 2) || sz;

            Pz(jp) = Pz(jp) + double(sz);
            Pany(jp) = Pany(jp) + double(sany);
            cnt(jp) = cnt(jp) + 1;

            if ~sz, zeros_run = zeros_run + 1; else, zeros_run = 0; end
            if zeros_run >= STOPRUN
                for jr = jp+1:numel(PGRID)
                    cnt(jr) = cnt(jr) + 1;
                end
                break
            end
        end
        fprintf('  seed %d done\n', si);
    end

    Pz = Pz ./ max(cnt, 1);
    Pany = Pany ./ max(cnt, 1);
    pcz = cross_half(PGRID, Pz);
    pca = cross_half(PGRID, Pany);
    fprintf('  p_c''_geom(z) = %.4f   (any) = %.4f\n', pcz, pca);

    summ(end+1) = struct('L', L, 'pc_geom_z', pcz, 'pc_geom_any', pca, 'nseed', NS); %#ok<AGROW>
    writetable(struct2table(summ), fullfile(out_root, 'void_geom_fss_kappa0.csv'));
end

fprintf('\nDone. Wrote %s\n', fullfile(out_root, 'void_geom_fss_kappa0.csv'));
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
