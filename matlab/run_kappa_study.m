% run_kappa_study.m
%
% Entry-point script for the kappa-mixing tunable gel-point study.
% Runs RW3D_kappa_mixing_study.m then analyze_kappa_gel_points.m in sequence.
%
% Usage — MATLAB command line:
%   >> run_kappa_study              % quick mode (default)
%   >> MODE = 'production'; run_kappa_study
%
% Usage — headless batch (terminal):
%   nohup /Applications/MATLAB_R2025a.app/bin/matlab -nodisplay \
%       -r "run_kappa_study; exit" \
%       > kappa_study_quick.log 2>&1 &
%
%   nohup /Applications/MATLAB_R2025a.app/bin/matlab -nodisplay \
%       -r "MODE='production'; run_kappa_study; exit" \
%       > kappa_study_production.log 2>&1 &
%
% Resume after interruption:
%   Existing .mat files are skipped automatically — just re-run the same command.

% =========================================================================
% MODE
% =========================================================================
if ~exist('MODE', 'var')
    MODE = 'quick';
end

fprintf('\n========================================\n');
fprintf('  KAPPA-MIXING STUDY  [mode = %s]\n', MODE);
fprintf('  %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('========================================\n\n');

% =========================================================================
% PARALLEL POOL — start explicitly so overhead is paid once
% =========================================================================
if isempty(gcp('nocreate'))
    try
        parpool('local');   % uses all available cores
        fprintf('Parallel pool started.\n\n');
    catch ME
        fprintf('Warning: could not start parallel pool (%s).\n', ME.message);
        fprintf('Running without parallelism — will be slower.\n\n');
    end
end

% =========================================================================
% STEP 1 — SIMULATION
% =========================================================================
fprintf('--- STEP 1: Running simulations ---\n');
t_sim_start = tic;

try
    RW3D_kappa_mixing_study;
catch ME
    fprintf('\nERROR in RW3D_kappa_mixing_study: %s\n', ME.message);
    fprintf('Check the output directory for partial results.\n');
    rethrow(ME);
end

t_sim = toc(t_sim_start);
fprintf('\nSimulations completed in %.1f min.\n\n', t_sim / 60);

% =========================================================================
% STEP 2 — GEL-POINT ANALYSIS
% =========================================================================
fprintf('--- STEP 2: Extracting gel-points ---\n');

try
    analyze_kappa_gel_points(MODE);
catch ME
    fprintf('\nERROR in analyze_kappa_gel_points: %s\n', ME.message);
    fprintf('You can re-run this step manually: analyze_kappa_gel_points(''%s'')\n', MODE);
    rethrow(ME);
end

% =========================================================================
% DONE
% =========================================================================
fprintf('\n========================================\n');
fprintf('  ALL DONE  [%s]\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('  Total elapsed: %.1f min\n', toc(t_sim_start) / 60);
fprintf('========================================\n');
