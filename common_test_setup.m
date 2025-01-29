function Params = common_test_setup(data_set_name)
    
    %% Remove output folder if it exists
    if isfolder('./test_power_calculator/')
        rmdir('./test_power_calculator/', 's'); % 's' removes all subfolders and files
    end

    Params = setparams();
    Params = setup_global_test_parameters(Params, data_set_name);

end