function sub_number = get_sub_number_from_meta_data(meta_data)

    if isfield(meta_data, 'n_subs')
        sub_number = meta_data.n_subs;
        return;
    end
    
    if isfield(meta_data, 'subject_number')
        sub_number = meta_data.subject_number;
        return;
    end

end