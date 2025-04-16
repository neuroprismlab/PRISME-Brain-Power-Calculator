%% TFCE Methods Benchmark Script
% This script benchmarks the Fast_TFCE method across different permutation counts
% to assess the impact on significance values.
% Clear workspace but keep important variables
vars = who;
vars(strcmp(vars, 'data_matrix')) = [];
vars(strcmp(vars, 'testing_yml_workflow')) = [];
clear(vars{:});
clc;

% Initialize results storage
subject_counts = {20}; % Using only 20 subjects - although this is not used
methods_to_compare = {'Fast_TFCE_per500', 'Fast_TFCE_per800', 'Fast_TFCE_per1000', ...
    'Fast_TFCE_per2000'};
permutation_counts = [500, 800, 1000, 2000]; % Number of permutations for each method
% Get the directory of the current script
current_script_dir = fileparts(mfilename('fullpath'));
parent_dir = fileparts(current_script_dir);
% Change the current working directory to the parent directory
cd(parent_dir);
% Create the full path for the results directory
main_results_dir = './power_calculator_results/TFCE_permutation/';
if ~exist(main_results_dir, 'dir')
    mkdir(main_results_dir);
end

% Define path for benchmark results file
benchmark_filepath = fullfile(main_results_dir, 'permutation_benchmark_results_20subs.mat'); % Changed filename
% Try to load existing benchmark results if available
if exist(benchmark_filepath, 'file')
    error('Delete or remove old file to continue')
else
    fprintf('No existing benchmark results found. Starting fresh.\n');
    benchmark_results = struct();
end

% Define path to clear.  Adjusted for new directory structure.
clear_dir = fullfile(main_results_dir, 'hcp_fc');
if ~exist(clear_dir, 'dir')
    mkdir(clear_dir);
end

% Run benchmarks for the subject count - NO LOOP ANYMORE
n_subs = subject_counts{1}; % Get the value directly - NOT USED ANYMORE
n_subs_str = 'results'; % Simplified naming
fprintf('\n========================================\n');
fprintf('Starting permutation_benchmark\n');
fprintf('========================================\n\n');
% Initialize struct to store results.  Simplified.
benchmark_results = struct(); % Store directly in benchmark_results
% Run all methods together
fprintf('Running all methods with subjects: %d\n', n_subs);

% Set parameters
Params = setparams();
Params.testing = false;
Params.save_directory = main_results_dir;
Params.data_dir = './data/s_hcp_fc_noble_tasks.mat';
Params.all_cluster_stat_types = methods_to_compare; % Run all methods
Params.n_perms = 2000; % Number of permutations for p-value calculation
Params.n_repetitions = 50; % Number of times the p-value estimation is repeated
Params.list_of_nsubset = {n_subs};
Params.save_significance_thresh = 0.15; % Changed significance threshold

rep_cal_function(Params);
% Find and load the results file.

result_files = dir(fullfile(main_results_dir, 'hcp_fc', 'hcp_fc*.mat'));
if isempty(result_files)
    error('No result files found for  %d repetitions',  Params.n_repetitions);
end

% Load and store the results from all files
permutation_results = struct();  % To store results from all files
for file_idx = 1:length(result_files)
    current_file_path = fullfile(result_files(file_idx).folder, result_files(file_idx).name);
    current_results = load(current_file_path);
    components = strcat(current_results.meta_data.test_components{1}, '_', ...
        current_results.meta_data.test_components{2});
    
    if ~isfield(permutation_results, components)
        permutation_results.(components) = struct();
    end
    
    for m = 1:length(methods_to_compare)
        current_method = methods_to_compare{m};
        permutation_results.(components).(current_method) = current_results.(current_method);
    end
end

% After all permutations are done, compare the results.
alpha = Params.pthresh_second_level;
task_names = fieldnames(permutation_results); % Use top-level
is_task = ~startsWith(task_names, 'total');
task_names = task_names(is_task);

