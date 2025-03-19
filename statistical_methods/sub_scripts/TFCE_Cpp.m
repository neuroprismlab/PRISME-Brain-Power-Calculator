classdef TFCE_Cpp
    
    properties (Constant)
        level = "edge";
        permutation_based = true;
    end

    methods

        function pval = run_method(~,varargin)

            % Applies Threshold-Free Cluster Enhancement (TFCE) and computes p-values
            % using a permutation-based approach.
            %
            % Inputs:
            %   - STATS: Structure containing statistical parameters, including threshold.
            %   - edge_stats: Raw test statistics for edges.
            %   - permutation_edge_data: Precomputed permutation edge statistics.
            %
            % Outputs:
            %   - pval: TFCE-corrected p-values.
        
            params = struct(varargin{:});
        
            % Extract relevant inputs
            STATS = params.statistical_parameters;
            edge_stats = params.edge_stats;
            permuted_edge_stats = params.permuted_edge_data; % Explicitly using the new argument
        
            % Convert the edge statistics back into a matrix
            test_stat_mat = unflatten_matrix(edge_stats, STATS.mask);
        
            % **Call the C++ MEX function instead of the MATLAB function**
            cluster_stats_target = tfce_mex(test_stat_mat, 'matrix'); 
            cluster_stats_target = flat_matrix(cluster_stats_target, STATS.mask);
        
            % Ensure permutation data is provided
            if isempty(permuted_edge_stats)
                error('Permutation data is missing. Ensure precomputed permutations are provided.');
            end
        
            % Number of permutations
            K = size(permuted_edge_stats, 2);
            null_dist = zeros(K, 1);
        
            % Apply TFCE transformation to each permutation using the MEX function
            for i = 1:K
                perm_stat_mat = unflatten_matrix(permuted_edge_stats(:, i), STATS.mask);
                tfce_null = tfce_mex(perm_stat_mat, 'matrix');  % **Using MEX**
                null_dist(i) = max(tfce_null(:)); % Store max TFCE value for permutation
            end
        
            % Compute p-values using permutation-based FWER correction
            pval = arrayfun(@(stat) (sum(stat <= null_dist)) /K, cluster_stats_target(:));

        end
        
    end

end