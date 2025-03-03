function pval = TFCE(varargin)
    % Applies Threshold-Free Cluster Enhancement (TFCE) and computes p-values.
    %
    % Inputs:
    %   - STATS: Structure containing statistical parameters, including threshold.
    %   - edge_stats: Raw test statistics for edges.
    %
    % Outputs:
    %   - pval: TFCE-corrected p-values.
    
    params = struct(varargin{:});
    
    % Extract relevant inputs
    STATS = params.statistical_parameters;
    GLM = params.glm_parameters;
    edge_stats = params.edge_stats;
    
    % Convert the edge statistics back into a matrix
    test_stat_mat = unflatten_matrix(edge_stats, STATS.mask);
    
    % Apply the TFCE transformation
    cluster_stats_target = matlab_tfce_transform(test_stat_mat, 'matrix');
    
    % Generate null distribution using permutation-based TFCE
    K = GLM.perm; % Number of permutations
    null_dist = zeros(K, 1);
    
    for i = 1:K
        permuted_stats = permute_signal(edge_stats); % Permute test statistics
        perm_stat_mat = unflatten_matrix(permuted_stats, STATS.mask);
        tfce_null = matlab_tfce_transform(perm_stat_mat, 'matrix');
        null_dist(i) = max(tfce_null(:)); % Store max TFCE value for permutation
    end
    
    % Compute p-values: proportion of null values greater than observed TFCE
    pval = arrayfun(@(stat) sum(stat <= null_dist) / K, cluster_stats_target(:));
    
end