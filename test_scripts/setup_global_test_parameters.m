function Params = setup_global_test_parameters(Params)

    Params = setparams();
    Params.all_cluster_stat_types = {'Parametric_Bonferroni'};

    Params.save_directory = './test_power_calculator/';
       
    % I think this is enough - the effect size in the test matrix is brutal
    Params.n_perms = 100;
    Params.n_repetitions = 40;


end