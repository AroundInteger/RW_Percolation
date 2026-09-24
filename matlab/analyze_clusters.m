%% Helper Function for Cluster Analysis
function [num_clusters, cluster_sizes, cluster_labels] = analyze_clusters(lattice)
    % Analyze connectivity using bwlabel
    cluster_labels = bwlabel(lattice, 4); % 4-connectivity
    num_clusters = max(cluster_labels(:));
    
    if num_clusters == 0
        cluster_sizes = [];
        return;
    end
    
    cluster_sizes = zeros(num_clusters, 1);
    for i = 1:num_clusters
        cluster_sizes(i) = sum(cluster_labels(:) == i);
    end
end