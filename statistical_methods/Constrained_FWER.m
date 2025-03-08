classdef Constrained_FWER
    properties (Constant)
        level = "network";
    end


    methods
        function pval = run_method(~,varargin)
            % Applies Constrained (cNBS) method and computes p-values using permutation-based inference.
            % Uses Bonferroni correction (FWER).
            %
            % Inputs:
            %   - STATS: Structure containing statistical parameters.
            %   - edge_stats: Raw test statistics for edges.
            %   - permuted_edge_data: Precomputed permutation edge statistics.
            %
            % Outputs:
            %   - pval: FWER-corrected p-values using Bonferroni correction.
        
            params = struct(varargin{:});
        
            % Extract relevant inputs
            STATS = params.statistical_parameters;
            edge_stats = params.edge_stats;
            permuted_edge_stats = params.permuted_edge_data;  % Precomputed permutation data
        
            % Ensure permutation data is available
            if isempty(permuted_edge_stats)
                error('Permutation data is missing. Ensure precomputed permutations are provided.');
            end
        
            % Compute uncorrected p-values
            pval_uncorr = constrained_calculation(STATS, edge_stats, permuted_edge_stats);
        
            % Apply Bonferroni correction (FWER)
            pval = pval_uncorr * numel(pval_uncorr);  % Bonferroni correction
            pval = min(pval, 1);  % Ensure p-values don’t exceed 1
        
        end
    end

end