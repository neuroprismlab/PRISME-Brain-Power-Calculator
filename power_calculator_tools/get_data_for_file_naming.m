function [test_components, test_type, sub_number, testing_code] = get_data_for_file_naming(meta_data)
    
    % All of these are needed to support multiple file versions
    test_components = get_test_components_from_meta_data(meta_data);
    test_type = get_test_type_from_meta_data(meta_data);
    sub_number = get_sub_number_from_meta_data(meta_data);
    
    % This one never went through a change
    testing_code = meta_data.testing_code;

end