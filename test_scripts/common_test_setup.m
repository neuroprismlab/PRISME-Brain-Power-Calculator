function Params = common_test_setup(data_set_name)
    
    %% Remove output folder if it exists
    if isfolder('./test_power_calculator/')
        rmdir('./test_power_calculator/', 's'); % 's' removes all subfolders and files
    end

    Params = setparams();

    Params.save_directory = './test_power_calculator/';
    Params.data_dir = ['./data/', data_set_name];

    % Tests in actions can only be run sequentially in MatLab
    Params.parallel = false;
    
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