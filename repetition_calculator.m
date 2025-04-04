%% Repetition Calculation Workflow
% This script sets up and runs the repetition calculation workflow for the 
% power calculator. It computes repeated statistical analyses on randomly 
% sampled subsets of subjects to enable power estimation via simulation.
%
% Usage:
%   1. Before running this script, open setparams.m and manually update the 
%      parameters specific to the repetition calculation (e.g., dataset file name,
%      number of repetitions, subset sizes, etc.).
%   2. Save your changes in setparams.m.
%   3. Run this script (e.g., calculate_repetitions) to load the data, configure 
%      parameters, perform the t-tests on each subset, and save the repetition results.
%
% Key Points:
% - Uses user-specified subset sizes and repetition counts to simulate repeated 
%   analyses.
% - Each repetition is based on a random sampling of subjects.
% - Results (e.g., p-values, edge statistics, and cluster statistics) are saved 
%   incrementally for downstream power calculations.
%
% Workflow:
%   1. Load or generate the dataset.
%   2. Configure experiment parameters using setparams.
%   3. Load data and prepare the experiment (via setup_experiment_data).
%   4. Create output directories and assign dataset names/atlas.
%   5. Initialize parallel processing (if enabled).
%   6. Loop over each test: infer test type, compute t-test statistics for 
%      the repetition subsets, and run the repetition workflow.
%   7. Save the updated results incrementally.
%
% Author: Fabricio Cravo | Date: March 2025

% Set working directory to the directory of this script
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(scriptDir));
cd(scriptDir);

vars = who;       % Get a list of all variable names in the workspace
vars(strcmp(vars, 'data_matrix')) = [];  % Remove the variable you want to keep from the list
vars(strcmp(vars, 'testing_yml_workflow')) = [];
clear(vars{:});   % Clear all other variables
clc;

[current_path,~,~] = fileparts(mfilename('fullpath')); % assuming NBS_benchmarking is current folder
addpath(genpath(current_path));

%% Get Params
Params = setparams();
Params.ground_truth = false;

rep_cal_function(Params);




