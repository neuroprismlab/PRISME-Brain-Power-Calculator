%% Ground Truth NBS Benchmarking Workflow
% This script sets up and runs a ground-truth workflow for the power 
% calculator. It is used to estimate the true effect locations using all
% subjects from a dataset. 
%  It prepares parameters, loads data, configures the experiment, 
% and executes tests across different outcomes.
%
% Workflow:
% 1. Set the working directory to the script location and clear unwanted variables.
% 2. Add necessary paths for NBS_Calculator and supporting code.
% 3. Prepare parameters by calling setparams() and enabling ground truth mode 
%    (Params.ground_truth = true) with parallel processing disabled.
% 4. Load the dataset if it is not already in the workspace.
% 5. Setup experiment data (n_nodes, n_var, n_repetitions) via setup_experiment_data.
% 6. Create the output directory, get dataset name, and assign atlas file.
% 7. Create a ground truth-specific output directory.
% 8. Initialize parallel workers as specified.
% 9. For each test (field in OutcomeData):
%    a. Copy Params to RP and assign the test name.
%    b. Infer test type origin using infer_test_from_data.
%    c. Depending on the test type:
%       - Call subs_data_from_score_condition for 'score_cond' tests.
%       - Call subs_data_from_contrast for 'contrast' tests.
%    d. Create node masks.
%    e. Setup ground truth-specific parameters via setup_ground_truth_parameters.
%    f. Run the benchmarking process using run_benchmarking.
%
% Author: Fabricio Cravo | Date: March 2025
%
% Usage:
%   Simply run the script to execute the ground truth benchmarking workflow.

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


