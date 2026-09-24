function [lattice, metadata] = load_lattice_for_microrheology(variant_name, p_value, L, output_dir)
% LOAD_LATTICE_FOR_MICRORHEOLOGY Load individual lattice for microrheological analysis
%
% This function loads a specific lattice variant for microrheological random walk
% analysis on the unoccupied sites.
%
% Inputs:
%   variant_name - String: '6N_Templated', '26N_Templated', 'Density_Increment', 'Random_Percolation'
%   p_value - Occupation probability (e.g., 0.3116, 0.6884)
%   L - Lattice size (e.g., 500)
%   output_dir - Directory containing lattice files (default: 'Clusters')
%
% Outputs:
%   lattice - 3D logical array (true = occupied, false = unoccupied)
%   metadata - Struct with lattice information
%
% Usage:
%   [lat, meta] = load_lattice_for_microrheology('6N_Templated', 0.3116, 500);
%   [lat, meta] = load_lattice_for_microrheology('Random_Percolation', 0.6884, 500, 'custom_dir');

if nargin < 4, output_dir = 'Clusters'; end

% Construct filename based on naming convention
filename = sprintf('Lattice_%s_p%.4f_L%d.mat', variant_name, p_value, L);
filepath = fullfile(output_dir, filename);

% Check if file exists
if ~exist(filepath, 'file')
    error('Lattice file not found: %s\nPlease check variant name, p-value, and lattice size.', filepath);
end

% Load the lattice data
fprintf('Loading lattice: %s\n', filename);
lattice_data = load(filepath);

% Extract lattice and metadata
lattice = logical(lattice_data.lattice);
metadata = struct();

% Basic metadata
metadata.p_value = lattice_data.p_value;
metadata.variant = lattice_data.variant;
metadata.L = lattice_data.L;
metadata.generation_time = lattice_data.generation_time;
metadata.cluster_stats = lattice_data.cluster_stats;

% Enhanced viscoelastic metadata (if available)
if isfield(lattice_data, 'is_critical_region')
    metadata.is_critical_region = lattice_data.is_critical_region;
end
if isfield(lattice_data, 'is_gel_point_region')
    metadata.is_gel_point_region = lattice_data.is_gel_point_region;
end
if isfield(lattice_data, 'expected_behavior')
    metadata.expected_behavior = lattice_data.expected_behavior;
end
if isfield(lattice_data, 'analysis_notes')
    metadata.analysis_notes = lattice_data.analysis_notes;
end

% Verify the loaded data matches requested parameters
if abs(metadata.p_value - p_value) > 1e-6
    warning('Loaded p-value (%.4f) differs from requested (%.4f)', metadata.p_value, p_value);
end

if metadata.L ~= L
    error('Loaded lattice size (%d) differs from requested (%d)', metadata.L, L);
end

if ~strcmp(metadata.variant, variant_name)
    error('Loaded variant (%s) differs from requested (%s)', metadata.variant, variant_name);
end

% Display lattice information
fprintf('Lattice loaded successfully:\n');
fprintf('  Variant: %s\n', metadata.variant);
fprintf('  P-value: %.4f\n', metadata.p_value);
fprintf('  Size: %dx%dx%d\n', size(lattice, 1), size(lattice, 2), size(lattice, 3));
fprintf('  Density: %.4f\n', sum(lattice(:)) / numel(lattice));
fprintf('  Unoccupied sites: %d (for RW analysis)\n', sum(~lattice(:)));

% Verify lattice is logical
if ~islogical(lattice)
    warning('Converting lattice to logical array');
    lattice = logical(lattice);
end

end

function list_available_lattices(output_dir)
% LIST_AVAILABLE_LATTICES List all available lattice files
%
% This helper function lists all available lattice files in the output directory
% to help you see what's available for microrheological analysis.

if nargin < 1, output_dir = 'Clusters'; end

if ~exist(output_dir, 'dir')
    fprintf('Output directory not found: %s\n', output_dir);
    return;
end

% Find all lattice files
lattice_files = dir(fullfile(output_dir, 'Lattice_*.mat'));

if isempty(lattice_files)
    fprintf('No lattice files found in %s\n', output_dir);
    return;
end

fprintf('Available lattice files in %s:\n', output_dir);
fprintf('Total files: %d\n\n', length(lattice_files));

% Group by variant
variants = {'6N_Templated', '26N_Templated', 'Density_Increment', 'Random_Percolation'};
for v = 1:length(variants)
    variant_files = lattice_files(contains({lattice_files.name}, variants{v}));
    if ~isempty(variant_files)
        fprintf('%s (%d files):\n', variants{v}, length(variant_files));
        for f = 1:min(5, length(variant_files)) % Show first 5
            fprintf('  %s\n', variant_files(f).name);
        end
        if length(variant_files) > 5
            fprintf('  ... and %d more\n', length(variant_files) - 5);
        end
        fprintf('\n');
    end
end

fprintf('To load a specific lattice:\n');
fprintf('  [lat, meta] = load_lattice_for_microrheology(''6N_Templated'', 0.3116, 500);\n');
fprintf('  [lat, meta] = load_lattice_for_microrheology(''Random_Percolation'', 0.6884, 500);\n');

end
