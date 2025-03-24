classdef Parametric
    properties (Constant)
        level = "edge";
        permutation_based = false;
        submethod = {'FWER', 'FDR'};
    end

    methods
        function pvals = run_method(~, varargin)
            % Inputs:
            % - statistical_parameters: struct with 'submethods' field (from STATS)
            % - glm_parameters: GLM details for tcdf computation
            % - edge_stats: test stats to evaluate
            %
            % Output:
            % - pvals: struct with one field per submethod (or vector if only one)

            % Unpack parameters
            params = struct(varargin{:});
            STATS = params.statistical_parameters;
            GLM = params.glm_parameters;
            edge_stats = params.edge_stats;

            % Compute uncorrected p-values
            p_uncorr = tcdf_computation(GLM, edge_stats);

            % Initialize struct for results
            pvals = struct();

            % FWER (Bonferroni correction)
            if STATS.submethods.FWER
                p_fwer = p_uncorr * numel(edge_stats);
                pvals.FWER = min(p_fwer, 1);
            end

            % FDR (Benjamini-Hochberg)
            if STATS.submethods.FDR
                [~, sort_idx] = sort(p_uncorr);
                m = numel(p_uncorr);
                p_fdr = zeros(size(p_uncorr));
                for i = 1:m
                    p_fdr(sort_idx(i)) = p_uncorr(sort_idx(i)) * m / i;
                end
                pvals.FDR = min(p_fdr, 1);
            end

            % Optional: unwrap single submethod into vector directly
            method_names = fieldnames(pvals);
            if numel(method_names) == 1
                pvals = pvals.(method_names{1});
            end
        end
    end
end