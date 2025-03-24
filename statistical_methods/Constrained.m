classdef Constrained
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

            % Check permutation data
            if isempty(permuted_edge_stats)
                error('Permutation data is missing. Ensure precomputed permutations are provided.');
            end

            % Compute uncorrected p-values via cNBS
            pval_uncorr = constrained_calculation(STATS, edge_stats, permuted_edge_stats);

            pvals = struct();

            % FWER - Bonferroni correction
            if STATS.submethods.FWER
                p_fwer = pval_uncorr * numel(pval_uncorr);
                pvals.FWER = min(p_fwer, 1);
            end

            % FDR - Simes procedure
            if STATS.submethods.FDR
                J = length(pval_uncorr);
                [p_sorted, ind_srt] = sort(pval_uncorr);
                threshold = (1:J) / J * STATS.alpha;
                sig_mask = p_sorted <= threshold;

                p_fdr = ones(1, J);
                p_fdr(ind_srt(sig_mask)) = 0;

                pvals.FDR = p_fdr;
            end
        end
    end
end