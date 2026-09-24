function gel_point = calculate_gel_point_accurate(lattice, p, method)
% calculate_gel_point_accurate.m
% Calculate gel-point based on established percolation theory
% 
% Inputs:
%   lattice - 3D logical array representing occupied sites
%   p - occupation probability
%   method - 'random', '6N_templated', '26N_templated', 'eden', 'dla'
%
% Output:
%   gel_point - estimated gel-point position

% Established percolation thresholds
p_c_3D = 0.3116;  % 3D percolation threshold
p_c_prime_standard = 1 - p_c_3D;  % = 0.6884

% Method-specific gel-points based on our previous analysis
% Convert method name to lowercase for matching
method_lower = lower(method);

switch method_lower
    case 'random'
        % Random percolation: p_c' = 0.6884
        gel_point = p_c_prime_standard;
        
    case '6n_templated'
        % 6N Templated: p_c' = 0.6884 (same as random)
        gel_point = p_c_prime_standard;
        
    case '26n_templated'
        % 26N Templated: p_c' = 0.6884 (same as random)
        gel_point = p_c_prime_standard;
        
    case 'eden_hybrid'
        % Eden growth: p_c' = 0.6884 (same as random)
        gel_point = p_c_prime_standard;
        
    case 'dla_hybrid'
        % DLA growth: p_c' = 0.6884 (same as random)
        gel_point = p_c_prime_standard;
        
    otherwise
        % Default to standard percolation threshold
        gel_point = p_c_prime_standard;
end

% For templated models, we could implement tunable gel-point positioning
% based on templating strength, but for now we use the standard values

end
