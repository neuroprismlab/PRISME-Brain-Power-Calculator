classdef Template_Method

    properties (Constant)
        level = "whole_brain";
        permutation_based = true;
        permutations = 800; % Override permutation number
        method_params = struct('f1',10,'f2',20);
    end
    
    methods

        function pval = run_method(~,varargin)
            pval = 1;
        end

    end

end