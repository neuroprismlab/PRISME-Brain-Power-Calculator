classdef Exact_FC_TFCE_cpp
    
    properties 
        level = "edge";
        permutation_based = true;
        permutations = 800; % Override permutation number
        method_params = Exact_FC_TFCE_cpp.get_tfce_params()
    end

    methods (Static, Access = private)
        function method_params = get_tfce_params()
            method_params = struct();
            method_params.H = 3.0;
            method_params.E = 0.4;
        end
    end

   methods

        function pval = run_method(obj,varargin)
            
            % Extract parameters 
            params = struct(varargin{:});
            STATS = params.statistical_parameters;
            edge_stats = params.edge_stats;
            permuted_edge_stats = params.permuted_edge_data; 
        
            % Convert the edge statistics back into a matrix
            test_stat_mat = STATS.unflatten_matrix(edge_stats);
           
            cluster_stats_target = exact_tfce_cpp(double(test_stat_mat), double(obj.method_params.H), ...
                double(obj.method_params.E));
            cluster_stats_target = STATS.flatten_matrix(cluster_stats_target);

            % Ensure permutation data is provided
            if isempty(permuted_edge_stats)
                error('Permutation data is missing. Ensure precomputed permutations are provided.');
            end

            % Number of permutations
            if size(permuted_edge_stats, 2) < obj.permutations
                K = size(permuted_edge_stats, 2);
            else
                K = obj.permutations;
            end
            null_dist = zeros(K, 1);
        
            % Apply TFCE transformation to each permutation
            for i = 1:K
                perm_stat_mat = STATS.unflatten_matrix(permuted_edge_stats(:, i));
                tfce_null = exact_tfce_cpp(double(perm_stat_mat), double(obj.method_params.H), ...
                    double(obj.method_params.E));
                null_dist(i) = max(tfce_null(:)); % Store max TFCE value for permutation
            end
            
            % Compute p-values using permutation-based FWER correction
            pval = arrayfun(@(stat) (sum(stat <= null_dist)) /K, cluster_stats_target);

        end

    end
end