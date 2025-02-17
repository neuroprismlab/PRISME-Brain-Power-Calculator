function task_name = get_test_components_from_meta_data(test_components)
    
    l_t_c = length(test_components);
    switch l_t_c 
        case 2
            task_name = strcat(test_components{1}, '_', test_components{2});
        
        case 1
            task_name = test_components{1};

        otherwise
            error('The test components in the meta-data is too large')
    end

end