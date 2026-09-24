% RW3D_paper_batch_p_seed_SCRIPT.m
% Usage: matlab -nodisplay -r "RW3D_paper_batch(p_idx)"
% Where p_idx = 1, 2, 3, or 4 (for p = 0, 0.3116, 0.6884, 0.75)
% Saves both .csv and .mat files

clear; clc; close all; format short g

% Parameters
L = 500;
L2 = L^2;
L3 = L^3;
LW = 1e6;
NW = 3e3;
p_c_prime = 0.6884;
%p = [0, 0.3116, 0.6884, 0.75];
%p = [0.1, 0.3116, 0.5, 0.65];
p = [0:0.05:0.3, 0.3116,0.35:0.05:0.6,linspace(0.6,0.75,21),p_c_prime,0.75:0.01:0.9,0.95];
p = [0.3116,p_c_prime,0.85];
p_values = unique(p);

Np = numel(p);
t = (1:LW)';
ii = 1;


rng(23*ii); % For reproducibility

% if nargin < 1
%     error('Usage: RW3D_paper_batch(p_idx) with p_idx = 1..4');
% end
% if p_idx < 1 || p_idx > Np
%     error('p_idx must be 1..4');
%end
MSD = [];
base_template = zeros(L, L);
% %%
% for p_idx = 1:1:Np
%
%     fprintf('Starting simulation for Cluster %i  p = %.4f (job %d/%d)\n',ii, p(p_idx), p_idx,Np);
%     fprintf('Parameters: L=%d, steps=%d, walkers=%d\n', L, LW, NW);
%
%     % --- Templating logic ---
%     % Load or build up the template for this p_idx
%
%     % for i_p = 2:p_idx
%     %     current_occupied = sum(base_template(:));
%     %     target_occupied = round(p(i_p) * L2);
%     %     additional_needed = target_occupied - current_occupied;
%     %     if additional_needed > 0
%     %         unoccupied = ~base_template;
%     %         idx_unocc = find(unoccupied);
%     %         selected = idx_unocc(randperm(length(idx_unocc), additional_needed));
%     %         base_template(selected) = 1;
%     %     end
%     % end
%     % bwr = rand(L, L) < p_values(p_idx);
%     bw = base_template;
%
%     c = bwconncomp(bw);
%
%     % Find free positions
%     %[px, py, pz] = ind2sub([L, L, L], find(~bw));
%
%
%
%     figure(p_idx);imshowpair(bw,bwr)
%
%             pause(0.1)
%
%             bw0 = bw;
%
%     fprintf('Job %d completed successfully!\n', p_idx);
%
% end
%%

% Test 1: Start from scratch
lattice1 = generate_templated_growth_2d(L, 0.2);

% Test 2: Build upon existing lattice
lattice2 = generate_templated_growth_2d(L, 0.4, lattice1);

% Test 3: Continue growing the same lattice
lattice3 = generate_templated_growth_2d(L, 0.6, lattice2);

figure(1);
subplot(1,3,1);imshow(lattice1)
subplot(1,3,2);imshow(lattice2)
subplot(1,3,3);imshow(lattice3)

% Test 4: Start from a custom template
% custom_template = zeros(L, L);
% custom_template(25:30, 25:30) = 1; % Create a small square seed
% lattice4 = generate_templated_growth_2d(L, 0.3, custom_template);


%%
pip = 0.2;
base_template = rand(L, L) < pip;



for loop = 1:10
    current_occupied = sum(base_template(:));
    target_occupied = round(pip * L2);
    additional_needed = target_occupied - current_occupied;
    if additional_needed > 0
        unoccupied = ~base_template;
        idx_unocc = find(unoccupied);
        selected = idx_unocc(randperm(length(idx_unocc), additional_needed));
        base_template(selected) = 1;
    end
end
bwr = rand(L, L) < p_values(p_idx);