% RW3D_paper_batch_p_seed_SCRIPT.m
% Usage: matlab -nodisplay -r "RW3D_paper_batch(p_idx)"
% Where p_idx = 1, 2, 3, or 4 (for p = 0, 0.3116, 0.6884, 0.75)
% Saves both .csv and .mat files

%function RW3D_paper_batch_p_seed(p_idx,seed)

% Parameters
L = 500;
L3 = L^3;
LW = 1e6;
NW = 3e3;
p_c_prime = 0.6884;
%p = [0, 0.3116, 0.6884, 0.75];
%p = [0.1, 0.3116, 0.5, 0.65];
p = [0:0.05:0.3, 0.3116,0.35:0.05:0.6,linspace(0.6,0.75,21),p_c_prime, 0.8, 0.85, 0.9, 0.95];
p = unique(p);

Np = numel(p);
t = (1:LW)';

for ii = 3
    rng(23*ii); % For reproducibility

    % if nargin < 1
    %     error('Usage: RW3D_paper_batch(p_idx) with p_idx = 1..4');
    % end
    % if p_idx < 1 || p_idx > Np
    %     error('p_idx must be 1..4');
    %end
    MSD = [];
    %%
    for p_idx = 1:Np

        fprintf('Starting simulation for Cluster %i  p = %.4f (job %d/%d)\n',ii, p(p_idx), p_idx,Np);
        fprintf('Parameters: L=%d, steps=%d, walkers=%d\n', L, LW, NW);

        % --- Templating logic ---
        % Load or build up the template for this p_idx
        base_template = zeros(L, L, L);
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
        bw = base_template;

        % Find free positions
        [px, py, pz] = ind2sub([L, L, L], find(~bw));
        N_rsp = numel(px);
        if N_rsp < NW
            error('Not enough free sites for walkers at p=%.4f', p(p_idx));
        end
        rp = ceil(rand(NW, 1) * N_rsp);
        rsp = [px(rp), py(rp), pz(rp)];

        fprintf('Running %d walkers for %d steps...\n', NW, LW);
        tic;

        x = zeros(LW, NW); y = x; z = x;
        parfor i_rw = 1:NW
            [xyz, ~] = RW3D_P_SP(bw, LW, L, rsp(i_rw,:), [20, 5]);
            x(:, i_rw) = xyz(:, 1);
            y(:, i_rw) = xyz(:, 2);
            z(:, i_rw) = xyz(:, 3);
        end

        runtime = toc;
        fprintf('Simulation completed in %.2f seconds\n', runtime);

        % Calculate MSD
        dx = x - x(1, :);
        dy = y - y(1, :);
        dz = z - z(1, :);
        sd = dx.^2 + dy.^2 + dz.^2;
        msd = mean(sd, 2);
        tau_msd = movmean(msd,10);

        MSD = [MSD,msd]; %#ok<*AGROW>

        % % Save as CSV (for Python compatibility)
        % csv_outname = sprintf('TEST_New_msd_results_L100_p%.4f.csv', p(p_idx));
        % T = table(t, x, y, z, msd, tau_msd, 'VariableNames', {'step', 'x', 'y', 'z', 'msd', 'lag_msd'});
        % writetable(T, csv_outname);
        % fprintf('Saved CSV: %s\n', csv_outname);
        %
        % % Save as MAT (for MATLAB analysis)
        % mat_outname = sprintf('TEST_New_msd_results_L100_p%.4f.mat', p(p_idx));
        % save(mat_outname, 't', 'msd', 'x', 'y', 'z', 'bw', 'p_idx', 'p', 'L', 'LW', 'NW', 'runtime');
        %fprintf('Saved MAT: %s\n', mat_outname);

        % Print summary statistics
        fprintf('Final MSD: %.2f\n', msd(end));
        fprintf('Job %d completed successfully!\n', p_idx);

    end

    figure(1),loglog(t,MSD)
    figure(2),loglog(t,movmean(MSD,10,1))

    %figure(2),plot(t,MSD);
    pause(1)



    %% Create variable names based on the number of columns in MSD
    variableNames = strcat('MSD_', string(p(1:size(MSD, 2))));
    % Convert MSD to a table with the correct variable names
    MSD_table = array2table(MSD, 'VariableNames', variableNames);

    % Create the final table with t
    %dataTable = table(t,'time', MSD_table);


    % % Specify the filename
    % filename = sprintf('/Users/rowanbrown/Documents/GitHub/RW_Percolation/matlab/Clusters/p_output_C%i.csv',ii);
    %
    % % Write the table to a CSV file
    % writetable(MSD_table, filename);

    % Write the table to a CSV file
    % Assuming MSD_table is already defined in your workspace
    mat_file_out = sprintf('/Users/rowanbrown/Documents/GitHub/RW_Percolation/matlab/Clusters/iMacBook_MSD_table_%i.mat',ii); % Specify the filename
    csv_file_out = sprintf('/Users/rowanbrown/Documents/GitHub/RW_Percolation/matlab/Clusters/iMacBook_MSD_table_%i.csv',ii); % Specify the filename
    save(mat_file_out, 'MSD_table'); % Save the variable to the MAT-file
    writetable(MSD_table, csv_file_out);


end

%%
% id = t> 1e3;
% alpha_exponent = size(p);
%
% for loop = 1:numel(p)
%
%     pm = polyfit(log10(t(id)),log10(MSD(id,loop)),1);
%
%     alpha_exponent(loop) = pm(1);
%
% end
%
% figure(3),plot(p, alpha_exponent,'o-')
% %%
% figure(4);plot(log10(t),log10(MSD(:,1:5)),log10(t),log10(t)-[0, 0.33,0.56,0.73,0.87],'w--',log10(t),[0.8,0.7,0.5,0.4].*log10(t)+[0.06,0.07,0.15,0.16],'y--')
% axis([0 4 -1 3])
% t_log = log10(t);
% y1 = log10(t)-0.87;
% y2 = 0.4.*log10(t)+0.16;
% y = log10(MSD(:,5));
% y_cr_id = find(abs(y-y1)<0.01,1,"first");
% y_ad_id = find(abs(y-y2)<0.01,1,"last");
% pf = polyfit(t_log([y_ad_id,y_cr_id]),y([y_ad_id,y_cr_id]),1);
%
% t_ad = linspace(t_log(y_ad_id),t_log(y_cr_id))';
% y_ad = polyval(pf,t_ad ,50);
%
% figure(5);plot(log10(t),log10(MSD(:,1:5)),log10(t),y1,'w--',log10(t),y2,'y--',t_log(y_cr_id),y(y_cr_id),'^m',t_log(y_ad_id),y(y_ad_id),'^w',t_ad,y_ad,'y:')
% axis([0 4 -1 3])
