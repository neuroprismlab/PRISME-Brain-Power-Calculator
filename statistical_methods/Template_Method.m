
classdef Template_Method

    properties (Constant)
        level = "whole_brain";
        permutation_based = true;
        permutations = 800; % Optional
        submethod = {'FWER', 'FDR'}; % Optional 
    end
    
    methods

        function pval = run_method(~,varargin)
            pval = 1;
        end

    end

end





