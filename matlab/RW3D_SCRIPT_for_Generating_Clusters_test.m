% Script to verify templated growth patterns
clear; clc; close all;

% RW3D_paper_batch_p_seed_SCRIPT.m
% Usage: matlab -nodisplay -r "RW3D_paper_batch(p_idx)"
% Where p_idx = 1, 2, 3, or 4 (for p = 0, 0.3116, 0.6884, 0.75)
% Saves both .csv and .mat files

%function RW3D_paper_batch_p_seed(p_idx,seed)

% Parameters
L = 10;
L3 = L^3;
LW = 1e2;
NW = 3e3;
p_c_prime = 0.6884;
p = [0, 0.2, 0.3116, 0.6884, 0.75];
%p = [0 0.2:0.1:0.3,0.35:0.01:0.5];
%p = [0:0.05:0.3, 0.3116,0.35:0.05:0.6,linspace(0.6,0.75,21),p_c_prime, 0.8, 0.85, 0.9, 0.95];
p_values = unique(p);

Np = numel(p);
t = (1:LW)';

Lattice = false(L3,Np,3);

for ii = 1%:10
    rng(21*ii); % For reproducibility

    % if nargin < 1
    %     error('Usage: RW3D_paper_batch(p_idx) with p_idx = 1..4');
    % end
    % if p_idx < 1 || p_idx > Np
    %     error('p_idx must be 1..4');
    %end
    MSD = [];
    %%
    base_template = false(L,L,L);
    loop = 1;
    for p_idx = 1:Np

        fprintf('Starting simulation for Cluster %i  p = %.4f (job %d/%d)\n',ii, p_values(p_idx), p_idx,Np);
        fprintf('Parameters: L=%d, steps=%d, walkers=%d\n', L, LW, NW);


        for lattice_type = 1:3

            

            switch lattice_type
                case 1

                    % --- Templating logic ---
                    if p_values(p_idx) > 0 && p_idx > 2
                        base_template = reshape(Lattice(:,p_idx-1,1),L,L,L);
                        lattice = generate_templated_growth_3d_logical(L, p_values(p_idx),base_template);
                    elseif p_idx == 2
                        base_template = rand(L,L,L) <= p_values(p_idx);
                        lattice = generate_templated_growth_3d_logical(L, p_values(p_idx),base_template);
                    else
                        lattice = base_template;
                    end

                case 2

                    % --- Templating logic ---
                    % Load or build up the template for this p_idx
                    base_template = reshape(Lattice(:,p_idx-1,2),L,L,L);
                    for i_p = 2:p_idx
                        current_occupied = sum(base_template(:));
                        target_occupied = round(p(i_p) * L3);
                        additional_needed = target_occupied - current_occupied;
                        if additional_needed > 0
                            unoccupied = ~base_template;
                            idx_unocc = find(unoccupied);
                            selected = idx_unocc(randperm(length(idx_unocc), additional_needed));
                            base_template(selected) = 1;
                        end
                    end

                case 3

                    lattice = rand(L,L,L) < p_values(p_idx) ;

            end

            bw = lattice > 0;
            Lattice(:,p_idx,lattice_type) = bw(:);

        end


    end



    % MSD_table = array2table(MSD, 'VariableNames', variableNames);
    %
    % % Create the final table with t
    % %dataTable = table(t,'time', MSD_table);
    %
    %
    % % % Specify the filename
    % % filename = sprintf('/Users/rowanbrown/Documents/GitHub/RW_Percolation/matlab/Clusters/p_output_C%i.csv',ii);
    % %
    % % % Write the table to a CSV file
    % % writetable(MSD_table, filename);
    %
    % % Write the table to a CSV file
    % % Assuming MSD_table is already defined in your workspace
    mat_file_out = sprintf('/Users/iMacPro/Documents/GitHub/RW_Percolation/matlab/Clusters/Lattices_%i.mat',ii); % Specify the filename
    % csv_file_out = sprintf('/Users/iMacPro/Documents/GitHub/RW_Percolation/matlab/Clusters/iMacPro_MSD_table_noTemplating_%i.csv',ii); % Specify the filename
    save(mat_file_out, 'Lattice'); % Save the variable to the MAT-file
    % writetable(MSD_table, csv_file_out);


end
