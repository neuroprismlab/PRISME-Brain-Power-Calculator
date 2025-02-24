function edge_based_tests(data_set_name)

    data_set = load(['./data/', data_set_name]);
    data_set_name = get_data_set_name(data_set);

    Params = common_test_setup(data_set_name);
    
    stat_method_cell = {'Parametric_Bonferroni', 'Parametric_FDR', 'Size', 'TFCE'};

    Params.all_cluster_stat_types = stat_method_cell;

    rep_cal_function(Params)
    
    ResData = unite_results_from_directory('directory', ['./power_calculator_results/', data_set_name, '/']);
    
    if isempty(ResData) || (isstruct(ResData) && isempty(fieldnames(ResData)))
        error('No results found in the specified directory: %s', ['./power_calculator_results/', data_set_name, '/']);
    end

    for i = 1:length(stat_method_cell)
        method = stat_method_cell{i};

        % The query is based on how the dataset is created
        query = {'testing', data_set_name, 'REST_TASK', method, 'subs_40', 'brain_data'};
        
        %% Test regression results
        brain_data = getfield(ResData, query{:});
    
        pvals = brain_data.pvals_all;

        % I think I need to add the power calculator scripts too - just to
        % make sure 

        % Ensure first row is all zeros
        error_effect = sprintf('Network-Level Test Failed in Dataset %s, Method %s: Effect not detected', ...
            data_set_name, method);
        error_non_effect = sprintf('Network-Level Test Failed in Dataset %s, Method %s: Effect detected', ...
            data_set_name, method);

        % Check for significant p-values where an effect is expected (rows 1 to 6)
        for row = 1:6
            assert(all(pvals(row, :) <= 0.05), error_effect);
        end

        % Check for non-significant p-values where no effect is expected (rows 7 to 10)
        for row = 7:10
            assert(all(pvals(row, :) == 1), error_non_effect);
        end

        %% Test meta-data results 
        query = {'testing', data_set_name, 'REST_TASK', method, 'subs_40', 'meta_data'};

        meta_data = getfield(ResData, query{:});

        check_test_meta_data(meta_data, method)
    
    end

end
