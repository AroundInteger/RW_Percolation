function [num_clusters, cluster_sizes, cluster_labels] = analyze_3d_clusters(lattice)
% Analyze 3D clusters using bwconncomp
    
    % Convert to logical for bwconncomp
    bw = logical(lattice);
    
    % Find connected components (6-connectivity for 3D)
    cc = bwconncomp(bw, 6);
    
    num_clusters = cc.NumObjects;
    cluster_sizes = cellfun(@length, cc.PixelIdxList);
    
    % Create cluster labels if requested
    if nargout > 2
        cluster_labels = labelmatrix(cc);
    end
end