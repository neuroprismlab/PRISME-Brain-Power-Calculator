function Params = common_test_setup(data_set_name)
%% common_test_setup
% Configures standard parameters for unit testing statistical methods using a toy dataset.
%
% This function sets default parameter values for use in testing workflows. It deletes any
% previous output folders to avoid residual interference, disables parallel processing
% (for deterministic behavior), and ensures test values match main parameters.
%
% Inputs:
%   - data_set_name: String name of the test dataset (e.g., 'test_hcp_fc.mat')
%
% Output:
%   - Params: Struct containing all required configuration fields for test execution.
    
    %% Remove output folder if it exists
    if isfolder(['./power_calculator_results/', data_set_name, '/'])
        rmdir(['./power_calculator_results/', data_set_name, '/'], 's'); % 's' removes all subfolders and files
    end

    Params = setparams();

    Params.save_directory = './power_calculator_results/';
    Params.data_dir = ['./data/', data_set_name];
    
    [~, output_name, ~] = fileparts(data_set_name);
    Params.output = output_name;

    % Tests in actions can only be run sequentially in MatLab
    Params.parallel = false;
    
    % I think this is enough - the effect size in the test matrix is brutal
    % BE CAREFUL WITH SUBJECT NUMBER - if it's too low, some permutations
    % will be equal to the actual data and there will be ties when
    % performing the test! 
    Params.n_perms = 100;
    Params.n_repetitions = 20;
    Params.list_of_nsubset = {40};
    
    % Set test values equal to normal values - with a simple dataset like
    % the test one, there is no need for a difference
    Params.test_n_perms = Params.n_perms;
    Params.test_n_repetitions = Params.n_repetitions;
    Params.test_n_workers = 10;

    % Avoid future developer confusion 
    Params.testing = true;
    Params.test_disable_save = false;

end