function pval = Multidimensional_cNBS(STATS, edge_stats, permuted_edge_stats)
    % Computes the Multidimensional cNBS Omnibus test with per-network statistics.
    %
    % Inputs:
    %   - STATS: Structure containing statistical parameters.
    %   - edge_stats: Raw test statistics for edges.
    %   - permuted_edge_stats: Precomputed permutation edge statistics.
    %
    % Outputs:
    %   - pval: Vector of p-values computed using multidimensional null hypothesis testing (1 per network).

    % Get unique network IDs
    n_networks = numel(STATS.edge_groups.unique);

    % Preallocate p-values
    pval = zeros(n_networks, 1);

    % Iterate over each network separately
    for i = 1:n_networks
        % Get the edges that belong to this network (converted to a flat vector mask)
        network_mask = (STATS.edge_groups.groups == STATS.edge_groups.unique(i));
        network_mask = flat_matrix(network_mask, STATS.mask); % Convert network mask to flat form
        
        % Extract test statistics for this network
        edge_stats_network = edge_stats(network_mask);
        
        % Directly extract corresponding permutation values
        permuted_edge_stats_network = permuted_edge_stats(network_mask, :);

        % Compute null centroid for this network
        null_centroid = mean(permuted_edge_stats_network, 2);

        % Compute Euclidean distance for each permutation
        null_dist = sqrt(sum((permuted_edge_stats_network - null_centroid).^2, 1));

        % Compute Euclidean distance for observed edge statistics
        observed_dist = sqrt(sum((edge_stats_network - null_centroid).^2));

        % Compute p-value for this network
        pval(i) = sum(observed_dist < null_dist) / length(null_dist);
    end

    % If any network shows significance, return pval = 0 (indicating an effect)
    if any(pval < STATS.alpha)
        pval = 0;
    else
        pval = 1;
    end
end