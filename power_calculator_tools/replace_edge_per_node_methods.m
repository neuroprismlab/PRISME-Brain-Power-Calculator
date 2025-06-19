function replaced_method = replace_edge_per_node_methods(method_name, method_variable_type, ...
                                                        dataset_variable_type)

    replaced_method = method_name;
    
    % Fast_TFCE_Node_cpp is currently not working
    %if strcmp(method_name, Fast_TFCE_Node_cpp)
    %    replaced_method = 'Fast_TFCE_Node';
    %end

    if strcmp(method_variable_type, 'edge') && strcmp(dataset_variable_type, 'node')

        switch method_name
            case 'Size_cpp'
                replaced_method = 'Size_Node_cpp';
             
            case 'Fast_TFCE_cpp'
                replaced_method = 'IC_TFCE_Node_cpp';

            case 'Size'
                replaced_method = 'Size_Node';

            case 'Fast_TFCE'
                replaced_method = 'Fast_TFCE_Node';
            
            otherwise 
                error('Method %s does not match variable type %s and has no replacement', ...
                    method_name, variable_type)

        end

    elseif strcmp(method_variable_type, 'node') && strcmp(dataset_variable_type, 'edge')

        switch method_name
            case 'Size_Node_cpp'
                replaced_method = 'Size_cpp';
             
            case 'Fast_TFCE_Node'
                replaced_method = 'Fast_TFCE_cpp';

            case 'IC_TFCE_Node_cpp'
                replaced_method = 'Fast_TFCE_cpp';

            otherwise 
                error('Method %s does not match variable type %s and has no replacement', ...
                    method_name, variable_type)
        end

    end
             

end

