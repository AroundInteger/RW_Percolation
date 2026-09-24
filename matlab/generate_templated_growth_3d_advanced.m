function lattice = generate_templated_growth_3d_advanced(L, p, opts)
% Advanced 3D templated/random growth with multiple physical options
% lattice = generate_templated_growth_3d_advanced(L, p, opts)
% 
% Inputs:
%   L    - lattice size (creates LxLxL)
%   p    - target occupation probability (0..1)
%   opts - struct with fields (all optional):
%       .template            logical LxLxL starting lattice (default all false)
%       .mode                'templated'|'density_increment'|'random' (default 'templated')
%       .connectivity        6|18|26 (default 6)
%       .periodic            true|false (default false)
%       .mask                logical LxLxL allowed sites (default all true)
%       .min_neighbors       integer >=0 neighbor threshold for occupation (default 1)
%       .batch_fraction      fraction of candidates to accept per iter (default 0.2)
%       .max_iters           safety cap (default inf)
%       .anisotropy_weights  3-vector weights for x,y,z neighbor directions (default [1 1 1])
%       .random_seed         scalar rng seed (optional)
%
% Notes:
% - 'templated': adjacency-constrained growth from existing occupied sites, obeying rules
% - 'density_increment': random addition without adjacency, to reach p
% - 'random': independent Bernoulli mask within opts.mask

if nargin < 3, opts = struct(); end

if isfield(opts,'random_seed') && ~isempty(opts.random_seed)
    rng(opts.random_seed);
end

% Defaults
template = get_opt(opts,'template',false(L,L,L));
mode = get_opt(opts,'mode','templated');
conn = get_opt(opts,'connectivity',6);
periodic = get_opt(opts,'periodic',false);
allowed = get_opt(opts,'mask',true(L,L,L));
min_neighbors = get_opt(opts,'min_neighbors',1);
batch_fraction = get_opt(opts,'batch_fraction',0.2);
max_iters = get_opt(opts,'max_iters',inf);
aniso = get_opt(opts,'anisotropy_weights',[1 1 1]);

% Clamp/validate
actionable = allowed;  % only these sites can be filled
L3 = L^3;
target_sites = max(0, min(L3, round(p * L3)));

switch mode
    case 'random'
        lattice = false(L,L,L);
        % Random occupancy restricted to allowed
        num_allowed = nnz(actionable);
        num_to_fill = min(target_sites, num_allowed);
        idx_allowed = find(actionable);
        if num_to_fill > 0
            sel = idx_allowed(randperm(num_allowed, num_to_fill));
            lattice(sel) = true;
        end
        lattice = lattice & actionable;
        lattice = double(lattice);
        return;

    case 'density_increment'
        % Start from template and add random sites to reach target density
        lattice = logical(template) & actionable;
        current_sites = nnz(lattice);
        additional_needed = target_sites - current_sites;
        if additional_needed > 0
            idx_unocc = find(actionable & ~lattice);
            k = min(additional_needed, numel(idx_unocc));
            if k > 0
                sel = idx_unocc(randperm(numel(idx_unocc), k));
                lattice(sel) = true;
            end
        end
        lattice = double(lattice);
        return;

    case 'templated_random'
        % Templated random percolation: build on previous lattice with random selection
        lattice = false(L,L,L);
        % Random occupancy restricted to allowed (ignoring template for selection)
        num_allowed = nnz(actionable);
        num_to_fill = min(target_sites, num_allowed);
        idx_allowed = find(actionable);
        if num_to_fill > 0
            sel = idx_allowed(randperm(num_allowed, num_to_fill));
            lattice(sel) = true;
        end
        lattice = lattice & actionable;
        lattice = double(lattice);
        return;

    case 'templated_rod_x'
        % Rod-like templating along x-axis
        lattice = generate_rod_template(L, target_sites, 'x', actionable);
        lattice = double(lattice);
        return;

    case 'templated_rod_y'
        % Rod-like templating along y-axis
        lattice = generate_rod_template(L, target_sites, 'y', actionable);
        lattice = double(lattice);
        return;

    case 'templated_rod_z'
        % Rod-like templating along z-axis
        lattice = generate_rod_template(L, target_sites, 'z', actionable);
        lattice = double(lattice);
        return;

    case 'templated_rod_random'
        % Random rod-like templating (random orientation)
        orientations = {'x', 'y', 'z'};
        orientation = orientations{randi(3)};
        lattice = generate_rod_template(L, target_sites, orientation, actionable);
        lattice = double(lattice);
        return;

    case 'templated'
        % Continue below
    otherwise
        error('Unknown mode: %s', mode);
end

% Templated adjacency-constrained growth
lattice = logical(template) & actionable;
current_sites = nnz(lattice);

