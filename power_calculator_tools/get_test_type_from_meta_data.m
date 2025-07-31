function test_type = get_test_type_from_meta_data(meta_data)
    
    if isfield(meta_data, 'test_type')
        test_type = meta_data.test_type;
        return;
    end
    
    % Legacy files
    if isfield(meta_data, 'test')
        test_type = meta_data.test;
        return;
    end
    
end 