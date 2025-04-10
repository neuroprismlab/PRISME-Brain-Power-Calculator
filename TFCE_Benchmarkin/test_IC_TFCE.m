
vars = who;       % Get a list of all variable names in the workspace
vars(strcmp(vars, 'data_matrix')) = [];  % Remove the variable you want to keep from the list
vars(strcmp(vars, 'testing_yml_workflow')) = [];
clear(vars{:});   % Clear all other variables
clc;

Params = setparams();
Params.save_directory = './power_calculator_results/TFCE_comp_results/';

Params.data_dir = './data/s_hcp_fc_noble_tasks.mat';

Params.all_cluster_stat_types = {'Fast_TFCE'};

rep_cal_function(Params);



