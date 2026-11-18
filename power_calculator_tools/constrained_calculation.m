function pval_uncorr = constrained_calculation( ...
    flat_edge_groups, ...
    edge_stats, ...
    permuted_edge_stats ...
    )
 
    % Compute cluster statistics for the observed data
    cluster_stats_target = get_constrained_stats(edge_stats, flat_edge_groups);

    % Number of permutations
    K = size(permuted_edge_stats, 2);
    null_dist = zeros(K, size(cluster_stats_target, 2)); % Store permutation null distribution

    % Compute cluster statistics for each permutation
    for i = 1:K
        null_stat = get_constrained_stats(permuted_edge_stats(:, i), flat_edge_groups);
        null_dist(i, :) = null_stat;  % Store in permutation null distribution
    end

    pval_uncorr = zeros(size(cluster_stats_target));

    % Compute permutation-based p-values for each cluster
    for i = 1:numel(cluster_stats_target)
        pval_uncorr(i) = sum(cluster_stats_target(i) <= null_dist(:, i)) / K;
    end

end