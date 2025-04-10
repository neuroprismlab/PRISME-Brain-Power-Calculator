%% TFCE Methods Benchmark Script
% This script benchmarks the Fast_TFCE method against traditional TFCE
% across different repetition counts while ensuring results are consistent.

% Clear workspace but keep important variables
vars = who; % Get a list of all variable names in the workspace
vars(strcmp(vars, 'data_matrix')) = []; % Remove variables you want to keep
vars(strcmp(vars, 'testing_yml_workflow')) = [];
clear(vars{:}); % Clear all other variables
clc;

% Initialize results storage
subject_counts = {40, 80, 120};
methods_to_compare = {'Fast_TFCE', 'TFCE'};

% Get the directory of the current script, and get parent directory
current_script_dir = fileparts(mfilename('fullpath'));
parent_dir = fileparts(current_script_dir);

% Change the current working directory to the parent directory
cd(parent_dir);

% Create the full path for the results directory
main_results_dir = './power_calculator_results/TFCE_benchmark';
if ~exist(main_results_dir, 'dir')
    mkdir(main_results_dir);
end

% Define path for benchmark results file
benchmark_filepath = fullfile(main_results_dir, 'benchmark_results.mat');

% Try to load existing benchmark results if available
if exist(benchmark_filepath, 'file')
    fprintf('Loading existing benchmark results from %s\n', benchmark_filepath);
    load(benchmark_filepath, 'benchmark_results');
else
    fprintf('No existing benchmark results found. Starting fresh.\n');
    benchmark_results = struct();
end

% Define path to clear
clear_dir = './power_calculator_results/TFCE_benchmark/hcp_fc/';

% Create the directory if it doesn't exist
if ~exist(clear_dir, 'dir')
    mkdir(clear_dir);
else
    % Remove only files that start with 'hcp' using standard MATLAB deletion
    files_to_remove = dir(fullfile(clear_dir, 'hcp*.*'));
    for i = 1:length(files_to_remove)
        if ~files_to_remove(i).isdir  % Make sure it's not a directory
            delete(fullfile(clear_dir, files_to_remove(i).name));
        end
    end
end

