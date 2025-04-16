%% TFCE vs Fast_TFCE Speed Comparison Script
% This script compares the speed of TFCE and Fast_TFCE methods across different dh values
% to assess the performance gains.

% Clear workspace but keep important variables
vars = who;
vars(strcmp(vars, 'data_matrix')) = [];
vars(strcmp(vars, 'testing_yml_workflow')) = [];
clear(vars{:});
clc;

% Initialize methods to compare
fast_tfce_methods = {'Fast_TFCE_dh1', 'Fast_TFCE_dh5', 'Fast_TFCE_dh50', 'Fast_TFCE_dh100', 'Fast_TFCE_dh250'};
tfce_methods = {'TFCE_dh1', 'TFCE_dh5', 'TFCE_dh50', 'TFCE_dh100', 'TFCE_dh250'};
dh_values = [1, 5, 50, 100, 250]; % dh values for each method

% Combine all methods
all_methods = [fast_tfce_methods, tfce_methods];

% Get the directory of the current script
current_script_dir = fileparts(mfilename('fullpath'));
parent_dir = fileparts(current_script_dir);

% Change the current working directory to the parent directory
cd(parent_dir);

% Create the full path for the results directory - using a different folder
speed_results_dir = './power_calculator_results/tfce_speed_comparison_results/';
if ~exist(speed_results_dir, 'dir')
    mkdir(speed_results_dir);
end

% Define path for speed comparison results file
speed_comparison_filepath = fullfile(speed_results_dir, 'tfce_speed_comparison_results.mat');

% Check if results already exist
if exist(speed_comparison_filepath, 'file')
    error('Delete or remove old file to continue')
else
    fprintf('No existing speed comparison results found. Starting fresh.\n');
    speed_results = struct();
end

% Define path to clear
clear_dir = fullfile(speed_results_dir, 'hcp_fc');
if ~exist(clear_dir, 'dir')
    mkdir(clear_dir);
end

% Set up parameters
fprintf('\n========================================\n');
fprintf('Starting TFCE vs Fast_TFCE dh Speed Comparison\n');
fprintf('========================================\n\n');

% Set parameters
Params = setparams();
Params.testing = false;
Params.save_directory = speed_results_dir;
Params.data_dir = './data/s_hcp_fc_noble_tasks.mat';
Params.all_cluster_stat_types = all_methods; % All methods at once
Params.n_perms = 100; % Reduced number of permutations since we're just comparing speed
Params.n_repetitions = 10; % Reduced number of repetitions
Params.list_of_nsubset = {20}; % Using 20 subjects
Params.save_significance_thresh = 0.15;

% ADD HERE: Skip tests on parameters if needed
% Params.skip_param_tests = true; 

% Run the analysis
rep_cal_function(Params);

% Find and load the results files
result_files = dir(fullfile(speed_results_dir, 'hcp_fc', 'hcp_fc*.mat'));
if isempty(result_files)
    error('No result files found for %d repetitions', Params.n_repetitions);
end

fprintf('Found %d result files. Loading all tasks...\n', length(result_files));

% Initialize the results structure
speed_results = struct();
speed_results.tasks = {};
speed_results.dh_values = dh_values;

% Create structures to store timing data across all tasks
all_fast_tfce_times = zeros(length(fast_tfce_methods), length(result_files));
all_tfce_times = zeros(length(tfce_methods), length(result_files));
task_names = cell(1, length(result_files));

% Process all result files
for file_idx = 1:length(result_files)
    temp_file_path = fullfile(result_files(file_idx).folder, result_files(file_idx).name);
    temp_results = load(temp_file_path);
    
    % Get the task name
    task_name = strcat(temp_results.meta_data.test_components{1}, '_', ...
        temp_results.meta_data.test_components{2});
    task_names{file_idx} = task_name;
    
    % Extract Fast_TFCE times for this task
    for m = 1:length(fast_tfce_methods)
        method = fast_tfce_methods{m};
        if isfield(temp_results, method) && isfield(temp_results.(method), 'total_time')
            all_fast_tfce_times(m, file_idx) = temp_results.(method).total_time;
        else
            all_fast_tfce_times(m, file_idx) = NaN;
        end
    end
    
    % Extract TFCE times for this task
    for m = 1:length(tfce_methods)
        method = tfce_methods{m};
        if isfield(temp_results, method) && isfield(temp_results.(method), 'total_time')
            all_tfce_times(m, file_idx) = temp_results.(method).total_time;
        else
            all_tfce_times(m, file_idx) = NaN;
        end
    end

    speed_results.all_fast_tfce_times = all_fast_tfce_times;
    speed_results.all_tfce_times = all_tfce_times;
end

% Store all task names
speed_results.tasks = task_names;

% Calculate average times across all tasks
speed_results.fast_tfce_times = nanmean(all_fast_tfce_times, 2)';
speed_results.tfce_times = nanmean(all_tfce_times, 2)';

% Calculate speed gain (time difference and percentage)
speed_results.speed_gain = zeros(1, length(dh_values));

for i = 1:length(dh_values)
    speed_results.speed_gain(i) = speed_results.tfce_times(i)/speed_results.fast_tfce_times(i);     
end

% Save the speed comparison results
save(speed_comparison_filepath, 'speed_results');