for j = 1:length(task_names)
    task = task_names{j};
    
    % Get the sig values for the highest permutation count as the base
    [~, max_perm_index] = max(permutation_counts);
    base_method = methods_to_compare{max_perm_index};
    if ~isfield(permutation_results.(task), base_method)
        error('Missing base method');
    end
    base_sig_prob = permutation_results.(task).(base_method).sig_prob;
    base_sig_prob_neg = permutation_results.(task).(base_method).sig_prob_neg;
    
    % Compare against the other permutation counts
    for m = 1:length(methods_to_compare)
        current_method = methods_to_compare{m};
        if ~isfield(permutation_results.(task), current_method)
            continue;
        end
        current_sig_prob = permutation_results.(task).(current_method).sig_prob;
        current_sig_prob_neg = permutation_results.(task).(current_method).sig_prob_neg;
        
        % Calculate the absolute difference, considering only p-values <= 0.15
        valid_indices_pos = base_sig_prob >= 0.9;
        valid_indices_neg = base_sig_prob_neg >= 0.9;
        
        sig_diff_pos = abs(current_sig_prob - base_sig_prob) .* valid_indices_pos;
        sig_diff_neg = abs(current_sig_prob_neg - base_sig_prob_neg) .* valid_indices_neg;
        
        % Store the results
        permutation_results.(task).(current_method).sig_diff_pos = mean(sig_diff_pos, 2); % Mean across repetitions
        permutation_results.(task).(current_method).sig_diff_neg = mean(sig_diff_neg, 2); % Mean across repetitions
        
        % Store the mean and max absolute difference across edges
        mean_pos_across_edges = mean(permutation_results.(task).(current_method).sig_diff_pos);
        mean_neg_across_edges = mean(permutation_results.(task).(current_method).sig_diff_neg);
        
        % Calculate the mean of the mean across repetitions.
        permutation_results.(task).(current_method).mean_pos = mean(mean_pos_across_edges);
        permutation_results.(task).(current_method).max_pos  = max(sig_diff_pos,[],1); % Max for each repetition
        permutation_results.(task).(current_method).mean_neg = mean(mean_neg_across_edges);
        permutation_results.(task).(current_method).max_neg  = max(sig_diff_neg,[],1);  % Max for each repetition
        
        % Calculate the 95% confidence interval for sig_diff_pos
        alpha_ci = 0.05; % significance level
        n_reps = size(sig_diff_pos, 2); % Number of repetitions
        
        if n_reps > 1
            sem_pos = std(sig_diff_pos, 0, 2) / sqrt(n_reps);  % Standard error of the mean
            t_crit = tinv(1 - alpha_ci / 2, n_reps - 1);      % T-critical value
            ci_lower_pos = mean_pos_across_edges - t_crit * sem_pos;
            ci_upper_pos = mean_pos_across_edges + t_crit * sem_pos;
            
            permutation_results.(task).(current_method).ci_95_pos = full([ci_lower_pos, ci_upper_pos]);
            
            sem_neg = std(sig_diff_neg, 0, 2) / sqrt(n_reps);  % Standard error of the mean
            t_crit_neg = tinv(1 - alpha_ci / 2, n_reps - 1);      % T-critical value
            ci_lower_neg = mean_neg_across_edges - t_crit_neg * sem_neg;
            ci_upper_neg = mean_neg_across_edges + t_crit_neg * sem_neg;
            
            permutation_results.(task).(current_method).ci_95_neg = full([ci_lower_neg, ci_upper_neg]);
            
             % Calculate CI for max_pos_across_reps
            max_pos_across_reps = permutation_results.(task).(current_method).max_pos;
            sem_max_pos = std(max_pos_across_reps) / sqrt(n_reps);
            ci_lower_max_pos =  mean(max_pos_across_reps) - t_crit * sem_max_pos;
            ci_upper_max_pos =  mean(max_pos_across_reps) + t_crit * sem_max_pos;
            permutation_results.(task).(current_method).ci_95_max_pos = full([ci_lower_max_pos; ci_upper_max_pos]);
            
            % Calculate CI for max_neg_across_reps
            max_neg_across_reps = permutation_results.(task).(current_method).max_neg;
            sem_max_neg = std(max_neg_across_reps) / sqrt(n_reps);
            ci_lower_max_neg =  mean(max_neg_across_reps) - t_crit * sem_max_neg;
            ci_upper_max_neg =  mean(max_neg_across_reps) + t_crit * sem_max_neg;
            permutation_results.(task).(current_method).ci_95_max_neg = full([ci_lower_max_neg; ci_upper_max_neg]);
            
        else
             permutation_results.(task).(current_method).ci_95_pos = full(NaN(2,1));
             permutation_results.(task).(current_method).ci_95_neg = full(NaN(2,1));
             permutation_results.(task).(current_method).ci_95_max_pos = full(NaN(2,1));
             permutation_results.(task).(current_method).ci_95_max_neg = full(NaN(2,1));
        end
        
    end
        
end

% Save the results.
save(benchmark_filepath, 'permutation_results');
fprintf('Benchmark results saved to %s\n', benchmark_filepath);

