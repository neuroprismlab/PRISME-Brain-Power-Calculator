classdef Size_cpp
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
        
            % Get number of nodes and edges
            %N = STATS.N;
            %J = N * (N - 1) / 2;  % Number of edges in an upper-triangular matrix

            edge_stats_mask = unflatten_matrix(edge_stats_target, STATS.mask) > STATS.thresh;
            
            % Pre-allocate the output array
            N = size(STATS.mask, 1);
            permuted_edge_stats_mask = false(N, N, size(permuted_edge_stats, 2));

            for p = 1:size(permuted_edge_stats, 2)
                permuted_edge_stats_mask(:, :, p) = unflatten_matrix(permuted_edge_stats(:, p), STATS.mask) ...
                    > STATS.thresh;
            end
            
            pval = size_pval_cpp(double(edge_stats_mask), double(permuted_edge_stats_mask));
            pval = flat_matrix(pval, STATS.mask);
            
        end
        
    end

end
