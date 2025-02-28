function p_uncorr = tcdf_computation(GLM, edge_stats__target)
% Compute uncorrected p-values based on the GLM test type.
%
% Inputs:
%   - GLM: Structure containing test type and number of observations.
%   - edge_stats__target: Precomputed test statistics for edges.
%
% Output:
%   - p_uncorr: Uncorrected p-values.

    switch lower(GLM.test)
        case 'onesample'
            df = GLM.n_observations - 1;
            p_uncorr = tcdf(-edge_stats__target, df);
    
        case 'ttest'
            df = GLM.n_observations - 2;
            p_uncorr = tcdf(-edge_stats__target, df);
    
        case 'ftest'
            error('F-test currently not supported.');
    
        otherwise
            error('Invalid GLM test type: %s', GLM.test);
    end
    
end