function Params = setup_global_test_parameters(Params, data_set_name)

    Params.save_directory = './test_power_calculator/';
    Params.data_dir = ['./data/', data_set_name];
       
    % I think this is enough - the effect size in the test matrix is brutal
    % BE CAREFUL WITH SUBJECT NUMBER - if it's too low, some permutations
    % will be equal to the actual data and there will be ties when
    % performing the test! 
    Params.n_perms = 500;
    Params.n_repetitions = 20;
    Params.list_of_nsubset = {40};
    
    % Set test values equal to normal values - with a simple dataset like
    % the test one, there is no need for a difference
    Params.test_n_perms = Params.n_perms;
    Params.test_n_repetitions = Params.n_repetitions;
    Params.test_n_workers = 10;

    % Avoid future developer confusion 
    Params.testing = true;

end