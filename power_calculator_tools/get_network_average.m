function cluster_stat = get_network_average(test_stat_flat, edge_groups_flat)
%% get_network_average - Performance-optimized O(n) version
    % Base case to avoid crashes
    if isempty(edge_groups_flat)
        cluster_stat = [];
        return;
    end

     % Filter out unassigned edges (group ID = 0)
    valid_mask = edge_groups_flat > 0;

    % Vectorized calculation using accumarray - O(n) operation
    cluster_stat = accumarray(edge_groups_flat(valid_mask), test_stat_flat(valid_mask), [], @mean)';
    
end