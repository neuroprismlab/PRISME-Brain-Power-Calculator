%% TFCE vs Fast_TFCE Similarity Heatmap Generator
% This script generates a single heatmap showing the percentage agreement between
% TFCE and Fast_TFCE methods, aggregated across all tasks and subject counts.

% Get the directory of the current script
current_script_dir = fileparts(mfilename('fullpath'));
parent_dir = fileparts(current_script_dir);

% Define path for benchmark results file
benchmark_filepath = fullfile(parent_dir, 'power_calculator_results', 'TFCE_benchmark', 'benchmark_results.mat');

% Output directory for saving figures
output_dir = fullfile(parent_dir, 'power_calculator_results', 'TFCE_benchmark');

% Load the benchmark results
load(benchmark_filepath);

% Define parameters
alpha = 0.05; % Significance threshold

% Initialize arrays to store all match percentages
all_match_percentages_pos = [];
all_match_percentages_neg = [];
match_counts = 0;

% Get all subject counts
subject_fields = fieldnames(benchmark_results);
subject_fields = subject_fields(startsWith(subject_fields, 'subs_'));

% Process each subject count
for s = 1:length(subject_fields)
    subject_count = subject_fields{s};
    
    % Get all task fields (excluding total_* fields)
    task_fields = fieldnames(benchmark_results.(subject_count));
    task_fields = task_fields(cellfun(@(f) ~startsWith(f, 'total') && ...
        isfield(benchmark_results.(subject_count).(f), 'Fast_TFCE') && ...
        isfield(benchmark_results.(subject_count).(f), 'TFCE'), task_fields));
    
    % Process first task to initialize matrices
    if ~isempty(task_fields) && isempty(all_match_percentages_pos)
        % Get dimensions from first available task
        task = task_fields{1};
        fast_tfce_data = benchmark_results.(subject_count).(task).Fast_TFCE;
        
        if isfield(fast_tfce_data, 'sig_prob')
            num_edges = size(fast_tfce_data.sig_prob, 1);
            all_match_percentages_pos = zeros(num_edges, 1);
            all_match_percentages_neg = zeros(num_edges, 1);
        end
    end
    
    % Process each task
    for t = 1:length(task_fields)
        task = task_fields{t};
        
        % Get Fast_TFCE and TFCE data
        fast_tfce_data = benchmark_results.(subject_count).(task).Fast_TFCE;
        tfce_data = benchmark_results.(subject_count).(task).TFCE;
        
        % Check if the required fields exist
        if isfield(fast_tfce_data, 'sig_prob') && isfield(tfce_data, 'sig_prob') && ...
           isfield(fast_tfce_data, 'sig_prob_neg') && isfield(tfce_data, 'sig_prob_neg')
            
            % Get significance data
            fast_tfce_sig_pos = fast_tfce_data.sig_prob > (1-alpha);
            tfce_sig_pos = tfce_data.sig_prob > (1-alpha);
            fast_tfce_sig_neg = fast_tfce_data.sig_prob_neg > (1-alpha);
            tfce_sig_neg = tfce_data.sig_prob_neg > (1-alpha);
            
            % Get the number of repetitions
            n_repetitions = size(fast_tfce_sig_pos, 2);
            
            % Calculate match percentages for each edge
            match_pct_pos = zeros(size(fast_tfce_sig_pos, 1), 1);
            match_pct_neg = zeros(size(fast_tfce_sig_neg, 1), 1);
            
            for i = 1:size(fast_tfce_sig_pos, 1)
                match_pct_pos(i) = sum(fast_tfce_sig_pos(i,:) == tfce_sig_pos(i,:)) / n_repetitions * 100;
                match_pct_neg(i) = sum(fast_tfce_sig_neg(i,:) == tfce_sig_neg(i,:)) / n_repetitions * 100;
            end
            
            % Add to the running sum (for later averaging)
            all_match_percentages_pos = all_match_percentages_pos + match_pct_pos;
            all_match_percentages_neg = all_match_percentages_neg + match_pct_neg;
            match_counts = match_counts + 1;
        end
    end
end

% Calculate the average match percentage across all tasks and subject counts
all_match_percentages_pos = all_match_percentages_pos / match_counts;
all_match_percentages_neg = all_match_percentages_neg / match_counts;

% Calculate the average match percentage across positive and negative effects
all_avg_match_percentage = (all_match_percentages_pos + all_match_percentages_neg) / 2;

% Determine the matrix dimensions from the number of edges
num_edges = size(all_match_percentages_pos, 1) / length(subject_fields);

% Correctly calculate number of nodes using the formula: edges = n(n-1)/2
% Solve quadratic equation: n² - n - 2*num_edges = 0
n = round((1 + sqrt(1 + 4*2*num_edges))/2);

% Create a single aggregated heatmap across all tasks and subjects
figure('Position', [100, 100, 800, 700]);

% Create the empty matrix with the correct dimensions
match_matrix = zeros(n, n);

% Fill only the upper triangular portion
idx = 1;
for i = 1:n
    for j = (i+1):n  % Start from i+1 to fill only upper triangle
        if idx <= num_edges
            match_matrix(i,j) = all_avg_match_percentage(idx);
            idx = idx + 1;
        end
    end
end

% Generate the heatmap - only showing upper triangular part
imagesc(triu(match_matrix, 1));

upper_tri = triu(match_matrix, 1);
% Calculate and display min and max values
upper_tri_values = upper_tri(upper_tri > 0);  % Get only the non-zero values from upper triangle
min_agreement = min(upper_tri_values);
max_agreement = max(upper_tri_values);
fprintf('Minimum agreement percentage: %.2f%%\n', min_agreement);
fprintf('Maximum agreement percentage: %.2f%%\n', max_agreement);
fprintf('Mean agreement percentage: %.2f%%\n', mean(upper_tri_values));

% Generate the heatmap
imagesc(match_matrix);
colormap(jet);
colorbar;
caxis([0 100]);
title('Percentage Agreement Between TFCE and Fast\_TFCE Methods');
xlabel('Node Index');
ylabel('Node Index');
axis square;
