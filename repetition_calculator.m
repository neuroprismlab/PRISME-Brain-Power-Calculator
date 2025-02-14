%% Questions
    %
    %% Potential issues
    % - nbs_method different than statistic_type - ?
    % - read_exchange - says optional - how?    
    % - UI.size.ui - what is it?
    % - UI.edge_groups.ui=edge_groups and
    % - UI.use_preaveraged_constrained.ui=edge_groups are receiving the same
    % variable? why?
    % - case 3,4, null_stats is not really stat, in get_constrained_stats
    % in NBSstats_smn.m
    %% THE ONE BELOW IS SUPER IMPORTANT
    % - On NBSedge_level_parametric_corr - t-test (for t2) assumes that the
    % number of subjects in both groups is equal 
    % - NBSglm_smn.m is using a simple average to calculate the t-test
    % statistics for the onesample case
    %
    % - What is SEA and why is it mentioned in the code?
    % - The same for 'Multidimensional_cNBS' 
    % - Line 377 of NBSrun_smn.m - strcmp(nbs.STATS.statistic_type,'SEA')
    % - Params.cluster_size_type - is it being used? 
    % - bgl value?
    % - Extent and Intensity - Which one?
    %
    % - Atlas name: map268_subnetwork.mat
    %% TODO
    % - shen atlas check 
    % - what atlas for the abcd dataset? what are the other atlases 

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




