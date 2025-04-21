classdef Constrained_cpp
    properties (Constant)
        level = "network";
        permutation_based = true;
        submethod = {'FWER', 'FDR'};
    end

    methods
        function pvals = run_method(~, varargin)
            % Applies the Constrained (cNBS) method and computes p-values using permutation-based inference.
            %
            % Inputs:
            %   - STATS: Structure containing:
            %       - submethods: struct with submethod flags (FWER, FDR)
            %       - alpha: significance level
            %   - edge_stats: Raw test statistics for edges.
            %   - permuted_edge_data: Precomputed permutation edge statistics.
            %
            % Output:
            %   - pvals: Struct with fields FWER and/or FDR (depending on what's active)

            params = struct(varargin{:});
            STATS = params.statistical_parameters;
            edge_stats = params.edge_stats;
            permuted_edge_stats = params.permuted_edge_data;
            
            flat_edge_groups = flatten_edge_groups(STATS.edge_groups.groups, STATS.mask);
            
            pvals = struct();
            [p_FWER, p_FDR] = constrained_pval_cpp(edge_stats, permuted_edge_stats, ...
                flat_edge_groups, STATS.alpha);
            
            if STATS.submethods.FWER
                pvals.FWER = p_FWER;
            end

            if STATS.submethods.FDR
                pvals.FDR = p_FDR;
            end

        end
    end
end