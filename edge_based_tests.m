function edge_based_tests(data_set_name)

    Params = common_test_setup(data_set_name);
    
    % Test 'TFCE' and Size with more detail 
    stat_method_cell = {'Parametric_Bonferroni', 'Parametric_FDR'};
    
    Params.all_cluster_stat_types = stat_method_cell;
    
    Params = setup_global_test_parameters(Params, data_set_name);
    
    rep_cal_function(Params)
    
    ResData = unite_results_from_directory('directory', './test_power_calculator/');

    for i = 1:length(stat_method_cell)
        method = stat_method_cell{i};

        % The query is based on how the dataset is created
        query = {'testing', 'test_hcp', 'REST_TASK', method, 'subs_40', 'brain_data'};
    
        brain_data = getfield(ResData, query{:});
    
        pvals = brain_data.pvals_all;

        % I think I need to add the power calculator scripts too - just to
        % make sure 

        % Ensure first row is all zeros
        assert(all(pvals(1, :) == 0), 'Network-Level Test Failed: Effect not detected in first row');

        % Ensure second row is all ones
        assert(all(pvals(2, :) == 1), 'Network-Level Test Failed: Effect detected in second row');
    end

end
