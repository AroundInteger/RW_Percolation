% Script to verify templated growth patterns - FIXED VERSION
clear; clc; close all;

% RW3D_paper_batch_p_seed_SCRIPT.m
% Usage: matlab -nodisplay -r "RW3D_paper_batch(p_idx)"
% Where p_idx = 1, 2, 3, or 4 (for p = 0, 0.3116, 0.6884, 0.75)
% Saves both .csv and .mat files

% Parameters
L = 10;
L3 = L^3;
LW = 1e2;
NW = 3e3;
p_c_prime = 0.6884;
p_values = [0, 0.2, 0.3116, 0.6884, 0.75];  % Use consistent variable name
Np = numel(p_values);
t = (1:LW)';

% Pre-allocate lattice storage
Lattice = false(L3, Np, 3);

% Create output directory if it doesn't exist
output_dir = fullfile(pwd, 'Clusters');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

for ii = 1  % :10 - can be extended for multiple runs
    rng(21*ii); % For reproducibility
    
    fprintf('Starting cluster generation run %d\n', ii);
    
    % Initialize base templates for each lattice type
    base_template_1 = false(L, L, L);  % For case 1 (templated growth)
    base_template_2 = false(L, L, L);  % For case 2 (incremental random)
    
    for p_idx = 1:Np
        
        fprintf('Processing p = %.4f (%d/%d)\n', p_values(p_idx), p_idx, Np);
        
        for lattice_type = 1:3
            
            switch lattice_type
                case 1  % Templated growth
                    if p_idx == 1
                        % First iteration: start with empty or single seed
                        if p_values(p_idx) == 0
                            lattice = false(L, L, L);
                        else
                            lattice = generate_templated_growth_3d_logical(L, p_values(p_idx));
                        end
                        base_template_1 = lattice;
                    else
                        % Use previous lattice as template
                        if p_values(p_idx) > p_values(p_idx-1)
                            lattice = generate_templated_growth_3d_logical(L, p_values(p_idx), base_template_1);
                            base_template_1 = lattice;
                        else
                            % If current p is less than previous, start fresh
                            lattice = generate_templated_growth_3d_logical(L, p_values(p_idx));
                            base_template_1 = lattice;
                        end
                    end
                    
                case 2  % Incremental random filling
                    if p_idx == 1
                        % First iteration
                        if p_values(p_idx) == 0
                            lattice = false(L, L, L);
                        else
                            lattice = rand(L, L, L) <= p_values(p_idx);
                        end
                        base_template_2 = lattice;
                    else
                        % Build incrementally from previous
                        current_occupied = sum(base_template_2(:));
                        target_occupied = round(p_values(p_idx) * L3);
                        additional_needed = target_occupied - current_occupied;
                        
                        if additional_needed > 0
                            unoccupied = ~base_template_2;
                            idx_unocc = find(unoccupied);
                            if length(idx_unocc) >= additional_needed
                                selected = idx_unocc(randperm(length(idx_unocc), additional_needed));
                                base_template_2(selected) = true;
                            else
                                % Fill all remaining sites
                                base_template_2(idx_unocc) = true;
                            end
                        end
                        lattice = base_template_2;
                    end
                    
                case 3  % Independent random
                    lattice = rand(L, L, L) < p_values(p_idx);
            end
            
            % Store the lattice
            bw = lattice > 0;
            Lattice(:, p_idx, lattice_type) = bw(:);
            
            % Verify the density achieved
            achieved_density = sum(bw(:)) / L3;
            fprintf('  Type %d: Target=%.4f, Achieved=%.4f\n', ...
                lattice_type, p_values(p_idx), achieved_density);
        end
    end
    
    % Save results with proper path handling
    mat_file_out = fullfile(output_dir, sprintf('Lattice_Clusters_%d.mat', ii));
    
    try
        save(mat_file_out, 'Lattice', 'p_values', 'L', 'ii');
        fprintf('Successfully saved: %s\n', mat_file_out);
    catch ME
        fprintf('Error saving file: %s\n', ME.message);
    end
    
    % Optional: Save summary statistics
    summary_file = fullfile(output_dir, sprintf('Lattice_Summary_%d.txt', ii));
    fid = fopen(summary_file, 'w');
    if fid > 0
        fprintf(fid, 'Lattice Generation Summary - Run %d\n', ii);
        fprintf(fid, 'Parameters: L=%d, L3=%d\n', L, L3);
        fprintf(fid, 'P-values: %s\n', mat2str(p_values));
        fprintf(fid, '\nDensity Achievement:\n');
        fprintf(fid, 'P-value\tType1\tType2\tType3\n');
        for p_idx = 1:Np
            densities = zeros(1, 3);
            for lattice_type = 1:3
                densities(lattice_type) = sum(Lattice(:, p_idx, lattice_type)) / L3;
            end
            fprintf(fid, '%.4f\t%.4f\t%.4f\t%.4f\n', p_values(p_idx), densities);
        end
        fclose(fid);
        fprintf('Summary saved: %s\n', summary_file);
    end
end

fprintf('Cluster generation complete!\n');
