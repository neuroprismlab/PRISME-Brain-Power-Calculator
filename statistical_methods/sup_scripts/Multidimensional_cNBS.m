function pval = Multidimensional_cNBS(edge_stats, permuted_edge_stats)
    % Computes the Multidimensional cNBS Omnibus test.
    %
    % Inputs:
    %   - STATS: Structure containing statistical parameters.
    %   - edge_stats: Raw test statistics for edges.
    %   - permuted_edge_stats: Precomputed permutation edge statistics.
    %
    % Outputs:
    %   - pval: P-values computed using multidimensional null hypothesis testing.

    % Compute null centroid (average of null distributions)
    null_centroid = mean(permuted_edge_stats, 2);  

    % Compute Euclidean distance for each permutation
    null_dist = sqrt(sum((permuted_edge_stats - null_centroid).^2, 1));

    % Compute Euclidean distance for observed edge statistics
    observed_dist = sqrt(sum((edge_stats - null_centroid).^2));

    % Compute p-value based on permutation distribution
    pval = sum(observed_dist < null_dist) / length(null_dist);

end