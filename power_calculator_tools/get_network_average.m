function [cluster_stat] = get_network_average(test_stat, edge_groups)
%% get_network_average
% Summarizes test statistics by averaging values within networks defined by edge_groups.
%
% Inputs:
%   - test_stat: Square, symmetric matrix of test statistics.
%   - edge_groups: Matrix with network IDs (nonzero indicates network membership).
%
% Outputs:
%   - cluster_stat: 1×N vector of mean test statistics for each network.
%
% Author: Fabricio Cravo | Date: March 2025
    
    % Ensure test_stat is square and symmetric
    if size(test_stat,1) ~= size(test_stat,2)
        error('Input test statistic matrix is not square');
    end
    
    if any(test_stat - test_stat', 'all')
        error('Input test statistic matrix is not symmetric');
    end
    
    % Extract unique network IDs (excluding zero, assuming 0 means "no network")
    unique_groups = unique(edge_groups(edge_groups > 0)); 
    
    % Preallocate cluster_stat array
    cluster_stat = zeros(1, length(unique_groups));
    
    % Compute mean test statistic for each network
    for i = 1:length(unique_groups)
        group_ids = (edge_groups == unique_groups(i));  % Find edges in the network
        cluster_stat(i) = mean(test_stat(group_ids));   % Average test stats within group
    end

end