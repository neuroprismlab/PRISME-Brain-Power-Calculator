%% Questions
    %
    %% Potential issues
    % - nbs_method different than statistic_type - ? 
    % - UI.size.ui - what is it?
    % - case 3,4, null_stats is not really stat, in get_constrained_stats
    % in NBSstats_smn.m
    %
    %% THE ONE BELOW IS SUPER IMPORTANT
    % - On NBSedge_level_parametric_corr - t-test (for t2) assumes that the
    % number of subjects in both groups is equal 
    % - should we correct for different group variances? Welch's app
    % - NBSglm_smn.m is using a simple average to calculate the t-test
    % statistics for the onesample case
    %
    % - Params.cluster_size_type - is it being used? 
    % - bgl value?
    % - Extent and Intensity - Which one?
    %
    % - Atlas name: map268_subnetwork.mat
    %
    %% TODO
    % - shen atlas check 
    % - what atlas for the abcd dataset? what are the other atlases
    % - fix t2 test
    % - check git task list
    %
    % PARAMETRIC METHOD MIGHT HAVE AN ISSUE

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

rep_cal_function(Params);




