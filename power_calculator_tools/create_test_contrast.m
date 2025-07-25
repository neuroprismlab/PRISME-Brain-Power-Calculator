function [nbs_contrast, nbs_contrast_neg, nbs_exchange] = create_test_contrast(test_type, n_subs)
%% create_test_contrast
% **Description**
% Generates the contrast vector required for statistical tests used in the NBS 
% pipeline, based on the specified `test_type`. The function also returns 
% `nbs_contrast_neg` for legacy compatibility, although it is currently deprecated 
% and not used in the current workflow.
%
% **Inputs**
% - `test_type` (string): Type of statistical test ('t', 't2', 'pt', or 'r').
% - `n_subs` (int): Number of subjects (only used for 'pt' test type).
%
% **Outputs**
% - `nbs_contrast` (vector): Contrast vector for detecting effects
% - `'t'` / `'r'`: One-sample test. Contrast is scalar `1`.
% - `'t2'`: Two-sample test. Contrast is `[0, 1]`.
% - `'pt'`: Permutation test. Returns a contrast vector of length `n_subs + 1` with 1 in the first position.
% - `nbs_contrast_neg` (vector, deprecated): Legacy field, unused in current pipeline.
% - `nbs_exchange` (string, deprecated): Empty placeholder string for exchangeability block.
%
% **Notes**
% - `nbs_contrast_neg` is deprecated and maintained for compatibility only. 
%   The negative side of the test is now handled by negating the test statistic directly.
% - `nbs_exchange` is returned as an empty string by default.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025
    
    nbs_contrast = [];
    nbs_contrast_neg = [];

    switch test_type

        case 't'

            nbs_contrast = 1;
            nbs_contrast_neg = -1;
       
        case 't2'

            nbs_contrast=[1, -1];
            nbs_contrast_neg=[-1, 1];  

        case 'pt'  
            % set up contrasts - positive and negative
            nbs_contrast = zeros(1, n_subs + 1);
            nbs_contrast(1)=1;
    
            nbs_contrast_neg=nbs_contrast;
            nbs_contrast_neg(1)=-1;

        case 'r'
            nbs_contrast = [1, 0];     
            nbs_contrast_neg = [-1, 0];
        
    end
    
    nbs_exchange='';

end   

