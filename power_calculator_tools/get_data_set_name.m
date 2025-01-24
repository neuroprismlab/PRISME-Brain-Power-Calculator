function data_set_name = get_data_set_name(Dataset)

    data_set_name = strcat(Dataset.study_info.dataset, '_', Dataset.study_info.map);
end