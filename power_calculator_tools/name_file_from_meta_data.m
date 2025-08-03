function file_name = name_file_from_meta_data(meta_data, gt)
    
    data_set_name = strcat(meta_data.dataset, '_', meta_data.map);
    test_name = get_test_components_from_meta_data(meta_data);

    [~, file_name] = create_and_check_rep_file(NaN, data_set_name, test_name, ...
        meta_data.test, meta_data.subject_number, meta_data.testing_code, gt);

end