% If starting from empty template and target_sites > 0, add nucleation sites
if current_sites == 0 && target_sites > 0
    % Add a few random nucleation sites (typically 1-3 for small p, more for larger p)
    num_nucleation = min(target_sites, max(1, round(target_sites * 0.01))); % 1% of target or at least 1
    idx_allowed = find(actionable);
    if ~isempty(idx_allowed)
        nucleation_indices = idx_allowed(randperm(length(idx_allowed), min(num_nucleation, length(idx_allowed))));
        lattice(nucleation_indices) = true;
        current_sites = nnz(lattice);
    end
end

if current_sites >= target_sites
    lattice = double(lattice);
    return;
end

iter = 0;
while current_sites < target_sites && iter < max_iters
    iter = iter + 1;

    % Compute neighbors according to connectivity and periodic BCs
    neighbors = compute_neighbors(lattice, conn, periodic, aniso);

    % Candidate sites: allowed, not currently filled, meet neighbor rule
    % Count neighbors for threshold rule
    neighbor_count = neighbors; % neighbors currently is logical mask of adjacency; convert to counts
    % Build accurate neighbor counts by summing 6/18/26 directional shifts
    neighbor_count = compute_neighbor_count(lattice, conn, periodic, aniso);

    candidate_mask = actionable & ~lattice & (neighbor_count >= min_neighbors);
    if ~any(candidate_mask(:))
        break;
    end

    % Batch selection
    idx_candidates = find(candidate_mask);
    num_candidates = numel(idx_candidates);
    batch_size = min(target_sites - current_sites, max(1, round(batch_fraction * num_candidates)));

    if batch_size <= 0
        break;
    end

    sel = idx_candidates(randperm(num_candidates, batch_size));
    lattice(sel) = true;
    current_sites = current_sites + batch_size;
end

lattice = double(lattice);

end

function v = get_opt(s, field, default)
    if isfield(s, field) && ~isempty(s.(field))
        v = s.(field);
    else
        v = default;
    end
end

function neighbor_count = compute_neighbor_count(lattice, conn, periodic, aniso)
% Return count of occupied neighbors per voxel under connectivity and BCs
    [Lx,Ly,Lz] = size(lattice);
    neighbor_count = zeros(Lx,Ly,Lz, 'double');

    % Prepare shifts: 6-neighbors (faces)
    shifts = [ 1  0  0; -1  0  0; 0  1  0; 0 -1  0; 0  0  1; 0  0 -1];
    weights = [aniso(1) aniso(1) aniso(2) aniso(2) aniso(3) aniso(3)];

    if conn >= 18
        % add edge neighbors (12 more)
        edge_shifts = [ 1  1  0;  1 -1  0; -1  1  0; -1 -1  0; ...
                         1  0  1;  1  0 -1; -1  0  1; -1  0 -1; ...
                         0  1  1;  0  1 -1;  0 -1  1;  0 -1 -1];
        shifts = [shifts; edge_shifts];
        weights = [weights, repmat(mean(aniso), 1, size(edge_shifts,1))];
    end
    if conn == 26
        % add corner neighbors (8 more)
        corner_shifts = [ 1  1  1;  1  1 -1;  1 -1  1;  1 -1 -1; ...
                         -1  1  1; -1  1 -1; -1 -1  1; -1 -1 -1];
        shifts = [shifts; corner_shifts];
        weights = [weights, repmat(mean(aniso), 1, size(corner_shifts,1))];
    end

    for k = 1:size(shifts,1)
        dx = shifts(k,1); dy = shifts(k,2); dz = shifts(k,3);
        shifted = shift3d(lattice, dx, dy, dz, periodic);
        neighbor_count = neighbor_count + weights(k) * double(shifted);
    end
end

function out = shift3d(A, dx, dy, dz, periodic)
% Shift 3D array by integer offsets with optional periodic wrap
    [Lx,Ly,Lz] = size(A);
    out = false(Lx,Ly,Lz);

    % Compute index ranges
    x_src = (1:Lx) - dx; y_src = (1:Ly) - dy; z_src = (1:Lz) - dz;
    if periodic
        x_src = mod(x_src-1, Lx) + 1;
        y_src = mod(y_src-1, Ly) + 1;
        z_src = mod(z_src-1, Lz) + 1;
        out = A(x_src, y_src, z_src);
        return;
    end

    x_dst = max(1,1+dx):min(Lx,Lx+dx);
    y_dst = max(1,1+dy):min(Ly,Ly+dy);
    z_dst = max(1,1+dz):min(Lz,Lz+dz);

    x_src_valid = max(1,1-dx):min(Lx,Lx-dx);
    y_src_valid = max(1,1-dy):min(Ly,Ly-dy);
    z_src_valid = max(1,1-dz):min(Lz,Lz-dz);

    if ~isempty(x_dst) && ~isempty(y_dst) && ~isempty(z_dst)
        out(x_dst, y_dst, z_dst) = A(x_src_valid, y_src_valid, z_src_valid);
    end
end

function neighbors = compute_neighbors(lattice, conn, periodic, aniso)
% Return logical mask of any occupied neighbor according to connectivity
    neighbor_count = compute_neighbor_count(lattice, conn, periodic, aniso);
    neighbors = neighbor_count > 0;
end