% Run benchmarks for each repetition count
for i = 1:numel(subject_counts)
    n_subs = subject_counts{i};
    n_subs_str = strcat('subs', '_', num2str(n_subs));

    % Check if this subject count has already been processed
    if isfield(benchmark_results, n_subs_str)
        fprintf('\n========================================\n');
        fprintf('Skipping completed benchmark with %d subjects\n', n_subs);
        fprintf('========================================\n\n');
        continue;
    end

    fprintf('\n========================================\n');
    fprintf('Starting benchmark with %d subjects\n', n_subs);
    fprintf('========================================\n\n');

    % Run each method
    fprintf('Running with subjects: %d\n', n_subs);
    
    % Set parameters for this run
    Params = setparams();
    Params.testing = false; % Disable testing mode to use full settings
    Params.save_directory = './power_calculator_results/TFCE_benchmark/';
    Params.data_dir = './data/s_hcp_fc_noble_tasks.mat';
    Params.all_cluster_stat_types = methods_to_compare;
    Params.n_perms = 1000;
    Params.n_repetitions = 50;
    Params.list_of_nsubset = {n_subs}; % Focus on 40 subjects only
        
    rep_cal_function(Params);
        
    % Find and load the results file
    result_files = dir(fullfile('./power_calculator_results/TFCE_benchmark/hcp_fc/', 'hcp_fc*.mat'));
    if isempty(result_files)
        error('No result files found for method %s with %d repetitions', current_method, n_reps);
    end
    
    for file_idx = 1:length(result_files)
        % Get full path for the current file
        current_file_path = fullfile(result_files(file_idx).folder, result_files(file_idx).name);
        
        % Load the current file
        current_results = load(current_file_path);
        
        components = strcat(current_results.meta_data.test_components{1}, '_', ...
            current_results.meta_data.test_components{2});
        
        benchmark_results.(n_subs_str).(components).Fast_TFCE= current_results.Fast_TFCE;
        benchmark_results.(n_subs_str).(components).TFCE = current_results.TFCE;

    end

    % Get all the component fields from Fast_TFCE
    f_total_time_acr_task = sum(structfun(@(x) x.Fast_TFCE.total_time, benchmark_results.(n_subs_str)));
    t_total_time_acr_task = sum(structfun(@(x) x.TFCE.total_time, benchmark_results.(n_subs_str)));
        
    benchmark_results.(n_subs_str).total_time_Fast_TFCE = f_total_time_acr_task;
    benchmark_results.(n_subs_str).total_time_TFCE = t_total_time_acr_task;
    benchmark_results.(n_subs_str).total_speed_up = t_total_time_acr_task/f_total_time_acr_task;
    
    alpha = Params.pthresh_second_level;
    
    % Get all task names automatically
    task_names = fieldnames(benchmark_results.(n_subs_str));
    is_task = ~startsWith(task_names, 'total');
    task_names = task_names(is_task);
    
    % Process each task
    for j = 1:length(task_names)
        task = task_names{j};
        
        % Skip if this is a metadata field like 'total_time'
        if strcmp(task, 'total_time')
            continue;
        end
        
        % Initialize variables to accumulate matching percentages across repetitions
        total_matching_pct_pos = 0;
        total_matching_pct_neg = 0;
        
        % Arrays to store individual values for stats calculation
        matching_pcts_pos = zeros(1, Params.n_repetitions);
        matching_pcts_neg = zeros(1, Params.n_repetitions);
        
        % Process each repetition
        for rep = 1:Params.n_repetitions
            % Get the thresholded significance maps for positive effects
            fast_tfce_sig = benchmark_results.(n_subs_str).(task).Fast_TFCE.sig_prob(:,rep) > (1-alpha);
            tfce_sig = benchmark_results.(n_subs_str).(task).TFCE.sig_prob(:,rep) > (1-alpha);
            
            % Always calculate percentage of matching voxels for positive effects
            matching_pct_pos = sum(fast_tfce_sig(:) == tfce_sig(:)) / numel(fast_tfce_sig) * 100;
            total_matching_pct_pos = total_matching_pct_pos + matching_pct_pos;
            matching_pcts_pos(rep) = matching_pct_pos;
            
            % Same for negative effects
            fast_tfce_neg = benchmark_results.(n_subs_str).(task).Fast_TFCE.sig_prob_neg(:,rep) > (1-alpha);
            tfce_neg = benchmark_results.(n_subs_str).(task).TFCE.sig_prob_neg(:,rep) > (1-alpha);
            
            % Always calculate percentage of matching voxels for negative effects
            matching_pct_neg = sum(fast_tfce_neg(:) == tfce_neg(:)) / numel(fast_tfce_neg) * 100;
            total_matching_pct_neg = total_matching_pct_neg + matching_pct_neg;
            matching_pcts_neg(rep) = matching_pct_neg;
        end
        
        % Calculate averages across repetitions (keep original calculation)
        avg_matching_pct_pos = total_matching_pct_pos / Params.n_repetitions;
        avg_matching_pct_neg = total_matching_pct_neg / Params.n_repetitions;
        
        % Store original results (unchanged)
        benchmark_results.(n_subs_str).(task).avg_similarity = (avg_matching_pct_pos + avg_matching_pct_neg) / 2;
        
        % Calculate and store variances
        var_pos = var(matching_pcts_pos);
        var_neg = var(matching_pcts_neg);
        
        % Calculate 95% confidence intervals
        t_critical = tinv(0.975, Params.n_repetitions - 1);
        std_pos = std(matching_pcts_pos);
        std_neg = std(matching_pcts_neg);
        
        ci_pos = [avg_matching_pct_pos - t_critical * (std_pos / sqrt(Params.n_repetitions)), 
                  avg_matching_pct_pos + t_critical * (std_pos / sqrt(Params.n_repetitions))];
        
        ci_neg = [avg_matching_pct_neg - t_critical * (std_neg / sqrt(Params.n_repetitions)), 
                  avg_matching_pct_neg + t_critical * (std_neg / sqrt(Params.n_repetitions))];
        
        % Calculate combined variance and CI for similarity
        similarity_values = (matching_pcts_pos + matching_pcts_neg) / 2;
        var_similarity = var(similarity_values);
        std_similarity = std(similarity_values);
        
        ci_similarity = [benchmark_results.(n_subs_str).(task).avg_similarity - t_critical * (std_similarity / sqrt(Params.n_repetitions)), 
                         benchmark_results.(n_subs_str).(task).avg_similarity + t_critical * (std_similarity / sqrt(Params.n_repetitions))];
        
        % Add statistics (without changing existing structure)
        benchmark_results.(n_subs_str).(task).variance_pos = var_pos;
        benchmark_results.(n_subs_str).(task).variance_neg = var_neg;
        benchmark_results.(n_subs_str).(task).variance_similarity = var_similarity;
        benchmark_results.(n_subs_str).(task).ci_95_pos = ci_pos;
        benchmark_results.(n_subs_str).(task).ci_95_neg = ci_neg;
        benchmark_results.(n_subs_str).(task).ci_95_similarity = ci_similarity;
    end

    task_fields = fieldnames(benchmark_results.(n_subs_str));
    valid_fields = cellfun(@(f) ~startsWith(f,'total') && ...
        isfield(benchmark_results.(n_subs_str).(f),'avg_similarity'), task_fields);
    valid_tasks = task_fields(valid_fields);

     % Get all the component fields from Fast_TFCE
    benchmark_results.(n_subs_str).avg_similarity = mean(arrayfun(@(i) ...
        benchmark_results.(n_subs_str).(valid_tasks{i}).avg_similarity, 1:length(valid_tasks)));

    % Save benchmark results after each subject count
    save(benchmark_filepath, 'benchmark_results');
    fprintf('Benchmark results saved to %s\n', benchmark_filepath);

end

total_time_fast = sum(structfun(@(x) x.total_time_Fast_TFCE, benchmark_results));
total_time_tfce = sum(structfun(@(x) x.total_time_TFCE, benchmark_results));

benchmark_results.total_time_Fast_TFCE = total_time_fast;
benchmark_results.total_time_TFCE = total_time_tfce;
benchmark_results.total_speed_up = benchmark_results.total_time_Fast_TFCE/benchmark_results.total_time_TFCE;

save(benchmark_filepath, 'benchmark_results');
fprintf('Benchmark results saved to %s\n', benchmark_filepath);


