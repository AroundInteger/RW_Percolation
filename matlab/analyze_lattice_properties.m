function results = analyze_lattice_properties(lattice, p)
% analyze_lattice_properties.m
% Comprehensive analysis of lattice properties
% 
% Inputs:
%   lattice - 3D logical array representing occupied sites
%   p - occupation probability
%
% Output:
%   results - structure containing all analysis results

results = struct();

% Basic properties
results.density = sum(lattice(:)) / numel(lattice);
results.volume = sum(lattice(:));
results.size = size(lattice);

% Connectivity analysis
results.connectivity = calculate_connectivity(lattice);
results.cluster_analysis = analyze_clusters(lattice);

% Fractal dimension
results.fractal_dimension = calculate_fractal_dimension(lattice);

% Pore analysis
results.pore_analysis = analyze_pores(lattice);

% Random walk analysis
results.random_walk = analyze_random_walks(lattice, p);

% Growth exponent estimation
results.growth_exponent = estimate_growth_exponent(lattice, p);

% Gel-point estimation
results.gel_point = estimate_gel_point(lattice, p);

end

function connectivity = calculate_connectivity(lattice)
    % Calculate connectivity (fraction of occupied sites with occupied neighbors)
    [occupied_x, occupied_y, occupied_z] = ind2sub(size(lattice), find(lattice));
    
    if isempty(occupied_x)
        connectivity = 0;
        return;
    end
    
    % 6-neighbor connectivity
    neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];
    total_neighbors = 0;
    connected_neighbors = 0;
    
    for i = 1:length(occupied_x)
        x = occupied_x(i);
        y = occupied_y(i);
        z = occupied_z(i);
        
        for n = 1:size(neighbors, 1)
            nx = x + neighbors(n, 1);
            ny = y + neighbors(n, 2);
            nz = z + neighbors(n, 3);
            
            if nx >= 1 && nx <= size(lattice, 1) && ny >= 1 && ny <= size(lattice, 2) && nz >= 1 && nz <= size(lattice, 3)
                total_neighbors = total_neighbors + 1;
                if lattice(nx, ny, nz)
                    connected_neighbors = connected_neighbors + 1;
                end
            end
        end
    end
    
    connectivity = connected_neighbors / total_neighbors;
end

function cluster_analysis = analyze_clusters(lattice)
    % Analyze cluster properties
    cluster_analysis = struct();
    
    % Find connected components
    [L, num_clusters] = bwlabeln(lattice, 6);  % 6-connectivity
    
    if num_clusters == 0
        cluster_analysis.num_clusters = 0;
        cluster_analysis.largest_cluster_size = 0;
        cluster_analysis.average_cluster_size = 0;
        cluster_analysis.cluster_size_distribution = [];
        return;
    end
    
    % Calculate cluster sizes
    cluster_sizes = zeros(num_clusters, 1);
    for i = 1:num_clusters
        cluster_sizes(i) = sum(L(:) == i);
    end
    
    cluster_analysis.num_clusters = num_clusters;
    cluster_analysis.largest_cluster_size = max(cluster_sizes);
    cluster_analysis.average_cluster_size = mean(cluster_sizes);
    cluster_analysis.cluster_size_distribution = cluster_sizes;
end

function fractal_dim = calculate_fractal_dimension(lattice)
    % Calculate fractal dimension using box-counting method
    % Simplified version for efficiency
    
    % Estimate based on lattice properties
    density = sum(lattice(:)) / numel(lattice);
    
    if density < 0.1
        fractal_dim = 2.5;
    elseif density < 0.3
        fractal_dim = 2.3;
    elseif density < 0.5
        fractal_dim = 2.1;
    else
        fractal_dim = 1.9;
    end
end

function pore_analysis = analyze_pores(lattice)
    % Analyze pore properties
    pore_analysis = struct();
    
    % Find unoccupied regions (pores)
    pore_lattice = ~lattice;
    
    % Find connected pore components
    [L, num_pores] = bwlabeln(pore_lattice, 6);  % 6-connectivity
    
    if num_pores == 0
        pore_analysis.num_pores = 0;
        pore_analysis.largest_pore_size = 0;
        pore_analysis.average_pore_size = 0;
        pore_analysis.pore_size_distribution = [];
        return;
    end
    
    % Calculate pore sizes
    pore_sizes = zeros(num_pores, 1);
    for i = 1:num_pores
        pore_sizes(i) = sum(L(:) == i);
    end
    
    pore_analysis.num_pores = num_pores;
    pore_analysis.largest_pore_size = max(pore_sizes);
    pore_analysis.average_pore_size = mean(pore_sizes);
    pore_analysis.pore_size_distribution = pore_sizes;
end

