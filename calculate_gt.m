%% Ground-Truth Power Calculator Workflow
% This script runs the ground-truth workflow for the power calculator. It uses 
% the entire dataset to compute t-test statistics for each functional connectivity 
% (FC) edge or network. A nonzero t-test value indicates the presence of an effect, 
% with the sign of the t-statistic indicating effect direction. Since the full dataset 
% is used, only one repetition is required.
%
% Usage:
%   1. Before running Calculate_gt, open setparams.m and manually update the 
%      parameters to suit your analysis (e.g., dataset file name, directories, etc.).
%   2. Save your changes in setparams.m.
%   3. Run Calculate_gt, which will load the updated parameters, load the dataset, 
%      configure the experiment (with ground_truth enabled), perform the t-tests, 
%      and save the ground-truth effect estimates.
%
% Key Points:
% - Uses the entire dataset (all subjects) for accurate effect size estimation.
% - Only one repetition is performed since a full-sample estimate is computed.
% - The t-test results are used to determine whether each FC edge shows a positive 
%   or negative effect.
% - Ground-truth results are saved for use in downstream power calculations.
%
% Workflow:
%   1. Load or generate the dataset.
%   2. Configure experiment parameters via setparams (ensure you update this file as needed).
%   3. Enable ground_truth mode and disable parallel processing.
%   4. Set up experiment parameters (n_nodes, n_var, n_repetitions) using setup_experiment_data.
%   5. Create the output directory and assign dataset names/atlas.
%   6. Load outcome and brain data from the dataset.
%   7. For each test, infer the test type and compute t-test statistics.
%   8. Set ground-truth-specific parameters and run the benchmarking workflow.
%
% Author: Fabricio Cravo | Date: March 2025

%% This needs to be optimized - Some could easily be moved to rep 
%% There is a lot of unnecesary redundancy added with the activation

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
    Dataset.file_name = Params.data_dir;
end

%% Set n_nodes, n_var, n_repetitions 
[Params.mask, Params.n_var, Params.n_nodes] = setup_experiment_data(Dataset);

%% Variables are nodes or edges (voxel - activation, or fc edges)
Params.variable_type = get_variable_type(Dataset);

%% Create directory and get dataset name - get atlas
[Params.output, Params.data_set_base, Params.data_set_map] = get_data_set_name(Dataset, Params);
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

     % Specific study mask data (some datasets have masks for each study)
        % The specific mask overrides the generic
    [RP.mask, RP.n_var, RP.n_nodes] = study_specific_mask(Dataset, Params, t);
    [RP.flat_to_spatial, RP.spatial_to_flat] = create_spatial_flat_map(RP);
    [RP.triumask, RP.trilmask] = create_masks_from_nodes(size(RP.mask, 1));

    % Create graph converter (flat to graph)
    RP.unflat_matrix_fun = unflatten_matrix(RP.mask, 'variable_type', ...
        RP.variable_type, 'flat_to_spatial', RP.flat_to_spatial, 'spatial_to_flat', RP.spatial_to_flat);


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


