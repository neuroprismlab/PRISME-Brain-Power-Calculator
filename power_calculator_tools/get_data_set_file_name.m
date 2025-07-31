function data_set_file_name = get_data_set_file_name(meta_data)
    
    if isfield(meta_data, 'data_dir')
        [~, data_set_file_name, ~] = fileparts(meta_data.data_dir);
        return;
    end

    %Legacy files
    if isfield(meta_data, 'rep_parameters')
        [~, data_set_file_name, ~] = fileparts(meta_data.rep_parameters.data_dir);
        return;
    end

end