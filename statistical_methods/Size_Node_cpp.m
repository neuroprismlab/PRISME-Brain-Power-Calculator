classdef Size_Node_cpp
    properties (Constant)
        level = 'node';
        permutation_based = true;
    end

    methods

        function pval = run_method(~,varargin)

            params = struct(varargin{:});
            STATS = params.statistical_parameters;
            edge_stats_target = params.edge_stats;
            permuted_edge_stats = params.permuted_edge_data;

            sparse_graph_stats = STATS.unflatten_matrix(edge_stats_target) > STATS.thresh;
            [I, J, ~] = find(sparse_graph_stats);
            cluster_size_per_variable = sparse_size_pval_cpp(double(I), double(J), ...
                double(size(sparse_graph_stats)));
            
            perms_max_cluster_size = zeros(1, STATS.n_perms);
            for p = 1:STATS.n_perms
                sparse_graph_stats = STATS.unflatten_matrix(permuted_edge_stats(:, p)) > STATS.thresh;
                [I, J, ~] = find(sparse_graph_stats);
                cluster_size_per_perm = sparse_size_pval_cpp(double(I), double(J), ...
                    double(size(sparse_graph_stats)));
                perms_max_cluster_size(1, p) = max(cluster_size_per_perm);
            end
            
            % Compare each variable 
            % P-value = (number of permutations with max cluster size >= observed cluster size) 
            % / total permutations
            pval = zeros(size(cluster_size_per_variable));
            for i = 1:length(cluster_size_per_variable)
                observed_cluster_size = cluster_size_per_variable(i);
                
                if observed_cluster_size == 0
                    % Inactive voxels get p-value = 1 (not significant)
                    pval(i) = 1.0;
                else
                    % Count how many permutations had max cluster size >= observed
                    n_exceeding = sum(perms_max_cluster_size >= observed_cluster_size);
                    pval(i) = n_exceeding / STATS.n_perms;
                end
            end
          
        end
        
    end

end
