vars = who;       % Get a list of all variable names in the workspace
vars(strcmp(vars, 'data_matrix')) = [];  % Remove the variable you want to keep from the list
vars(strcmp(vars, 'testing_yml_workflow')) = [];
clear(vars{:});   % Clear all other variables
clc;


directory_path = ['/Users/f.cravogomes/Desktop/Cloned Repos/Power_Calculator/power_calculator_results/' ...
    'cpp_comparison/constrained'];

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
summary.fdr_max_diff = [];
summary.fdr_mean_diff = [];
summary.fdr_binary_diff_percent = [];
summary.fwer_max_diff = [];
summary.fwer_mean_diff = [];
summary.fwer_binary_diff_percent = [];
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
    if ~isfield(data, 'Constrained_FDR') || ~isfield(data, 'Constrained_cpp_FDR') || ...
       ~isfield(data, 'Constrained_FWER') || ~isfield(data, 'Constrained_cpp_FWER')
        warning('File %s is missing required fields. Skipping.', files(i).name);
        continue;
    end
    
    % Get the dimensions for plotting
    if isfield(data.Constrained_FDR, 'sig_prob') && isfield(data.Constrained_cpp_FDR, 'sig_prob')
        [n_networks, n_subjects] = size(data.Constrained_FDR.sig_prob);
    else
        warning('Missing sig_prob field in FDR results. Skipping file %s.', files(i).name);
        continue;
    end
    
    % Compare FDR results
    fprintf('Comparing FDR results:\n');
    fdr_matlab = full(data.Constrained_FDR.sig_prob);
    fdr_cpp = full(data.Constrained_cpp_FDR.sig_prob);
    
    fdr_diff = abs(fdr_matlab - fdr_cpp);
    fdr_max_diff = max(fdr_diff(:));
    fdr_mean_diff = mean(fdr_diff(:));
    
    % Convert to binary (significant/not significant)
    % NOTE: These are significance probabilities (sig_prob = 1 - pval), 
    % so significance is when sig_prob > (1 - alpha)
    alpha_fdr = 0.05; % Using standard alpha for FDR
    sig_threshold = 1 - alpha_fdr;
    fdr_matlab_binary = fdr_matlab > sig_threshold;
    fdr_cpp_binary = fdr_cpp > sig_threshold;
    fdr_binary_diff = xor(fdr_matlab_binary, fdr_cpp_binary);
    fdr_binary_diff_percent = 100 * sum(fdr_binary_diff(:)) / numel(fdr_binary_diff);
    
    fprintf('  Max absolute difference: %.10f\n', fdr_max_diff);
    fprintf('  Mean absolute difference: %.10f\n', fdr_mean_diff);
    fprintf('  Binary difference: %.2f%% of elements differ in significance\n', fdr_binary_diff_percent);
    
    % Compare FWER results
    fprintf('Comparing FWER results:\n');
    fwer_matlab = full(data.Constrained_FWER.sig_prob);
    fwer_cpp = full(data.Constrained_cpp_FWER.sig_prob);
    
    fwer_diff = abs(fwer_matlab - fwer_cpp);
    fwer_max_diff = max(fwer_diff(:));
    fwer_mean_diff = mean(fwer_diff(:));
    
    % Convert to binary (significant/not significant)
    % NOTE: These are significance probabilities (sig_prob = 1 - pval), 
    % so significance is when sig_prob > (1 - alpha)
    alpha = 0.05; % Assuming standard alpha
    sig_threshold = 1 - alpha;
    fwer_matlab_binary = fwer_matlab > sig_threshold;
    fwer_cpp_binary = fwer_cpp > sig_threshold;
    fwer_binary_diff = xor(fwer_matlab_binary, fwer_cpp_binary);
    fwer_binary_diff_percent = 100 * sum(fwer_binary_diff(:)) / numel(fwer_binary_diff);
    
    fprintf('  Max absolute difference: %.10f\n', fwer_max_diff);
    fprintf('  Mean absolute difference: %.10f\n', fwer_mean_diff);
    fprintf('  Binary difference: %.2f%% of elements differ in significance\n', fwer_binary_diff_percent);
    
    % Check execution time if available
    cpp_speedup = NaN;
    if isfield(data.Constrained_FDR, 'total_time') && isfield(data.Constrained_cpp_FDR, 'total_time')
        matlab_time = data.Constrained_FDR.total_time;
        cpp_time = data.Constrained_cpp_FDR.total_time;
        cpp_speedup = matlab_time / cpp_time;
        fprintf('Speed comparison: MATLAB: %.4f s, C++: %.4f s (%.2fx speedup)\n', ...
                matlab_time, cpp_time, cpp_speedup);
    end
    
    % Store summary statistics
    summary.file_names{end+1} = files(i).name;
    summary.fdr_max_diff(end+1) = fdr_max_diff;
    summary.fdr_mean_diff(end+1) = fdr_mean_diff;
    summary.fdr_binary_diff_percent(end+1) = fdr_binary_diff_percent;
    summary.fwer_max_diff(end+1) = fwer_max_diff;
    summary.fwer_mean_diff(end+1) = fwer_mean_diff;
    summary.fwer_binary_diff_percent(end+1) = fwer_binary_diff_percent;
    summary.cpp_speedup(end+1) = cpp_speedup;
    
    % Create plots for this file
    figure('Name', sprintf('Comparison for %s', files(i).name), 'Position', [100, 100, 1200, 800]);
    
    % Plot FDR results
    subplot(2, 3, 1);
    imagesc(fdr_matlab);
    title('MATLAB FDR p-values');
    xlabel('Subject');
    ylabel('Network');
    colorbar;
    
    subplot(2, 3, 2);
    imagesc(fdr_cpp);
    title('C++ FDR p-values');
    xlabel('Subject');
    ylabel('Network');
    colorbar;
    
    subplot(2, 3, 3);
    imagesc(fdr_diff);
    title('FDR Absolute Difference');
    xlabel('Subject');
    ylabel('Network');
    colorbar;
    
    % Plot FWER results
    subplot(2, 3, 4);
    imagesc(fwer_matlab);
    title('MATLAB FWER p-values');
    xlabel('Subject');
    ylabel('Network');
    colorbar;
    
    subplot(2, 3, 5);
    imagesc(fwer_cpp);
    title('C++ FWER p-values');
    xlabel('Subject');
    ylabel('Network');
    colorbar;
    
    subplot(2, 3, 6);
    imagesc(fwer_diff);
    title('FWER Absolute Difference');
    xlabel('Subject');
    ylabel('Network');
    colorbar;
    
    % Save figure
    saveas(gcf, fullfile(directory_path, sprintf('comparison_%s.png', strrep(files(i).name, '.mat', ''))));
    
    % Create additional plots showing binary significance differences
    figure('Name', sprintf('Significance Differences for %s', files(i).name), 'Position', [100, 100, 1200, 400]);
    
    % Plot FDR binary difference
    subplot(1, 2, 1);
    imagesc(fdr_binary_diff);
    title('FDR Significance Differences');
    xlabel('Subject');
    ylabel('Network');
    colorbar;
    colormap(gca, [1 1 1; 1 0 0]);  % White for no difference, red for difference
    
    % Plot FWER binary difference
    subplot(1, 2, 2);
    imagesc(fwer_binary_diff);
    title('FWER Significance Differences');
    xlabel('Subject');
    ylabel('Network');
    colorbar;
    colormap(gca, [1 1 1; 1 0 0]);  % White for no difference, red for difference
    
    % Save binary difference figure
    saveas(gcf, fullfile(directory_path, sprintf('sig_diff_%s.png', strrep(files(i).name, '.mat', ''))));
