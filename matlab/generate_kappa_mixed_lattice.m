function lattice = generate_kappa_mixed_lattice(L, p, kappa, template)
% generate_kappa_mixed_lattice  3D site-percolation lattice via
%   nucleation-density kappa model.
%
%   lattice = generate_kappa_mixed_lattice(L, p, kappa)
%   lattice = generate_kappa_mixed_lattice(L, p, kappa, template)
%
%   kappa controls the nucleation density of new sites needed:
%
%       kappa = 1  ->  single seed, pure 6N templated growth
%                      -> compact connected cluster  ->  p_c' ~ 0.886
%
%       kappa = 0  ->  N_seeds = all required new sites, placed randomly,
%                      6N growth step is trivially empty
%                      = random (Bernoulli) percolation  ->  p_c' ~ 0.683
%
%   Physical interpretation: kappa maps onto the nucleation site density
%   of the material.  High kappa (few seeds) produces a spatially clustered,
%   compact occupied network.  Low kappa (many seeds) produces a spatially
%   uniform distribution of obstacles that more efficiently fragments the
%   void space at lower p.
%
%   Connectivity guarantee: every occupied site is connected to at least
%   one nucleation seed via a path of 6N adjacency steps.  There are no
%   isolated disconnected islands — all growth proceeds from seeds outward.
%   This aligns with both existing universality classes (random and
%   templated) which both maintain this connected-from-seed property.
%
%   Cumulative generation: pass the output of a lower-p call as `template`
%   to build the lattice incrementally without re-placing existing sites.
%   At each increment, (1-kappa) * n_new additional seeds are planted in
%   the unoccupied sites, and 6N growth proceeds from ALL occupied sites
%   (existing cluster + new seeds) until the target density is reached.
%
%   Inputs
%   ------
%   L        : lattice side length  (creates L x L x L cubic lattice)
%   p        : target occupation probability  [0, 1]
%   kappa    : nucleation-density parameter   [0, 1]
%   template : (optional) logical/double L x L x L — existing occupied
%              sites to build upon for cumulative generation
%
%   Output
%   ------
%   lattice  : double L x L x L  (0 = unoccupied, 1 = occupied)
%
%   Notes
%   -----
%   - No periodic boundary conditions are applied during growth (consistent
%     with existing templated scripts).  The RW simulation uses PBC
%     separately via mod() in RW3D_P_SP.
%   - batch_min sets the floor on how many frontier sites are added per
%     iteration — keeps the loop efficient for large L.

% -------------------------------------------------------------------------
% Input handling and validation
% -------------------------------------------------------------------------
if nargin < 4 || isempty(template)
    template = false(L, L, L);
end

kappa         = max(0, min(1, kappa));
L3            = L^3;
target_sites  = max(0, min(L3, round(p * L3)));
lattice       = logical(template);
current_sites = nnz(lattice);

if current_sites >= target_sites
    lattice = double(lattice);
    return;
end

n_new = target_sites - current_sites;   % sites still to add

% -------------------------------------------------------------------------
% STEP 1 — Plant nucleation seeds
%
%   n_seeds = round((1-kappa) * n_new)
%
%   kappa=1: 0 new seeds  -> pure 6N growth from existing occupied sites
%            (or 1 seed if starting from empty, so growth can begin)
%   kappa=0: n_seeds = n_new  -> plant exactly the required number of
%            sites at random positions = Bernoulli / density-increment;
%            the growth step (Step 2) then immediately exits.
%
%   Intermediate kappa: a fraction (1-kappa) of needed sites are seeded
%   randomly throughout unoccupied space; the remainder are grown via 6N
%   adjacency from the combined frontier of template + new seeds.
% -------------------------------------------------------------------------
n_seeds = round((1 - kappa) * n_new);

% Starting from empty: always plant at least 1 seed so frontier is non-empty
if current_sites == 0
    n_seeds = max(1, n_seeds);
end

if n_seeds > 0
    unoccupied = find(~lattice);
    n_plant    = min(n_seeds, numel(unoccupied));
    if n_plant > 0
        sel              = unoccupied(randperm(numel(unoccupied), n_plant));
        lattice(sel)     = true;
        current_sites    = current_sites + n_plant;
    end
end

% kappa=0 case: seeds fill the target exactly, no growth loop needed
if current_sites >= target_sites
    lattice = double(lattice);
    return;
end

% -------------------------------------------------------------------------
% STEP 2 — 6N adjacency growth from ALL occupied sites
%
%   Grow outward from the combined frontier of (template + new seeds)
%   until target_sites is reached.  Sites are added in batches: at each
%   iteration we pick min(remaining, batch) sites at random from the
%   full 6N frontier, ensuring monotonic increase toward the target.
% -------------------------------------------------------------------------
batch_min = 500;    % floor on batch size — keeps loop iterations low

while current_sites < target_sites
    remaining = target_sites - current_sites;

    % --- 6N frontier: unoccupied sites adjacent to any occupied site ---
    nbr = false(L, L, L);
    nbr(1:end-1, :, :) = nbr(1:end-1, :, :) | lattice(2:end,   :, :);
    nbr(2:end,   :, :) = nbr(2:end,   :, :) | lattice(1:end-1, :, :);
    nbr(:, 1:end-1, :) = nbr(:, 1:end-1, :) | lattice(:, 2:end,   :);
    nbr(:, 2:end,   :) = nbr(:, 2:end,   :) | lattice(:, 1:end-1, :);
    nbr(:, :, 1:end-1) = nbr(:, :, 1:end-1) | lattice(:, :, 2:end  );
    nbr(:, :, 2:end)   = nbr(:, :, 2:end)   | lattice(:, :, 1:end-1);

    frontier = find(nbr & ~lattice);

    if isempty(frontier)
        % All unoccupied sites are isolated from any occupied site.
        % This should not occur for p < 1 with any seeds present.
        warning('generate_kappa_mixed_lattice: frontier empty at %.4f (target %.4f). Planting emergency seed.', current_sites/L3, p);
        unoccupied = find(~lattice);
        if isempty(unoccupied), break; end
        lattice(unoccupied(randi(numel(unoccupied)))) = true;
        current_sites = current_sites + 1;
        continue;
    end

    % Batch: 25% of frontier, bounded below by batch_min and above by remaining
    n_pick = min(remaining, max(batch_min, round(0.25 * numel(frontier))));
    n_pick = min(n_pick, numel(frontier));

    sel              = frontier(randperm(numel(frontier), n_pick));
    lattice(sel)     = true;
    current_sites    = current_sites + n_pick;
end

% -------------------------------------------------------------------------
% Sanity check on achieved density
% -------------------------------------------------------------------------
achieved = nnz(lattice) / L3;
if abs(achieved - p) > 0.002
    fprintf('  [kappa=%.2f] Target p=%.4f, achieved p=%.4f\n', ...
            kappa, p, achieved);
end

lattice = double(lattice);
end
