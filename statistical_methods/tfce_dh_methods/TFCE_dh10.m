classdef TFCE_dh100
    
    properties (Constant)
        level = "edge";
        permutation_based = true;
        permutations = 800; % Override permutation number, not implemented yet
        
        method_params = TFCE_dh100.get_tfce_params()
    end

    methods (Static, Access = private)
        function method_params = get_tfce_params()
            method_params = struct();
            method_params.dh = 0.1;
            method_params.H = 3.0;
            method_params.E = 0.4;
        end
    end

    methods

        function pval = run_method(obj,varargin)

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

            % Apply TFCE transformation to the observed test statistics
            cluster_stats_target = matlab_tfce_transform(test_stat_mat, 'dh', obj.method_params.dh, ...
                'H',  obj.method_params.H, 'E', obj.method_params.E);
            cluster_stats_target = flat_matrix(cluster_stats_target, STATS.mask);
        
            % Ensure permutation data is provided
            if isempty(permuted_edge_stats)
                error('Permutation data is missing. Ensure precomputed permutations are provided.');
            end
        
            % Number of permutations
            K = size(permuted_edge_stats, 2);
            null_dist = zeros(K, 1);
        
            % Apply TFCE transformation to each permutation
            for i = 1:K
                perm_stat_mat = unflatten_matrix(permuted_edge_stats(:, i), STATS.mask);
                tfce_null = matlab_tfce_transform(perm_stat_mat, 'dh', obj.method_params.dh, ...
                    'H',  obj.method_params.H, 'E', obj.method_params.E);
                null_dist(i) = max(tfce_null(:)); % Store max TFCE value for permutation
            end
        
            % Compute p-values using permutation-based FWER correction
            pval = arrayfun(@(stat) (sum(stat <= null_dist)) /K, cluster_stats_target(:));

        end
        
    end

end