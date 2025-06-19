classdef Size_Node
    properties (Constant)
        level = 'node';
        permutation_based = true;
    end

    methods

        function pval = run_method(~,varargin)

            error('Under development')

            params = struct(varargin{:});
            STATS = params.statistical_parameters;
            edge_stats_target = params.edge_stats;
            permuted_edge_stats = params.permuted_edge_data;
        
            sparse_graph_stats = STATS.unflatten_matrix(edge_stats_target) > STATS.thresh;

            keyboard;
            
            

        end
        
    end

end
