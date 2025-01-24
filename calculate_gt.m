%%%%%
    %% Questions
        % - subtraction and t-test is way more computationally efficient than
        % paired -t
        % - started calculations
        % - in create_test_contrast
            % nbs_exchange for t test? what is it? 
        % - ground_truth code? what do remove what to keep?
%%%%%

% Change for test

addpath('/Users/f.cravogomes/Desktop/Cloned Repos/NBS_Calculator')

% Set working directory to the directory of this script
scriptDir = fileparts(mfilename('fullpath'));
cd(scriptDir);

a = 10;
vars = who;       % Get a list of all variable names in the workspace
vars(strcmp(vars, 'data_matrix')) = [];  % Remove the variable you want to keep from the list
clear(vars{:});   % Clear all other variables
clc;

data_dir = '/Users/f.cravogomes/Desktop/Cloned Repos/NBS_Calculator/data/s_hcp_fc_noble_tasks.mat';
if ~exist('Dataset', 'var')
    Dataset = load(data_dir);
else
    % disp('Data already loaded')
end
% Extract dataset name
[~, data_set_name, ~] = fileparts(data_dir);

[current_path, ~, ~] = fileparts(mfilename('fullpath')); % assuming NBS_benchmarking is current folder
addpath(genpath(current_path));

%% Prepare parameters and dataset
Params = setparams();

if ~exist('Dataset', 'var')
    Dataset = load(Params.data_dir);
else
    % disp('Data already loaded')
end

%% Set n_nodes, n_var, n_repetitions 
Params = setup_experiment_data(Params, Dataset);

%% Create directory and get dataset name
Params.save_directory = [Params.save_directory, 'ground_truth/'];
Params = create_output_directory(Params);
Params.data_set = get_data_set_name(Dataset);

%% Paralle workers
setup_parallel_workers(Params.parallel, Params.n_workers);

OutcomeData = Dataset.outcome;
BrainData = Dataset.brain_data;

tests = fieldnames(OutcomeData);

for ti = 1:length(tests)
    t = tests{ti};
    % Fix RP both tasks
    % RP - stands for Repetition Parameters
    RP = Params;
    RP.test_name = t;

    RP = infer_test_from_data(RP, OutcomeData.(t), BrainData);
    
    % y_and_x also extracts subject number and sub_ids
    % Encapsulate this level of setup in a function if there is to much
    % function calls here 
    [~, Y , RP] = subs_data_from_contrast(RP, OutcomeData.(t).contrast, BrainData);
    [RP.triumask, RP.trilmask] = create_masks_from_nodes(size(RP.mask, 1));
    
    % Sets subject repetition to all subjects and others
    RP = setup_ground_truth_parameters(RP);

    run_benchmarking(RP, Y)
    
    return;
    if RP.testing == 1 && ti == 2
        return;
    end
    
end


