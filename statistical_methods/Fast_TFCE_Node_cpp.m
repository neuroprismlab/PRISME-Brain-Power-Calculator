classdef Fast_TFCE_Node_cpp
    properties (Constant)
        level = 'node';
        permutation_based = true;
    end
    
    properties
        method_params = Fast_TFCE_Node_cpp.get_fast_tfce_params()
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
            params = struct(varargin{:});
            STATS = params.statistical_parameters;
            edge_stats_target = params.edge_stats;
            permuted_edge_stats = params.permuted_edge_data;
            
            % Apply TFCE to target data
            a = tic;
            tfce_values_target = obj.compute_tfce_values(edge_stats_target, STATS);
            b = toc(a);
            disp(b)

            error("Plese kill me. I hate this")
            
            % Apply TFCE to each permutation and get max values
            perms_max_tfce = zeros(1, STATS.n_perms);
            for p = 1:STATS.n_perms
                tfce_values_perm = obj.compute_tfce_values(permuted_edge_stats(:, p), STATS);
                perms_max_tfce(1, p) = max(tfce_values_perm);
            end
            
            % Compute p-values for each node
            pval = zeros(size(tfce_values_target));
            for i = 1:length(tfce_values_target)
                observed_tfce = tfce_values_target(i);
                if observed_tfce == 0
                    % Inactive nodes get p-value = 1 (not significant)
                    pval(i) = 1.0;
                else
                    % Count how many permutations had max TFCE >= observed
                    n_exceeding = sum(perms_max_tfce >= observed_tfce);
                    pval(i) = n_exceeding / STATS.n_perms;
                end
            end
        end
        
        function tfce_values = compute_tfce_values(obj, edge_stats, STATS)
            % Convert edge stats to sparse matrix format
            sparse_stat_mat = STATS.unflatten_matrix(edge_stats);
            sparse_stat_mat = max(sparse_stat_mat, 0);  % Remove negative values, keep sparse
            
            num_nodes = size(sparse_stat_mat, 1);
            tfce_values = zeros(num_nodes, 1);
            
            % Find maximum value for threshold range
            max_val = max(sparse_stat_mat(:));
            if max_val == 0
                return; % No positive values
            end
            
            % Create threshold range
            thresholds = 0:obj.method_params.dh:max_val;
            
            % For each threshold, calculate cluster sizes and accumulate TFCE
            for thresh = thresholds(2:end)  % Skip threshold 0
                % Apply operation only to non-zero values
                sparse_stat_mat = spfun(@(x) max(x - thresh, 0), sparse_stat_mat); 
                
                [I, J, ~] = find(sparse_stat_mat);
                

                if isempty(I)
                    continue; % No connections at this threshold
                end
                
                % Calculate cluster size for each node at this threshold
                cluster_sizes = sparse_size_pval_cpp(double(I), double(J), double([num_nodes, num_nodes]));
                
                % Accumulate TFCE contribution: cluster_size^E * threshold^H * dh
                tfce_contribution = (cluster_sizes .^ obj.method_params.E) .* ...
                                  (thresh ^ obj.method_params.H) .* obj.method_params.dh;
                
                tfce_values = tfce_values + tfce_contribution;
            end
        end
    end
end