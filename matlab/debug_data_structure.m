% debug_data_structure.m
% Quick diagnostic to understand the data structure

clear; close all; clc;

fprintf('=== DATA STRUCTURE DIAGNOSTIC ===\n\n');

% Check obstruction results
obstruction_file = 'Clusters/obstruction_probability_analysis.mat';
if exist(obstruction_file, 'file')
    fprintf('Loading obstruction results...\n');
    load(obstruction_file);
    fprintf('Obstruction results variables:\n');
    whos
    fprintf('\n');
    
    if exist('obstruction_results', 'var')
        fprintf('obstruction_results fields:\n');
        fieldnames(obstruction_results)
        
        % Check a specific variant
        if isfield(obstruction_results, 'Templated_6N')
            fprintf('\nTemplated_6N fields:\n');
            fieldnames(obstruction_results.Templated_6N)
        end
    end
else
    fprintf('Obstruction file not found: %s\n', obstruction_file);
end

fprintf('\n');

% Check MSD results
msd_file = 'Clusters/universality_class_analysis.mat';
if exist(msd_file, 'file')
    fprintf('Loading MSD results...\n');
    load(msd_file);
    fprintf('MSD results variables:\n');
    whos
    fprintf('\n');
    
    if exist('alpha_results', 'var')
        fprintf('alpha_results fields:\n');
        fieldnames(alpha_results)
    end
else
    fprintf('MSD file not found: %s\n', msd_file);
end

fprintf('\n=== DIAGNOSTIC COMPLETE ===\n');
