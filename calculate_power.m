%% Questions
    % There appears to be something wrong in the network level power
    % calculations - edge level and whole brain are fine
    % I likely made an error in the atlas 
    % Cluster has network-based stats not edge
    % Found it - Likely problem in edge groups!
    % 
    %% Potential fix - More resonable results!
    %   Used tril mask on extract_atlas_related_parameters for edge groups
    %   Removed atlas reordering in setupbenchmarking 

% Initial setup
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(scriptDir));
cd(scriptDir);
vars = who;       % Get a list of all variable names in the workspace
vars(strcmp(vars, 'RepData')) = [];  % Remove the variable you want to keep from the list
vars(strcmp(vars, 'GtData')) = [];
clear(vars{:});   % Clear all other variables
clc;

%% Directory to save and find rep data - TODO add them all
Params = setparams();

%% Create storage directory - only if it does not exist
if ~exist(Params.save_directory, 'dir') % Check if the directory does not exist
    mkdir(Params.save_directory);       % Create the directory
end

if ~exist('RepData', 'var') || ~exist('GtData', 'var')
    [GtData, RepData] = load_rep_and_gt_results(Params, 'gt_origin', Params.gt_origin);
end 

power_calculation_tprs = @(x) summarize_tprs('calculate_tpr', x, GtData, ...
                                             'save_directory', Params.save_directory);
dfs_struct(power_calculation_tprs, RepData);

