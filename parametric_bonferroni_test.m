function parametric_bonferroni_test(data_set_name)
    
    Params = setparams();
    
    Params.all_cluster_stat_types = {'Parametric_Bonferroni'};

    Params = setup_global_test_parameters(Params, data_set_name);

end

