classdef Exact_TFCE_IC_cpp

    properties
        level = "edge";
        permutation_based = true;
        permutations = 1000; % Override permutation number
        method_params = Exact_TFCE_IC_cpp.get_exact_tfce_params()
    end

    methods (Static, Access = private)
        function method_params = get_exact_tfce_params()
            % No dh: the exact TFCE integrates piecewise between sorted edge weights.
            method_params = struct();
            method_params.H = 3.0;
            method_params.E = 0.4;
        end
    end

    methods
        function pval = run_method(obj, varargin)
            % Applies the exact Threshold-Free Cluster Enhancement 
            % with an incremental cluster strategy
            params = struct(varargin{:});

            % Extract relevant inputs
            STATS = params.statistical_parameters;
            edge_stats = params.edge_stats;
            permuted_edge_stats = params.permuted_edge_data;

            % Convert the edge statistics back into a matrix
            test_stat_mat = STATS.unflatten_matrix(edge_stats);

            % Apply exact TFCE transformation to the observed test statistics
            cluster_stats_target = ic_exact_tfce(test_stat_mat, ...
                obj.method_params.H, obj.method_params.E);
            cluster_stats_target = STATS.flatten_matrix(cluster_stats_target);

            % Ensure permutation data is provided
            if isempty(permuted_edge_stats)
                error('Permutation data is missing.');
            end

            % Number of permutations
            if size(permuted_edge_stats, 2) < obj.permutations
                K = size(permuted_edge_stats, 2);
            else
                K = obj.permutations;
            end

            null_dist = zeros(K, 1);

            % Apply exact TFCE transformation to each permutation
            for i = 1:K
                perm_stat_mat = STATS.unflatten_matrix(permuted_edge_stats(:, i));
                tfce_null = ic_exact_tfce(perm_stat_mat, ...
                    obj.method_params.H, obj.method_params.E);
                % Store max TFCE value for permutation
                null_dist(i) = max(tfce_null(:)); 
            end

            % Compute p-values using permutation-based FWER correction
            pval = arrayfun(@(stat) (sum(stat <= null_dist)) / K, cluster_stats_target(:));
        end
    end
end