classdef Parametric_Bonferroni
    properties (Constant)
        level = "edge";
        permutation_based = false;
    end

    methods
        function pval = run_method(~, varargin)
            % Existing logic stays the same
            params = struct(varargin{:});

            GLM = params.glm_parameters;
            edge_stats__target = params.edge_stats;
            
            % Compute uncorrected p-values
            p_uncorr = tcdf_computation(GLM, edge_stats__target);
            
            % Apply Bonferroni correction
            pval = p_uncorr * numel(edge_stats__target);
            pval = min(pval, 1); % Ensure p-values don’t exceed 1
        end
    end

end