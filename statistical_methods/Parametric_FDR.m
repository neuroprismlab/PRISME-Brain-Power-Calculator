function [any_significant, con_mat, pval] = Parametric_FDR(STATS, GLM, edge_stats__target)
% Perform FDR correction with uncorrected p-value computation.
%
% Inputs:
%   - STATS: Structure containing statistical parameters, including alpha.
%   - GLM: GLM structure containing test type and number of observations.
%   - edge_stats__target: Precomputed test statistics for edges.
%
% Outputs:
%   - any_significant: Boolean indicating if any edges are significant.
%   - con_mat: Boolean mask of significant edges.
%   - pval: FDR-corrected p-values.
    
    % Compute uncorrected p-values based on the test type
    p_uncorr = tcdf_computation(GLM, edge_stats__target);
    
    % Apply Benjamini-Hochberg FDR correction
    [~, sort_idx] = sort(p_uncorr);
    m = numel(p_uncorr);
    pval = zeros(size(p_uncorr));
    
    for i = 1:m
        pval(sort_idx(i)) = p_uncorr(sort_idx(i)) * m / i;
    end
    
    pval = min(pval, 1); % Ensure p-values don’t exceed 1
    
    % Determine significant edges
    con_mat{1} = pval(:) < STATS.alpha;
    any_significant = any(con_mat{1});
    
end