function gt_filename = construct_gt_filename(meta_data)
    % Extract information from metadata
    data_set_name = strcat(meta_data.dataset, '_', meta_data.map);
    test_components = strjoin(meta_data.test_components, '_');
    test_type = meta_data.test;
    stat_type = meta_data.test_type;
    omnibus_type = meta_data.omnibus;

    % Handle missing omnibus type (convert NaN to 'nobus')
    if isnan(omnibus_type)
        omnibus_type = 'nobus';
    end

    % Determine the stat level based on stat type
    switch stat_type
        case 'Parametric_Bonferroni'
            stat_level = 'edge';
        case 'Constrained'
            stat_level = 'network';
        case 'Omnibus'
            stat_level = 'whole_brain';
        otherwise
            error('Stat type not necessary for GT calculation');
    end

    % Construct the GT filename
    gt_filename = sprintf('gt_%s_%s_%s_%s_%s.mat', ...
                          data_set_name, test_components, ...
                          test_type, stat_level, omnibus_type);

    if meta_data.testing_code 
        gt_filename = strcat(gt_filename, '_test.mat');
    end

end