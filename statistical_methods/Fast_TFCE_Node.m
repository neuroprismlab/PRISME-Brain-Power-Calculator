classdef Fast_TFCE_Node
    
    properties 
        level = "node";
        permutation_based = true;
        permutations = 800; % Override permutation number
        method_params = Fast_TFCE_Node.get_fast_tfce_params()
    end

    methods (Static, Access = private)
        function method_params = get_fast_tfce_params()
            method_params = struct();
            method_params.dh = 0.1;
            method_params.H = 3.0;
            method_params.E = 0.4;
        end
    end

    methods

        function pval = run_method(obj,varargin)
            
            params = struct(varargin{:});
        
            %% Extract relevant inputs
            STATS = params.statistical_parameters;
            edge_stats = params.edge_stats;
            permuted_edge_stats = params.permuted_edge_data; % Explicitly using the new argument

            % Keep values above threshold, set others to zero
            sparse_stat_mat = STATS.unflatten_matrix(edge_stats);
            sparse_stat_mat = max(sparse_stat_mat, 0);  % Sets negative values to 0, keeps sparse

            %% Extract method parameters
            num_nodes = size(sparse_stat_mat, 1);
            dh = obj.method_params.dh;
            H = obj.method_params.H;
            E = obj.method_params.E;
            
             % Convert the edge statistics back into a matrix
            a = tic;
            [I, J, V] = find(sparse_stat_mat);
            tfce_stats = apply_tfce_sparse(I, J, V, num_nodes, dh, E, H);
            b = toc(a);
            disp(b)
            
            error('Debbug')

        end
        
    end


end


