function network_based_tests(data_set_name)
    
    data_set = load(['./data/', data_set_name]);
    data_set_name = get_data_set_name(data_set);

    Params = common_test_setup(data_set_name);

    stat_method_cell = {'Constrained', 'Constrained_FWER'};
    Params.all_cluster_stat_types = stat_method_cell;

    rep_cal_function(Params)
    
    ResData = unite_results_from_directory('directory', ['./power_calculator_results/', data_set_name, '/']);
    
    task_name = get_task_name_for_test(data_set);
    for i = 1:length(stat_method_cell)
        method = stat_method_cell{i};

        % The query is based on how the dataset is created
        query = {'testing', data_set_name, task_name, method, 'subs_40', 'brain_data'};
    
        brain_data = getfield(ResData, query{:});
    
        pvals = brain_data.pvals_all;

        % I think I need to add the power calculator scripts too - just to
        % make sure 

        % Ensure first row is all zeros
        assert(all(pvals(1, :) <= 0.05), 'Network-Level Test Failed: Effect not detected in first row');

        % Ensure second row is all ones
        assert(all(pvals(2, :) >= 0.5), 'Network-Level Test Failed: Effect detected in second row');


        %% Test meta-data results 
        query = {'testing', data_set_name, task_name, method, 'subs_40', 'meta_data'};

        meta_data = getfield(ResData, query{:});

        check_test_meta_data(meta_data, method)
        
    end

end