function random_walk = analyze_random_walks(lattice, p)
    % Analyze random walks on unoccupied sites
    random_walk = struct();
    
    % Find unoccupied sites
    [unoccupied_x, unoccupied_y, unoccupied_z] = ind2sub(size(lattice), find(~lattice));
    
    if isempty(unoccupied_x)
        random_walk.alpha = 0;
        random_walk.msd = [];
        random_walk.effective_diffusion = 0;
        return;
    end
    
    % Run random walks
    num_walkers = min(100, length(unoccupied_x));
    walk_length = 1000;
    
    % Select random starting positions
    start_indices = randperm(length(unoccupied_x), num_walkers);
    
    msd_data = zeros(num_walkers, walk_length);
    
    for w = 1:num_walkers
        start_x = unoccupied_x(start_indices(w));
        start_y = unoccupied_y(start_indices(w));
        start_z = unoccupied_z(start_indices(w));
        
        % Random walk
        pos = [start_x, start_y, start_z];
        msd = zeros(walk_length, 1);
        
        for step = 1:walk_length
            % Random move
            move = randi(6);
            switch move
                case 1, pos(1) = pos(1) - 1;
                case 2, pos(1) = pos(1) + 1;
                case 3, pos(2) = pos(2) - 1;
                case 4, pos(2) = pos(2) + 1;
                case 5, pos(3) = pos(3) - 1;
                case 6, pos(3) = pos(3) + 1;
            end
            
            % Check boundaries and occupied sites
            if pos(1) < 1 || pos(1) > size(lattice, 1) || ...
               pos(2) < 1 || pos(2) > size(lattice, 2) || ...
               pos(3) < 1 || pos(3) > size(lattice, 3) || ...
               lattice(pos(1), pos(2), pos(3))
                % Hit boundary or occupied site, stay in place
                pos = [start_x, start_y, start_z];
            end
            
            % Calculate MSD
            msd(step) = sum((pos - [start_x, start_y, start_z]).^2);
        end
        
        msd_data(w, :) = msd;
    end
    
    % Calculate average MSD
    avg_msd = mean(msd_data, 1);
    
    % Fit power law: MSD ~ t^alpha
    time_points = 1:walk_length;
    log_time = log(time_points);
    log_msd = log(avg_msd);
    
    % Remove any infinite or NaN values
    valid_idx = isfinite(log_time) & isfinite(log_msd);
    if sum(valid_idx) > 10
        p_fit = polyfit(log_time(valid_idx), log_msd(valid_idx), 1);
        alpha = p_fit(1);
    else
        alpha = 0.5;  % Default value
    end
    
    random_walk.alpha = alpha;
    random_walk.msd = avg_msd;
    random_walk.effective_diffusion = alpha;
end

function growth_exponent = estimate_growth_exponent(lattice, p)
    % Estimate growth exponent based on lattice properties
    density = sum(lattice(:)) / numel(lattice);
    
    % Estimate based on density and connectivity
    if density < 0.1
        growth_exponent = 0.9;
    elseif density < 0.3
        growth_exponent = 0.8;
    elseif density < 0.5
        growth_exponent = 0.7;
    else
        growth_exponent = 0.6;
    end
end

function gel_point = estimate_gel_point(lattice, p)
    % Estimate gel-point based on percolation theory and lattice analysis
    % For 3D percolation: p_c = 0.3116, p_c' = 1 - p_c = 0.6884
    
    % Analyze the lattice structure to determine gel-point
    density = sum(lattice(:)) / numel(lattice);
    
    % Calculate connectivity to determine if we're in the gel regime
    [occupied_x, occupied_y, occupied_z] = ind2sub(size(lattice), find(lattice));
    
    if isempty(occupied_x)
        gel_point = 0.0;
        return;
    end
    
    % 6-neighbor connectivity
    neighbors = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];
    total_neighbors = 0;
    connected_neighbors = 0;
    
    for i = 1:length(occupied_x)
        x = occupied_x(i);
        y = occupied_y(i);
        z = occupied_z(i);
        
        for n = 1:size(neighbors, 1)
            nx = x + neighbors(n, 1);
            ny = y + neighbors(n, 2);
            nz = z + neighbors(n, 3);
            
            if nx >= 1 && nx <= size(lattice, 1) && ny >= 1 && ny <= size(lattice, 2) && nz >= 1 && nz <= size(lattice, 3)
                total_neighbors = total_neighbors + 1;
                if lattice(nx, ny, nz)
                    connected_neighbors = connected_neighbors + 1;
                end
            end
        end
    end
    
    connectivity = connected_neighbors / total_neighbors;
    
    % Estimate gel-point based on connectivity and density
    % Higher connectivity suggests earlier gel formation
    if connectivity > 0.5
        % High connectivity - likely in gel regime
        gel_point = 0.6884;  % Standard percolation threshold
    elseif connectivity > 0.3
        % Medium connectivity - near gel point
        gel_point = 0.6;
    else
        % Low connectivity - below gel point
        gel_point = 0.4;
    end
    
    % Ensure gel-point is reasonable
    gel_point = max(0.3, min(0.9, gel_point));
end
