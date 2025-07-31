function file_type = get_file_type(meta_data)
    
    % New file types have the 
    if isfield(meta_data, 'file_type')
        file_type = meta_data.file_type;
    else
        file_type = 'full_file';
    end

end