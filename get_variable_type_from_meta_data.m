function variable_type = get_variable_type_from_meta_data(meta_data)

    if isfield(meta_data, 'variable_type')
        variable_type = meta_data.variable_type;
        return;
    end

end