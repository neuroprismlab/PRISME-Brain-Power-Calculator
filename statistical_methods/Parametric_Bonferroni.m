function pval = Parametric_Bonferroni(varargin)
    % Perform Bonferroni correction with uncorrected p-value computation.
    %
    % Inputs:
    %   - STATS: Structure containing statistical parameters, including alpha.
    %   - GLM: GLM structure containing test type and number of observations.
    %   - edge_stats__target: Precomputed test statistics for edges.
    %
    % Outputs:
    %   - any_significant: Boolean indicating if any edges are significant.
    %   - con_mat: Boolean mask of significant edges.
    %   - pval: Bonferroni-corrected p-values.
    params = struct(varargin{:});

    GLM = params.glm_parameters;
    edge_stats__target = params.edge_stats;
  
    % Compute uncorrected p-values based on the test type
    p_uncorr = tcdf_computation(GLM, edge_stats__target);
    
    % Apply Bonferroni correction
    pval = p_uncorr * numel(edge_stats__target);
    pval = min(pval, 1); % Ensure p-values don’t exceed 1
    
end