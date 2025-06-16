function replaced_method = replace_edge_per_node_methods(method_name, method_variable_type, ...
                                                        dataset_variable_type)

    replaced_method = method_name;

    if strcmp(method_variable_type, 'edge') && strcmp(dataset_variable_type, 'node')

        switch method_name
            case 'Size_cpp'
                replaced_method = 'Size_Node_cpp';
             
            case 'Fast_TFCE_cpp'
                replaced_method = 'Fast_TFCE_Node_cpp';
            
            otherwise 
                error('Method %s does not match variable type %s and has no replacement', ...
                    method_name, variable_type)

        end

    elseif strcmp(method_variable_type, 'node') && strcmp(dataset_variable_type, 'edge')

        switch method_name
            case 'Size_Node_cpp'
                replaced_method = 'Size_Node_cpp';
             
            case 'Fast_TFCE_Node_cpp'
                replaced_method = 'Fast_TFCE_Node_cpp';

            otherwise 
                error('Method %s does not match variable type %s and has no replacement', ...
                    method_name, variable_type)
        end

    end
             

end

