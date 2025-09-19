function study_name = get_study_name_from_meta_data(meta_data)
  
    if isfield(meta_data, 'study_name')
        study_name = meta_data.study_name;
        return;
    end

    if isfield(meta_data, 'rep_parameters')
        study_name = meta_data.rep_parameters.test_name;
        return;
    end

end