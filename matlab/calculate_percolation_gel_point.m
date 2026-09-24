function gel_point = calculate_percolation_gel_point(lattice, p)
% calculate_percolation_gel_point.m
% Calculate gel-point based on percolation theory: sample-spanning cluster detection
% 
% Inputs:
%   lattice - 3D logical array representing occupied sites
%   p - occupation probability
%
% Output:
%   gel_point - estimated gel-point based on percolation analysis

% Check if we have a sample-spanning cluster
[Lx, Ly, Lz] = size(lattice);

% Find connected components using 6-connectivity (face neighbors)
[L, num_clusters] = bwlabeln(lattice, 6);

if num_clusters == 0
    gel_point = 0.0;
    return;
end

% Check for sample-spanning clusters
sample_spanning = false;
spanning_cluster_id = 0;

for cluster_id = 1:num_clusters
    cluster_mask = (L == cluster_id);
    
    % Check if cluster spans in x-direction
    x_spanning = any(any(cluster_mask(1, :, :))) && any(any(cluster_mask(end, :, :)));
    
    % Check if cluster spans in y-direction  
    y_spanning = any(any(cluster_mask(:, 1, :))) && any(any(cluster_mask(:, end, :)));
    
    % Check if cluster spans in z-direction
    z_spanning = any(any(cluster_mask(:, :, 1))) && any(any(cluster_mask(:, :, end)));
    
    % Cluster is sample-spanning if it spans in at least one direction
    if x_spanning || y_spanning || z_spanning
        sample_spanning = true;
        spanning_cluster_id = cluster_id;
        break;
    end
end

% Calculate cluster properties
cluster_sizes = zeros(num_clusters, 1);
for i = 1:num_clusters
    cluster_sizes(i) = sum(L(:) == i);
end

largest_cluster_size = max(cluster_sizes);
total_sites = numel(lattice);
largest_cluster_fraction = largest_cluster_size / total_sites;

% Estimate gel-point based on percolation analysis
if sample_spanning
    % We have a sample-spanning cluster - we're at or above the gel-point
    % The gel-point is likely at a lower p-value
    if largest_cluster_fraction > 0.8
        % Very large spanning cluster - well above gel-point
        gel_point = p - 0.1;  % Estimate gel-point was ~0.1 lower
    elseif largest_cluster_fraction > 0.6
        % Large spanning cluster - moderately above gel-point
        gel_point = p - 0.05; % Estimate gel-point was ~0.05 lower
    else
        % Small spanning cluster - just above gel-point
        gel_point = p - 0.02; % Estimate gel-point was ~0.02 lower
    end
else
    % No sample-spanning cluster - we're below the gel-point
    % Estimate gel-point based on largest cluster size
    if largest_cluster_fraction > 0.5
        % Large cluster but not spanning - close to gel-point
        gel_point = p + 0.02;  % Gel-point is slightly higher
    elseif largest_cluster_fraction > 0.3
        % Medium cluster - moderately below gel-point
        gel_point = p + 0.05;  % Gel-point is moderately higher
    else
        % Small clusters - well below gel-point
        gel_point = p + 0.1;   % Gel-point is much higher
    end
end

% Ensure reasonable bounds
gel_point = max(0.0, min(1.0, gel_point));

% Additional refinement based on cluster size distribution
if num_clusters > 1
    % Multiple clusters - we're likely below the gel-point
    gel_point = max(gel_point, p + 0.01);
else
    % Single cluster - we're likely at or above the gel-point
    gel_point = min(gel_point, p);
end

end
