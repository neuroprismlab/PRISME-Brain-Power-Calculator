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

[current_path, ~, ~] = fileparts(mfilename('fullpath')); % assuming NBS_benchmarking is current folder
addpath(genpath(current_path));

%% Prepare parameters and dataset
Params = setparams();
Params.ground_truth = true;
Params.parallel = false;

%% Load data
if ~exist('Dataset', 'var')
    Dataset = load(Params.data_dir);
end

%% Set n_nodes, n_var, n_repetitions 
Params = setup_experiment_data(Params, Dataset);

%% Create directory and get dataset name - get atlas
[Params.data_set, Params.data_set_base, Params.data_set_map] = get_data_set_name(Dataset);
Params.atlas_file = atlas_data_set_map(Params);

%% Create gt output directory
Params = create_gt_output_directory(Params);

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

    [RP, test_type_origin] = infer_test_from_data(RP, OutcomeData.(t), BrainData);
        
    % Important, X is calculated here for all test_types
    % However, only the r test type will use this test
    switch test_type_origin
        
        % Here: RP.test_name, RP.n_subs_1, RP.n_subs_2, RP.n_subs
        case 'score_cond'
            [X, Y , RP] = subs_data_from_score_condition(RP, OutcomeData.(t), BrainData, t);
       
        case 'contrast'
            [X, Y , RP] = subs_data_from_contrast(RP, OutcomeData.(t).contrast, BrainData);
        
        otherwise
            error('Test type origin not found')

    end  
    
    [RP.triumask, RP.trilmask] = create_masks_from_nodes(size(RP.mask, 1));
    
    % Sets subject repetition to all subjects and others
    RP = setup_ground_truth_parameters(RP);

    run_benchmarking(RP, Y, X)
    
end


