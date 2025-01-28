function constrained_test(data_set_name)
    
    Params = setparams();
    
    Params.all_cluster_stat_types = {'Constrained'};

    Params = setup_global_test_parameters(Params, data_set_name);

    rep_cal_function(Params)

end