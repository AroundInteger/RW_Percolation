% RW3D_paper_batch.m
% Usage: matlab -nodisplay -r "RW3D_paper_batch(p_idx)"
% Where p_idx = 1, 2, 3, or 4 (for p = 0, 0.3116, 0.6884, 0.75)
% Saves both .csv and .mat files

function RW3D_paper_batch(p_idx,seed)
    
    % Parameters
    L = 500;
    L3 = L^3;
    LW = 1e6;
    NW = 1e3;
    p = [0, 0.3116, 0.6884, 0.75];
    Np = numel(p);
    t = (1:LW)';
    rng(seed); % For reproducibility

    if nargin < 1
        error('Usage: RW3D_paper_batch(p_idx) with p_idx = 1..4');
    end
    if p_idx < 1 || p_idx > Np
        error('p_idx must be 1..4');
    end

    fprintf('Starting simulation for p = %.4f (job %d/4)\n', p(p_idx), p_idx);
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

    % Save as CSV (for Python compatibility)
    csv_outname = sprintf('msd_results_L100_p%.4f.csv', p(p_idx));
    T = table(t, x, y, z, msd, 'VariableNames', {'step', 'x', 'y', 'z', 'msd'});
    writetable(T, csv_outname);
    fprintf('Saved CSV: %s\n', csv_outname);

    % Save as MAT (for MATLAB analysis)
    mat_outname = sprintf('msd_results_L100_p%.4f.mat', p(p_idx));
    save(mat_outname, 't', 'msd', 'x', 'y', 'z', 'bw', 'p_idx', 'p', 'L', 'LW', 'NW', 'runtime');
    fprintf('Saved MAT: %s\n', mat_outname);

    % Print summary statistics
    fprintf('Final MSD: %.2f\n', msd(end));
    fprintf('Job %d completed successfully!\n', p_idx);
end 