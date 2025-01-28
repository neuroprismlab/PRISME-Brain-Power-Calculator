function Params = setup_global_test_parameters(Params, data_set_name)

    Params = setparams();

    Params.save_directory = './test_power_calculator/';
    Params.data_dir = ['./data/', data_set_name];
       
    % I think this is enough - the effect size in the test matrix is brutal
    Params.n_perms = 100;
    Params.n_repetitions = 40;

    rep_cal_function(Params)

end