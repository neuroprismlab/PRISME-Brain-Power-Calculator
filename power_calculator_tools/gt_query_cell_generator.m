function query_cell = gt_query_cell_generator(meta_data)

    data_set_name = strcat(meta_data.dataset, '_', meta_data.map);
    if length(meta_data.test_components) > 1
        task = strcat(meta_data.test_components{1}, '_', meta_data.test_components{2});
    else
        task = meta_data.test_components{1};
    end

    query_cell = {data_set_name, task};
end