function edge_based_tests(data_set_name)

    Params = common_test_setup(data_set_name);
    
    % Test 'TFCE' and Size with more detail 
    % Ok methods = {'Parametric_Bonferroni', 'Parametric_FDR'}
    stat_method_cell = {'Size'};
    

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
        error_effect = sprintf('Network-Level Test Failed in Method %s: Effect not detected', method);
        error_non_effect = sprintf('Network-Level Test Failed in Method %s: Effect detected', method);

        % Check for significant p-values where an effect is expected (rows 1 to 6)
        for row = 1:6
            assert(all(pvals(row, :) == 0), error_effect);
        end

        % Check for non-significant p-values where no effect is expected (rows 7 to 10)
        for row = 7:10
            assert(all(pvals(row, :) == 1), error_non_effect);
        end
     
    end

end
