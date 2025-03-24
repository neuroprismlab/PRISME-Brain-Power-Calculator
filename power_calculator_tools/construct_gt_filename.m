function gt_filename = construct_gt_filename(meta_data)
    % Extract information from metadata
    data_set_name = strcat(meta_data.dataset, '_', meta_data.map);
    test_components = strjoin(meta_data.test_components, '_');
    test_type = meta_data.test;   

    % Construct the GT filename
    gt_filename = sprintf('%s-%s-%s-%s', ...
                          data_set_name, test_components, ...
                          test_type, 'Ground_Truth');

    if meta_data.testing_code 
        gt_filename = strcat(gt_filename, '-test.mat');
    else
        gt_filename = strcat(gt_filename, '.mat');
    end

end