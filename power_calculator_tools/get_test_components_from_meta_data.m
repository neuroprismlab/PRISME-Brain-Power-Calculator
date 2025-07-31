function task_name = get_test_components_from_meta_data(meta_data)
    
    % New version
    if isfield(meta_data, 'study_name')
        task_name = meta_data.study_name;
        return;
    end
    
    % Legacy meta_data
    if isfield(meta_data, 'test_components')
        
        test_components = meta_data.test_components;
        l_t_c = length(test_components);
        switch l_t_c 
            case 2
                task_name = strcat(test_components{1}, '_', test_components{2});
            
            case 1
                task_name = test_components{1};
    
            otherwise
                error('The test components in the meta-data is too large')
        end

        return;
    end
    

end