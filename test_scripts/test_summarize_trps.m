
% Initial setup
addpath(genpath('/Users/f.cravogomes/Desktop/Cloned Repos/NBS_Calculator'))
scriptDir = fileparts(mfilename('fullpath'));
cd(scriptDir);
vars = who;       % Get a list of all variable names in the workspace
vars(strcmp(vars, 'RepData')) = [];  % Remove the variable you want to keep from the list
vars(strcmp(vars, 'GtData')) = [];
clear(vars{:});   % Clear all other variables
clc;

power_calculation_tprs = @(x) summarize_tprs('calculate_tpr', x, GtData);
dfs_struct(power_calculation_tprs, RepData);