end

% Generate summary report
fprintf('\n\n===== SUMMARY REPORT =====\n');
fprintf('Analyzed %d files\n', length(summary.file_names));

% FDR summary
fprintf('\nFDR Results:\n');
fprintf('  Average max difference: %.10f\n', mean(summary.fdr_max_diff));
fprintf('  Average mean difference: %.10f\n', mean(summary.fdr_mean_diff));
fprintf('  Average binary difference: %.2f%%\n', mean(summary.fdr_binary_diff_percent));

% FWER summary
fprintf('\nFWER Results:\n');
fprintf('  Average max difference: %.10f\n', mean(summary.fwer_max_diff));
fprintf('  Average mean difference: %.10f\n', mean(summary.fwer_mean_diff));
fprintf('  Average binary difference: %.2f%%\n', mean(summary.fwer_binary_diff_percent));

% Speed summary
valid_speedups = summary.cpp_speedup(~isnan(summary.cpp_speedup));
if ~isempty(valid_speedups)
    fprintf('\nSpeed Comparison:\n');
    fprintf('  Average speedup: %.2fx\n', mean(valid_speedups));
    fprintf('  Maximum speedup: %.2fx\n', max(valid_speedups));
    fprintf('  Minimum speedup: %.2fx\n', min(valid_speedups));
end

% Create summary plot
figure('Name', 'Summary of Differences', 'Position', [100, 100, 800, 600]);

subplot(2, 2, 1);
bar(summary.fdr_max_diff);
title('FDR Max Differences');
xlabel('File Index');
ylabel('Max Absolute Difference');

subplot(2, 2, 2);
bar(summary.fdr_binary_diff_percent);
title('FDR Binary Differences (%)');
xlabel('File Index');
ylabel('Percent Different');

subplot(2, 2, 3);
bar(summary.fwer_max_diff);
title('FWER Max Differences');
xlabel('File Index');
ylabel('Max Absolute Difference');

subplot(2, 2, 4);
bar(summary.fwer_binary_diff_percent);
title('FWER Binary Differences (%)');
xlabel('File Index');
ylabel('Percent Different');

% Create a table with detailed results for each file
results_table = table(summary.file_names', summary.fdr_max_diff', summary.fdr_mean_diff', ...
                     summary.fdr_binary_diff_percent', summary.fwer_max_diff', summary.fwer_mean_diff', ...
                     summary.fwer_binary_diff_percent', summary.cpp_speedup', ...
                     'VariableNames', {'FileName', 'FDR_MaxDiff', 'FDR_MeanDiff', 'FDR_BinaryDiffPercent', ...
                                       'FWER_MaxDiff', 'FWER_MeanDiff', 'FWER_BinaryDiffPercent', 'Speedup'});

% Display the table
disp(results_table);

% Save summary results
save(fullfile(directory_path, 'constrained_comparison_summary.mat'), 'summary', 'results_table');