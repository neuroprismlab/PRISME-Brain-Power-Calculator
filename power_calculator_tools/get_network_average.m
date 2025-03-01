function [cluster_stat] = get_network_average(test_stat, edge_groups)
    %GET_CONSTRAINED_STATS
    % Summarize stats by network defined by atlas (edge_groups is now a double matrix)
    % TODO: Add option to scale by weight
    % TODO: Consider calculating variance within each network
    % TODO: Ensure symmetry or force to be upper/lower triangular
    
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