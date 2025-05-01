function X = create_design_matrix(varargin)
%% create_design_matrix
% **Description**
% Creates a design matrix `X` based on the specified test type for use in 
% statistical testing (e.g., `t`, `t2`, `pt`, `r`). Supports paired, unpaired, 
% and permutation test designs, with optional parameters for group sizes.
%
% **Inputs**
% - `test_type` (string): Type of test to design (`'t'`, `'t2'`, `'pt'`, `'r'`).
% - `n_subs` (int): Total number of subjects (or number of subjects in one group, depending on test).
%
% **Name-Value Parameters**
% - `n_subs_1` (int, optional): Number of subjects in group 1 (used for `t2`).
% - `n_subs_2` (int, optional): Number of subjects in group 2 (used for `t2`).
%
% **Outputs**
% - `X` (matrix): Design matrix suitable for statistical testing. If test type is `'r'`, returns `NaN`.
%
% **Test Types**
% - `'t'`: One-sample or paired t-test; returns a column of ones.
% - `'t2'`: Two-sample t-test; returns a matrix with intercept and group labels.
% - `'pt'`: Permutation t-test; returns a signed contrast matrix with block structure.
% - `'r'`: Correlation test; returns `NaN` since the design comes from the data.
%
% **Notes**
% - The design matrix for `'r'` is not constructed here—it's pulled directly from the score data.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025

    % Define a parser with default values
    p = inputParser;
    addRequired(p, 'test_type');
    addRequired(p, 'n_subs');
    addParameter(p, 'n_subs_1', -1); 
    addParameter(p, 'n_subs_2', -1); 

    
    % Parse the inputs
    parse(p, varargin{:});
    
    % Access parsed inputs
    test_type = p.Results.test_type;
    n_subs = p.Results.n_subs;
    n_subs_1 = p.Results.n_subs_1;
    n_subs_2 = p.Results.n_subs_2;


    switch test_type
        
        case 't'
            
            X = ones(n_subs, 1);
            
        case 't2' 
            
            if n_subs_1 == -1 || n_subs_2 == -1
                error('For a t2 design matrix, the number of subjects from both conditions must be supplied')
            end
        
            % Create the design matrix with intercept and one group indicator
            X = zeros(n_subs_1 + n_subs_2, 2);
        
            % Intercept column (ones for all subjects)
            X(1:n_subs_1, 1) = 1;
        
            % Group membership column (1 for Group 1, 0 for Group 2)  
            X(n_subs_1 + 1:end, 2) = 1;

        case 'pt'

            X = zeros(n_subs * 2, n_subs + 1);
            X(1:n_subs, 1) = 1;
            X(n_subs + 1:end, 1) = -1;
    
            for i=1:n_subs
                X(i,i+1)=1;
                X(n_subs + i, i + 1) = 1;
            end

        case 'r'
            % Design matrix for r is obtained directly from the data 
            % So here we define it as NaN
            X = NaN; 
        
        otherwise

            error('Test type in create_design_matrix not supported')
        
    end
        
end