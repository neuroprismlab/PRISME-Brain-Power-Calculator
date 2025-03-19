function pval = Multidimensional_cNBS(network_stats, permuted_network_stats)
    % Computes the Multidimensional cNBS Omnibus test treating networks as elements.
    %
    % Inputs:
    %   - STATS: Structure containing statistical parameters.
    %   - edge_stats: Raw test statistics for edges.
    %   - permuted_edge_stats: Precomputed permutation edge statistics.
    %
    % Outputs:
    %   - pval: Single omnibus p-value computed across networks.
    
    % Compute **null centroid** in network-level space
    null_centroid = mean(permuted_network_stats, 2);

    % Compute **Euclidean distance** for null distribution (using networks as elements)
    null_dist = sqrt(sum((permuted_network_stats - null_centroid).^2, 1));

    % Compute **Euclidean distance** for observed network statistics
    observed_dist = sqrt(sum((network_stats - null_centroid).^2));

    % Compute omnibus p-value (probability of more extreme distances)
    pval = sum(observed_dist < null_dist) / length(null_dist);
    
end