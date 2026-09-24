% Generate multiple 3D cluster variants across p values
clear; clc; close all;

L = 60;
L3 = L^3;
p_values = [0, 0.2, 0.3116, 0.5, 0.6884, 0.75];
Np = numel(p_values);

output_dir = fullfile(pwd, 'Clusters');
if ~exist(output_dir,'dir'), mkdir(output_dir); end

% Modes to generate:
% 1) templated (6N, open)
% 2) density_increment (no adjacency)
% 3) random percolation
% 4) templated 26N (richer connectivity)
% 5) templated periodic BCs
% 6) templated with obstacle mask
% 7) templated with neighbor threshold >=2
num_modes = 7;
Lattice = false(L3, Np, num_modes);

% Build a simple spherical obstacle mask (mode 6)
[X,Y,Z] = ndgrid(1:L,1:L,1:L);
center = (L+1)/2;
radius = L/4;
mask_obstacle = true(L,L,L);
mask_obstacle((X-center).^2 + (Y-center).^2 + (Z-center).^2 < radius^2) = false;

% Base template for templated modes
base_template = false(L,L,L);

for p_idx = 1:Np
    p = p_values(p_idx);
    fprintf('p = %.4f (%d/%d)\n', p, p_idx, Np);

    % 1) templated (6N, open)
    opts = struct('mode','templated','connectivity',6,'periodic',false,'template',base_template);
    lat1 = generate_templated_growth_3d_advanced(L, p, opts);
    base_template = logical(lat1);
    Lattice(:, p_idx, 1) = lat1(:) > 0;

    % 2) density_increment (no adjacency)
    opts = struct('mode','density_increment','template',false(L,L,L));
    lat2 = generate_templated_growth_3d_advanced(L, p, opts);
    Lattice(:, p_idx, 2) = lat2(:) > 0;

    % 3) random percolation
    opts = struct('mode','random');
    lat3 = generate_templated_growth_3d_advanced(L, p, opts);
    Lattice(:, p_idx, 3) = lat3(:) > 0;

    % 4) templated 26N
    opts = struct('mode','templated','connectivity',26,'template',base_template);
    lat4 = generate_templated_growth_3d_advanced(L, p, opts);
    Lattice(:, p_idx, 4) = lat4(:) > 0;

    % 5) templated periodic
    opts = struct('mode','templated','connectivity',6,'periodic',true,'template',base_template);
    lat5 = generate_templated_growth_3d_advanced(L, p, opts);
    Lattice(:, p_idx, 5) = lat5(:) > 0;

    % 6) templated with obstacle mask
    opts = struct('mode','templated','connectivity',6,'template',base_template,'mask',mask_obstacle);
    lat6 = generate_templated_growth_3d_advanced(L, p, opts);
    Lattice(:, p_idx, 6) = lat6(:) > 0;

    % 7) templated with neighbor threshold >=2
    opts = struct('mode','templated','connectivity',6,'template',base_template,'min_neighbors',2);
    lat7 = generate_templated_growth_3d_advanced(L, p, opts);
    Lattice(:, p_idx, 7) = lat7(:) > 0;
end

% Save
outfile = fullfile(output_dir, sprintf('ClusterVariants_L%d.mat', L));
save(outfile, 'Lattice', 'p_values', 'L');
fprintf('Saved variants to %s\n', outfile);

