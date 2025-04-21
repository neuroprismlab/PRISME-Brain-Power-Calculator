vars = who;       % Get a list of all variable names in the workspace
vars(strcmp(vars, 'data_matrix')) = [];  % Remove the variable you want to keep from the list
vars(strcmp(vars, 'testing_yml_workflow')) = [];
clear(vars{:});   % Clear all other variables
clc;


directory_path = ['/Users/f.cravogomes/Desktop/Cloned Repos/Power_Calculator/power_calculator_results/' ...
    'cpp_comparison/size'];

% Check if the directory exists
if ~exist(directory_path, 'dir')
    error('Directory does not exist: %s', directory_path);
end

% Get all .mat files in the directory
files = dir(fullfile(directory_path, '*.mat'));

if isempty(files)
    error('No .mat files found in the directory: %s', directory_path);
end

fprintf('Found %d .mat files to analyze\n', length(files));

% Initialize summary statistics
summary = struct();
summary.file_names = {};
summary.size_max_diff = [];
summary.size_mean_diff = [];
summary.size_binary_diff_percent = [];
summary.cpp_speedup = [];

% Process each file
for i = 1:length(files)
    file_path = fullfile(directory_path, files(i).name);
    fprintf('\nAnalyzing file %d/%d: %s\n', i, length(files), files(i).name);
    
    % Load the file
    data = load(file_path);
    
    % Extract the field names from the struct
    field_names = fieldnames(data);
    
    % Check if the required fields exist
    if ~isfield(data, 'Size') || ~isfield(data, 'Size_cpp')
        warning('File %s is missing required fields. Skipping.', files(i).name);
        continue;
    end
    
    % Get the dimensions for plotting
    if isfield(data.Size, 'sig_prob') && isfield(data.Size_cpp, 'sig_prob')
        [n_rows, n_cols] = size(data.Size.sig_prob);
    else
        warning('Missing sig_prob field in Size results. Skipping file %s.', files(i).name);
        continue;
    end
    
    % Compare Size results
    fprintf('Comparing Size results:\n');
    size_matlab = full(data.Size.sig_prob);
    size_cpp = full(data.Size_cpp.sig_prob);
    
    size_diff = abs(size_matlab - size_cpp);
    size_max_diff = max(size_diff(:));
    size_mean_diff = mean(size_diff(:));
    
    % Convert to binary (significant/not significant)
    % NOTE: These are significance probabilities (sig_prob = 1 - pval), 
    % so significance is when sig_prob > (1 - alpha)
    alpha = 0.05; % Assuming standard alpha
    sig_threshold = 1 - alpha;
    size_matlab_binary = size_matlab > sig_threshold;
    size_cpp_binary = size_cpp > sig_threshold;
    size_binary_diff = xor(size_matlab_binary, size_cpp_binary);
    size_binary_diff_percent = 100 * sum(size_binary_diff(:)) / numel(size_binary_diff);
    
    fprintf('  Max absolute difference: %.10f\n', size_max_diff);
    fprintf('  Mean absolute difference: %.10f\n', size_mean_diff);
    fprintf('  Binary difference: %.2f%% of elements differ in significance\n', size_binary_diff_percent);
    
    % Check execution time if available
    cpp_speedup = NaN;
    if isfield(data.Size, 'total_time') && isfield(data.Size_cpp, 'total_time')
        matlab_time = data.Size.total_time;
        cpp_time = data.Size_cpp.total_time;
        cpp_speedup = matlab_time / cpp_time;
        fprintf('Speed comparison: MATLAB: %.4f s, C++: %.4f s (%.2fx speedup)\n', ...
                matlab_time, cpp_time, cpp_speedup);
    end
    
    % Store summary statistics
    summary.file_names{end+1} = files(i).name;
    summary.size_max_diff(end+1) = size_max_diff;
    summary.size_mean_diff(end+1) = size_mean_diff;
    summary.size_binary_diff_percent(end+1) = size_binary_diff_percent;
    summary.cpp_speedup(end+1) = cpp_speedup;
    
    % Create plots for this file
    figure('Name', sprintf('Comparison for %s', files(i).name), 'Position', [100, 100, 900, 300]);
    
    % Plot Size results
    subplot(1, 3, 1);
    imagesc(size_matlab);
    title('MATLAB Size Significance');
    xlabel('Column');
    ylabel('Row');
    colorbar;
    
    subplot(1, 3, 2);
    imagesc(size_cpp);
    title('C++ Size Significance');
    xlabel('Column');
    ylabel('Row');
    colorbar;
    
    subplot(1, 3, 3);
    imagesc(size_diff);
    title('Size Absolute Difference');
    xlabel('Column');
    ylabel('Row');
    colorbar;
    
    % Save figure
    saveas(gcf, fullfile(directory_path, sprintf('comparison_%s.png', strrep(files(i).name, '.mat', ''))));
    
    % Create additional plot showing binary significance differences
    figure('Name', sprintf('Significance Differences for %s', files(i).name), 'Position', [100, 100, 600, 300]);
    
    % Plot binary significance differences
    imagesc(size_binary_diff);
    title(sprintf('Significance Differences (%.2f%% differ)', size_binary_diff_percent));
    xlabel('Column');
    ylabel('Row');
    colorbar;
    colormap(gca, [1 1 1; 1 0 0]);  % White for no difference, red for difference
    
    % Save binary difference figure
    saveas(gcf, fullfile(directory_path, sprintf('sig_diff_%s.png', strrep(files(i).name, '.mat', ''))));
end

% Generate summary report
fprintf('\n\n===== SUMMARY REPORT =====\n');
fprintf('Analyzed %d files\n', length(summary.file_names));

% Size summary
fprintf('\nSize Method Results:\n');
fprintf('  Average max difference: %.10f\n', mean(summary.size_max_diff));
fprintf('  Average mean difference: %.10f\n', mean(summary.size_mean_diff));
fprintf('  Average binary difference: %.2f%%\n', mean(summary.size_binary_diff_percent));

% Speed summary
valid_speedups = summary.cpp_speedup(~isnan(summary.cpp_speedup));
if ~isempty(valid_speedups)
    fprintf('\nSpeed Comparison:\n');
    fprintf('  Average speedup: %.2fx\n', mean(valid_speedups));
    fprintf('  Maximum speedup: %.2fx\n', max(valid_speedups));
    fprintf('  Minimum speedup: %.2fx\n', min(valid_speedups));
end

% Create summary plot
figure('Name', 'Summary of Differences', 'Position', [100, 100, 800, 400]);

subplot(1, 2, 1);
bar(summary.size_max_diff);
title('Size Max Differences');
xlabel('File Index');
ylabel('Max Absolute Difference');

subplot(1, 2, 2);
bar(summary.size_binary_diff_percent);
title('Size Binary Differences (%)');
xlabel('File Index');
ylabel('Percent Different');

% Create a table with detailed results for each file
results_table = table(summary.file_names', summary.size_max_diff', summary.size_mean_diff', ...
                     summary.size_binary_diff_percent', summary.cpp_speedup', ...
                     'VariableNames', {'FileName', 'MaxDiff', 'MeanDiff', 'BinaryDiffPercent', 'Speedup'});

% Display the table
disp(results_table);

% Save summary results
save(fullfile(directory_path, 'size_comparison_summary.mat'), 'summary', 'results_table');