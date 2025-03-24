function check_pval_output_data(RP, all_pvals, all_pvals_neg)
%% check_pval_output_data
% Validates the structure of p-value outputs to ensure consistency with the expected method names.
%
% This function checks that all p-values stored in the `all_pvals` and `all_pvals_neg` cell arrays
% contain only valid keys corresponding to the expected full method names (e.g., `'Parametric_FDR'`).
% It does not validate the dimensions of the outputs.
%
% This is typically used after p-value calculation to ensure that the results were produced
% for the correct methods and that no invalid or unintended method names were included.
%
% Inputs:
%   - RP: Repetition parameter struct with field:
%       - `all_full_stat_type_names`: A list of expected full method names (e.g., {'TFCE', 'Size', 'Omnibus_XYZ'}).
%   - all_pvals: Cell array of structs (per repetition) storing positive effect p-values.
%   - all_pvals_neg: Cell array of structs (per repetition) storing negative effect p-values.
%
% Internal Functions:
%   - `l_test_struct`: Verifies that the fields in each struct are all expected method names.
%   - `l_test_output_size`: (defined but not called) Checks if the dimensions of the output arrays match the expected sizes.    

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
            
            case "edge"
                sz = size(test_struct.(full_method_name));
                assert(isequal(sz, [RP.n_var, 1]) || isequal(sz, [1, RP.n_var]), ...
                    'Size mismatch for method "%s" (edge)', full_method_name);
                
            otherwise
                error("Unknown statistic level: %s", method_instance.level);
        
        end

    end

end