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
fast_tfce_methods = {'Fast_TFCE_dh1', 'Fast_TFCE_dh5', 'Fast_TFCE_dh50', 'Fast_TFCE_dh100', 'Fast_TFCE_dh175', 'Fast_TFCE_dh250'};
tfce_methods = {'TFCE_dh1', 'TFCE_dh5', 'TFCE_dh50', 'TFCE_dh100', 'TFCE_dh175', 'TFCE_dh250'};
dh_values = [1, 5, 50, 100, 175, 250]; % dh values for each method

% Combine all methods
all_methods = [fast_tfce_methods, tfce_methods];

% Get the directory of the current script
current_script_dir = fileparts(mfilename('fullpath'));
parent_dir = fileparts(current_script_dir);

% Change the current working directory to the parent directory
cd(parent_dir);

% Create the full path for the results directory - using a different folder
speed_results_dir = './tfce_speed_comparison_results/';
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
fprintf('Starting TFCE vs Fast_TFCE Speed Comparison\n');
fprintf('========================================\n\n');

% Set parameters
Params = setparams();
Params.testing = false;
Params.save_directory = speed_results_dir;
Params.data_dir = './data/s_hcp_fc_noble_tasks.mat';
Params.all_cluster_stat_types = all_methods; % All methods at once
Params.n_perms = 10; % Reduced number of permutations since we're just comparing speed
Params.n_repetitions = 5; % Reduced number of repetitions
Params.list_of_nsubset = {20}; % Using 20 subjects
Params.save_significance_thresh = 0.15;

% ADD HERE: Skip tests on parameters if needed
% Params.skip_param_tests = true; 

% Run the analysis
rep_cal_function(Params);

% Find and load the results file
result_files = dir(fullfile(speed_results_dir, 'hcp_fc', 'hcp_fc*.mat'));
if isempty(result_files)
    error('No result files found for %d repetitions', Params.n_repetitions);
end

% Load and store the results from the first result file (first task only)
speed_results = struct();
current_file_path = fullfile(result_files(1).folder, result_files(1).name);
current_results = load(current_file_path);

% Get the task name
components = strcat(current_results.meta_data.test_components{1}, '_', ...
    current_results.meta_data.test_components{2});

fprintf('Analyzing speed for task: %s\n', components);

% Extract execution times for each method
speed_results.task_name = components;
speed_results.dh_values = dh_values;
speed_results.fast_tfce_times = zeros(1, length(fast_tfce_methods));
speed_results.tfce_times = zeros(1, length(tfce_methods));
speed_results.speed_gain = zeros(1, length(dh_values));
speed_results.percent_speed_gain = zeros(1, length(dh_values));

% Process Fast_TFCE methods
for m = 1:length(fast_tfce_methods)
    method = fast_tfce_methods{m};
    if isfield(current_results, method) && isfield(current_results.(method), 'total_time')
        speed_results.fast_tfce_times(m) = current_results.(method).total_time;
        fprintf('Fast_TFCE with dh=%d took %.2f seconds\n', dh_values(m), speed_results.fast_tfce_times(m));
    else
        fprintf('Warning: Total time not found for method %s\n', method);
        speed_results.fast_tfce_times(m) = NaN;
    end
end

% Process TFCE methods
for m = 1:length(tfce_methods)
    method = tfce_methods{m};
    if isfield(current_results, method) && isfield(current_results.(method), 'total_time')
        speed_results.tfce_times(m) = current_results.(method).total_time;
        fprintf('TFCE with dh=%d took %.2f seconds\n', dh_values(m), speed_results.tfce_times(m));
    else
        fprintf('Warning: Total time not found for method %s\n', method);
        speed_results.tfce_times(m) = NaN;
    end
end

% Calculate speed gain (time difference and percentage)
for i = 1:length(dh_values)
    if ~isnan(speed_results.tfce_times(i)) && ~isnan(speed_results.fast_tfce_times(i))
        % Absolute time saved (in seconds)
        speed_results.speed_gain(i) = speed_results.tfce_times(i) - speed_results.fast_tfce_times(i);
        
        % Percentage speed improvement
        speed_results.percent_speed_gain(i) = (speed_results.speed_gain(i) / speed_results.tfce_times(i)) * 100;
        
        fprintf('dh=%d: Speed gain = %.2f seconds (%.2f%%)\n', ...
            dh_values(i), speed_results.speed_gain(i), speed_results.percent_speed_gain(i));
    else
        speed_results.speed_gain(i) = NaN;
        speed_results.percent_speed_gain(i) = NaN;
    end
end

% Create a figure to visualize the speed gain
figure;
bar(dh_values, speed_results.percent_speed_gain);
xlabel('dh Value');
ylabel('Speed Gain (%)');
title(sprintf('Fast_TFCE vs TFCE Speed Gain for %s', components));
grid on;

% Save the figure
saveas(gcf, fullfile(speed_results_dir, 'speed_gain_visualization.png'));
saveas(gcf, fullfile(speed_results_dir, 'speed_gain_visualization.fig'));

% Save the speed comparison results
save(speed_comparison_filepath, 'speed_results');
fprintf('Speed comparison results saved to %s\n', speed_comparison_filepath);

% Print summary
fprintf('\n========================================\n');
fprintf('Summary of Speed Comparison\n');
fprintf('========================================\n');
fprintf('Task: %s\n', speed_results.task_name);
fprintf('Average Fast_TFCE execution time: %.2f seconds\n', mean(speed_results.fast_tfce_times, 'omitnan'));
fprintf('Average TFCE execution time: %.2f seconds\n', mean(speed_results.tfce_times, 'omitnan'));
fprintf('Average speed gain: %.2f seconds (%.2f%%)\n', ...
    mean(speed_results.speed_gain, 'omitnan'), mean(speed_results.percent_speed_gain, 'omitnan'));
fprintf('Maximum speed gain: %.2f%% (at dh=%d)\n', ...
    max(speed_results.percent_speed_gain), dh_values(speed_results.percent_speed_gain == max(speed_results.percent_speed_gain)));