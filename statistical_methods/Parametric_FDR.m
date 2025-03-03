function pval = Parametric_FDR(varargin)
% Perform FDR correction with uncorrected p-value computation.

    params = struct(varargin{:});
    
    GLM = params.glm_parameters;
    edge_stats__target = params.edge_stats;
    
    
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
    
end