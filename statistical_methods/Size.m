classdef Size
    properties (Constant)
        level = "edge";
        permutation_based = true;
    end

    methods

        function pval = run_method(~,varargin)
            % Performs cluster-based inference using the "Size" method in Network-Based Statistics (NBS).
            %
            % Inputs:
            %   - STATS: Structure containing statistical parameters (threshold, alpha, etc.).
            %   - edge_stats: Test statistics for each edge.
            %   - glm_parameters: Parameters for the General Linear Model (GLM).
            %
            % Outputs:
            %   - pval: FWER-corrected p-values for each network component.
        
            % Parse input arguments
            params = struct(varargin{:});
            STATS = params.statistical_parameters;
            edge_stats_target = params.edge_stats;
            GLM = params.glm_parameters;
            permuted_edge_stats = params.permuted_edge_data;
            
            % Identify significant edges based on primary threshold
            significant_edges = edge_stats_target > STATS.thresh;
        
            % Convert significant edges into an adjacency matrix
            adj = double(STATS.unflatten_matrix(significant_edges));

            % Get number of nodes and edges
            N = size(adj, 1);
        
            % Compute network components (clusters) from the adjacency matrix
            [cluster_stats_target, max_stat_target] = ...
                get_edge_components(adj, false, edge_stats_target, ...
                                    STATS.thresh, N, find(triu(STATS.mask)), exist('components', 'file'));
        
            % Get number of permutations
            K = GLM.perm; 
            % Compute permutation-based null distribution
            null_dist = zeros(K, 1);
            for i = 1:K
                edge_stats_perm = permuted_edge_stats(:, i);
                [~, max_stat] = get_edge_components(STATS.unflatten_matrix(edge_stats_perm > STATS.thresh), ...
                    false, edge_stats_perm, STATS.thresh, N, find(triu(STATS.mask)), exist('components', 'file'));
                null_dist(i) = max_stat;
            end
        
            % Compute FWER-corrected p-values
            flat_target_stat = flat_matrix(cluster_stats_target, STATS.mask);
            pval = arrayfun(@(stat) sum(stat <= null_dist) / K, flat_target_stat);
        
            % Ensure p-values do not exceed 1
            pval = min(pval, 1);
        
        end
        
    end

end
