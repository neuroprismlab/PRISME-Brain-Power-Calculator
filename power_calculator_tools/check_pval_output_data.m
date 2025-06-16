function check_pval_output_data(RP, all_pvals, all_pvals_neg)
%% check_pval_output_data
% Validates the structure and dimensions of p-value outputs from each statistical method.
%
% This function performs two key validation steps:
%   1. Ensures that all method names in the p-value outputs match expected full method names 
%      (e.g., 'Parametric_FDR').
%   2. Verifies that the size of each output array is consistent with its expected shape based on
%      the method's analysis level: whole-brain, network, or edge.
%
% Inputs:
%   - RP: Struct with benchmarking parameters. Must contain:
%       * all_full_stat_type_names: Cell array of all valid method_submethod names.
%       * full_name_method_map: Map from full names to base class names.
%       * n_repetitions, n_var, edge_groups: For dimension validation.
%   - all_pvals: Cell array of p-value structures (positive effects).
%   - all_pvals_neg: Cell array of p-value structures (negative effects).
%
% Example:
%   check_pval_output_data(RP, all_pvals, all_pvals_neg)
%
% Notes:
%   - Throws an error if any validation check fails.   

    % Only necessary to check a single repetition
    test_struct = all_pvals{1};
    l_test_struct(RP.all_full_stat_type_names, test_struct)
    l_test_output_size(RP, test_struct)
    test_struct_neg = all_pvals_neg{1};
    l_test_struct(RP.all_full_stat_type_names, test_struct_neg)
    l_test_output_size(RP, test_struct)

end

function l_test_struct(all_full_stat_type_names, test_struct)
    
    fn = fieldnames(test_struct);
    for i = 1:numel(fn)
        field = fn{i};

        if ~ismember(field, all_full_stat_type_names)
            error('The %s is not a full method name. Was there a misoutputed pval?', field)
        end

    end

end

function l_test_output_size(RP, test_struct)
    
    fn = fieldnames(test_struct);
    for i = 1:numel(fn)
        % Get method instance
        full_method_name = fn{i};
        parent_method = RP.full_name_method_map(full_method_name);
        method_instance = feval(parent_method);
   
        switch method_instance.level

            case "whole_brain"
                sz = size(test_struct.(full_method_name));
                assert(isequal(sz, [1, 1]) || isequal(sz, [1, 1]'), ...
                    'Size mismatch for method "%s" (whole_brain)', full_method_name);
            
            case "network"
                expected = length(unique(RP.edge_groups)) - 1;
                sz = size(test_struct.(full_method_name));
                assert(isequal(sz, [expected, 1]) || isequal(sz, [1, expected]), ...
                    'Size mismatch for method "%s" (network)', full_method_name);
            
            % Edge, node and variable are the same for these conditions!
            case "edge"
                sz = size(test_struct.(full_method_name));
                assert(isequal(sz, [RP.n_var, 1]) || isequal(sz, [1, RP.n_var]), ...
                    'Size mismatch for method "%s" (edge)', full_method_name);

            case "node"
                sz = size(test_struct.(full_method_name));
                assert(isequal(sz, [RP.n_var, 1]) || isequal(sz, [1, RP.n_var]), ...
                    'Size mismatch for method "%s" (edge)', full_method_name);

            case "variable"
                sz = size(test_struct.(full_method_name));
                assert(isequal(sz, [RP.n_var, 1]) || isequal(sz, [1, RP.n_var]), ...
                    'Size mismatch for method "%s" (edge)', full_method_name);

            otherwise
                error("Unknown statistic level: %s", method_instance.level);
        
        end

    end

end