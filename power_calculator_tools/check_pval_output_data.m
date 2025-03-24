function check_pval_output_data(RP, all_pvals, all_pvals_neg)
    
    % Only necessary to check a single repetition
    test_struct = all_pvals{1};
    l_test_struct(RP.all_full_stat_type_names, test_struct)
    test_struct_neg = all_pvals_neg{1};
    l_test_struct(RP.all_full_stat_type_names, test_struct_neg)

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

function l_test_output_size(full_name_method_map, test_struct)
    
    fn = fieldnames(test_struct);
    for i = 1:numel(fn)
        % Get method instance
        full_method_name = fn{i};
        parent_method = full_name_method_map(full_method_name);
        method_instance = feval(parent_method);

         switch method_instance.level
            case "whole_brain"
                assert(size(test_struct.(full_method_name)) == size(zeros(1, RP.n_repetitions)));
            case "network"
                assert(size(test_struct.(full_method_name)) == ...
                    size(zeros(length(unique(RP.edge_groups)) - 1, RP.n_repetitions)));
            case "edge"
                assert(size(test_struct.(full_method_name)) == size(zeros(RP.n_var, RP.n_repetitions)));
            otherwise
                error("Unknown statistic level: %s", method_instance.level);
         end

    end

end