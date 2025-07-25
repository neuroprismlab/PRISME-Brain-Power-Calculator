classdef IC_TFCE_Node_cpp < handle

    properties
        level = "node";
        permutation_based = true;
        permutations = 800; % Override permutation number
        method_params = IC_TFCE_Node_cpp.get_fast_tfce_params()
    end
    
    methods (Static, Access = private)
        function method_params = get_fast_tfce_params()
            method_params = struct();
            method_params.dh = 0.1;
            method_params.H = 2.0;
            method_params.E = 0.5;
        end
    end
    
    methods
        function pval = run_method(obj, varargin)
            % Applies Threshold-Free Cluster Enhancement (TFCE) and computes p-values
            % using a permutation-based approach for node-level statistics.
            %
            % Inputs:
            % - STATS: Structure containing statistical parameters, including threshold.
            % - node_stats: Raw test statistics for nodes.
            % - permutation_node_data: Precomputed permutation node statistics.
            %
            % Outputs:
            % - pval: TFCE-corrected p-values.
            
            params = struct(varargin{:});
            
            % Extract relevant inputs - Legacy naming issue with the edge
            % stats
            STATS = params.statistical_parameters;
            node_stats = params.edge_stats; 
            permuted_node_stats = params.permuted_edge_data; 
            
            % Convert the node statistics back into a matrix
            sparse_mat = STATS.unflatten_matrix(node_stats);
            
            % Apply TFCE transformation to the observed test statistics 
            cluster_stats_target = apply_tfce_sparse_node(sparse_mat, ...
                obj.method_params.dh, obj.method_params.H, obj.method_params.E);
            
            % Ensure permutation data is provided
            if isempty(permuted_node_stats)
                error('Permutation data is missing. Ensure precomputed permutations are provided.');
            end
            
            % Number of permutations
            if size(permuted_node_stats, 2) < obj.permutations
                K = size(permuted_node_stats, 2);
            else
                K = obj.permutations;
            end
            
            null_dist = zeros(K, 1);
            
            % Apply TFCE transformation to each permutation
            for i = 1:K
                perm_stat_mat = STATS.unflatten_matrix(permuted_node_stats(:, i));
                tfce_null = apply_tfce_sparse_node(perm_stat_mat, ...
                    obj.method_params.dh, obj.method_params.H, obj.method_params.E);
                null_dist(i) = max(tfce_null(:)); % Store max TFCE value for permutation
            end
            
            % Compute p-values using permutation-based FWER correction
            pval = arrayfun(@(stat) (sum(stat <= null_dist)) / K, cluster_stats_target(:));

        end
    end
end

function tfce_result = apply_tfce_sparse_node(sparse_mat, dh, H, E)
    % Apply TFCE using sparse matrix representation for node-level analysis
    %
    % Inputs:
    % - stat_mat: Matrix of test statistics
    % - STATS: Structure containing connectivity information or adjacency matrix
    % - dh: Height increment for TFCE
    % - H: Height exponent for TFCE
    % - E: Extent exponent for TFCE
    %
    % Outputs:
    % - tfce_result: TFCE-enhanced statistics
    
    % Convert to sparse matrix and get indices
    [I, J, V] = find(sparse_mat);
    n_nodes = size(sparse_mat, 1);
    
    % Call the MEX function with sparse matrix components
    tfce_result = sparse_tfce_cpp(I, J, V, n_nodes, dh, H, E);
    
end