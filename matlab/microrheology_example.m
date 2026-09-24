% MICRORHEOLOGY_EXAMPLE Example script for microrheological analysis
%
% This script demonstrates how to load individual lattice variants and
% prepare them for microrheological random walk analysis on unoccupied sites.
%
% Run this after completing the research_lattice_analysis to see how to
% access the generated lattices for your universality class research.

clear; clc; close all;

fprintf('=== Microrheological Analysis Example ===\n\n');

% Example parameters (adjust based on your generated lattices)
L = 500;
p_values = [0.3116, 0.6884];  % Critical and high percolation regions
variants = {'6N_Templated', '26N_Templated', 'Density_Increment', 'Random_Percolation'};

fprintf('Loading lattices for microrheological analysis...\n\n');

% Load and analyze lattices for each p-value and variant
for p_idx = 1:length(p_values)
    p = p_values(p_idx);
    fprintf('=== P = %.4f ===\n', p);
    
    for v_idx = 1:length(variants)
        variant = variants{v_idx};
        
        try
            % Load the lattice
            [lattice, metadata] = load_lattice_for_microrheology(variant, p, L);
            
            % Prepare for microrheological analysis
            occupied_sites = lattice;           % True = occupied sites
            unoccupied_sites = ~lattice;        % False = unoccupied sites (for RW)
            
            % Calculate key properties for microrheological analysis
            total_sites = numel(lattice);
            num_occupied = sum(occupied_sites(:));
            num_unoccupied = sum(unoccupied_sites(:));
            density = num_occupied / total_sites;
            
            % Display microrheological properties
            fprintf('  %s:\n', variant);
            fprintf('    Total sites: %d\n', total_sites);
            fprintf('    Occupied sites: %d (%.4f)\n', num_occupied, density);
            fprintf('    Unoccupied sites: %d (%.4f) - for RW analysis\n', num_unoccupied, 1-density);
            
            % Calculate connectivity properties (important for universality class)
            [num_clusters, cluster_sizes] = analyze_3d_clusters(lattice);
            if ~isempty(cluster_sizes)
                largest_cluster = max(cluster_sizes);
                avg_cluster_size = mean(cluster_sizes);
                fprintf('    Clusters: %d, largest: %d, avg: %.1f\n', num_clusters, largest_cluster, avg_cluster_size);
            end
            
            % Calculate percolation properties
            if density > 0
                percolation_ratio = largest_cluster / num_occupied;
                fprintf('    Percolation ratio: %.4f\n', percolation_ratio);
            end
            
            fprintf('\n');
            
        catch ME
            fprintf('  %s: Error loading - %s\n', variant, ME.message);
        end
    end
    
    fprintf('\n');
end

fprintf('=== Microrheological Analysis Ready ===\n\n');

% Example of how to use for random walk analysis
fprintf('For random walk analysis on unoccupied sites:\n\n');

% Load a specific example
try
    fprintf('Loading example lattice for demonstration...\n');
    [lattice, metadata] = load_lattice_for_microrheology('6N_Templated', 0.3116, L);
    
    % Prepare for random walk
    unoccupied_sites = ~lattice;  % Sites available for random walkers
    
    fprintf('Example lattice prepared for RW analysis:\n');
    fprintf('  Variant: %s\n', metadata.variant);
    fprintf('  P-value: %.4f\n', metadata.p_value);
    fprintf('  Available sites for RW: %d\n', sum(unoccupied_sites(:)));
    
    % Show a 2D slice for visualization
    z_slice = round(L/2);
    slice_2d = lattice(:, :, z_slice);
    unoccupied_slice = unoccupied_sites(:, :, z_slice);
    
    figure('Position', [100, 100, 800, 400]);
    
    subplot(1, 2, 1);
    imagesc(slice_2d);
    title(sprintf('Occupied Sites (p=%.4f)', metadata.p_value));
    axis equal tight;
    colormap(gca, 'hot');
    
    subplot(1, 2, 2);
    imagesc(unoccupied_slice);
    title('Unoccupied Sites (for RW)');
    axis equal tight;
    colormap(gca, 'hot');
    
    sgtitle(sprintf('Lattice Slice: %s, L=%d, z=%d', metadata.variant, L, z_slice));
    
    fprintf('  Visualization created - check the figure\n');
    
catch ME
    fprintf('Error in example: %s\n', ME.message);
end

fprintf('\n=== Next Steps for Universality Class Research ===\n');
fprintf('1. Load lattices using load_lattice_for_microrheology()\n');
fprintf('2. Extract unoccupied sites: unoccupied_sites = ~lattice\n');
fprintf('3. Run random walks on unoccupied sites\n');
fprintf('4. Analyze MSD behavior for different variants\n');
fprintf('5. Compare universality classes across variants\n\n');

fprintf('Example usage:\n');
fprintf('  [lat, meta] = load_lattice_for_microrheology(''Random_Percolation'', 0.6884, 500);\n');
fprintf('  rw_sites = ~lat;  % Sites for random walk analysis\n');
fprintf('  % Now run your microrheological simulation on rw_sites\n');
