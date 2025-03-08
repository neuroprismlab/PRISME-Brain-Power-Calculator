function pval_uncorr = constrained_calculation(STATS, edge_stats, permuted_edge_stats)

    % Get number of nodes
    N = STATS.N;
    
    % Convert edge statistics back into a matrix
    test_stat_mat = unflatten_matrix(edge_stats, STATS.mask);
    
    % Compute cluster statistics for the observed data
    cluster_stats_target = get_constrained_stats(test_stat_mat, STATS.edge_groups);

    % Number of permutations
    K = size(permuted_edge_stats, 2);
    null_dist = zeros(K, size(cluster_stats_target, 2)); % Store permutation null distribution

    % Compute cluster statistics for each permutation
    for i = 1:K
        perm_stat_mat = unflatten_matrix(permuted_edge_stats(:, i), STATS.mask);
        null_stat = get_constrained_stats(perm_stat_mat, STATS.edge_groups);
        null_dist(i, :) = null_stat;  % Store in permutation null distribution
    end

    pval_uncorr = zeros(size(cluster_stats_target));

    % Compute permutation-based p-values for each cluster
    for i = 1:numel(cluster_stats_target)
        pval_uncorr(i) = sum(cluster_stats_target(i) <= null_dist(:, i)) / K;
    end

end