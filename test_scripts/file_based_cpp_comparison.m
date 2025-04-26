function compare_cpp_methods_alpha05(data_path)
%% compare_cpp_methods_alpha05
% Compares CPP-based methods with their non-CPP versions using alpha = 0.05
%
% This function loads a MATLAB data file and computes summary statistics comparing
% CPP-based statistical methods with their non-CPP counterparts, focusing specifically
% on significance with alpha = 0.05.
%
% The function properly handles data with multiple repetitions (e.g., 500 repetitions)
% and computes average statistics across these repetitions.
%
% Inputs:
% - data_path: Path to the MATLAB data file (e.g., '/path/to/abcd_fc-test1-t2-subs_40.mat')
%
% Outputs:
% - Prints summary statistics to the console
% - Returns a table with detailed comparison metrics

if nargin < 1
    data_path = '/Users/f.cravogomes/Downloads/abcd_fc-test1-t2-subs_40.mat';
    disp(['Using default data path: ' data_path]);
end

% Load the data
disp(['Loading data file: ' data_path]);
data = load(data_path);

% Define the method pairs to compare (CPP vs non-CPP)
method_pairs = {
    {'Constrained_cpp_FDR', 'Constrained_FDR'},
    {'Constrained_cpp_FWER', 'Constrained_FWER'},
    {'Fast_TFCE_cpp', 'Fast_TFCE'},
    {'Size_cpp', 'Size'}
};

% Set alpha threshold
alpha = 0.05;
threshold = 1 - alpha;

% Create summary table
summary_table = cell(length(method_pairs), 14);
headers = {'Method Pair', ...
           'Mean Diff (sig_prob)', 'Max Diff (sig_prob)', 'Mean Corr (sig_prob)', ...
           'CPP Sig Edges', 'Non-CPP Sig Edges', 'Both Sig', 'Only CPP Sig', 'Only Non-CPP Sig', ...
           'Agreement %', ...
           'Mean Diff (sig_prob_neg)', 'Max Diff (sig_prob_neg)', 'Mean Corr (sig_prob_neg)', ...
           'Agreement % (neg)'};

fprintf('\n===== Comparison of CPP vs Non-CPP Methods (α=%.2f) =====\n\n', alpha);

for i = 1:length(method_pairs)
    cpp_method = method_pairs{i}{1};
    non_cpp_method = method_pairs{i}{2};
    
    fprintf('Comparing %s vs %s\n', cpp_method, non_cpp_method);
    
    % Check if both methods exist in the data
    if ~isfield(data, cpp_method) || ~isfield(data, non_cpp_method)
        fprintf('  Warning: Could not find one or both methods in the data\n\n');
        continue;
    end
    
    % === Process sig_prob ===
    if isfield(data.(cpp_method), 'sig_prob') && isfield(data.(non_cpp_method), 'sig_prob')
        cpp_sig_prob = full(data.(cpp_method).sig_prob);
        non_cpp_sig_prob = full(data.(non_cpp_method).sig_prob);
        
        % Get dimensions and verify
        [num_rows, num_reps] = size(cpp_sig_prob);
        fprintf('  Found data with dimensions: %d rows x %d repetitions\n', num_rows, num_reps);
        
        % Calculate differences for each repetition
        diff_sig_prob = cpp_sig_prob - non_cpp_sig_prob;
        abs_diff_sig_prob = abs(diff_sig_prob);
        
        % Summary statistics (averaged across repetitions)
        mean_diff = mean(mean(abs_diff_sig_prob, 2));  % Mean across all values
        max_diff = max(max(abs_diff_sig_prob));        % Max across all values
        
        % Calculate correlation per row (across repetitions)
        corr_vals = zeros(num_rows, 1);
        for row = 1:num_rows
            corr_vals(row) = corr(cpp_sig_prob(row,:)', non_cpp_sig_prob(row,:)');
        end
        corr_val = mean(corr_vals);  % Average correlation
        
        % Determine significant edges (for each repetition)
        cpp_sig = cpp_sig_prob > threshold;
        non_cpp_sig = non_cpp_sig_prob > threshold;
        
        % Calculate agreement metrics (averaged across repetitions)
        both_sig = cpp_sig & non_cpp_sig;
        only_cpp_sig = cpp_sig & ~non_cpp_sig;
        only_non_cpp_sig = ~cpp_sig & non_cpp_sig;
        
        % Count for each repetition, then average
        n_cpp_sig = mean(sum(cpp_sig, 1));
        n_non_cpp_sig = mean(sum(non_cpp_sig, 1));
        n_both_sig = mean(sum(both_sig, 1));
        n_only_cpp_sig = mean(sum(only_cpp_sig, 1));
        n_only_non_cpp_sig = mean(sum(only_non_cpp_sig, 1));
        
        % Calculate agreement percentage per repetition, then average
        agreement_per_rep = zeros(1, num_reps);
        for rep = 1:num_reps
            agreement_per_rep(rep) = 100 * mean(cpp_sig(:,rep) == non_cpp_sig(:,rep));
        end
        agreement_pct = mean(agreement_per_rep);
        
        % Display results
        fprintf('  sig_prob statistics (α=%.2f):\n', alpha);
        fprintf('    Mean absolute difference: %.6f\n', mean_diff);
        fprintf('    Max absolute difference: %.6f\n', max_diff);
        fprintf('    Mean correlation across rows: %.6f\n', corr_val);
        fprintf('    CPP significant edges (mean): %.2f\n', n_cpp_sig);
        fprintf('    Non-CPP significant edges (mean): %.2f\n', n_non_cpp_sig);
        fprintf('    Edges significant in both (mean): %.2f\n', n_both_sig);
        fprintf('    Edges significant only in CPP (mean): %.2f\n', n_only_cpp_sig);
        fprintf('    Edges significant only in non-CPP (mean): %.2f\n', n_only_non_cpp_sig);
        fprintf('    Agreement percentage (mean): %.2f%%\n', agreement_pct);
        
        % Store in summary table
        summary_table{i, 1} = [cpp_method ' vs ' non_cpp_method];
        summary_table{i, 2} = mean_diff;
        summary_table{i, 3} = max_diff;
        summary_table{i, 4} = corr_val;
        summary_table{i, 5} = n_cpp_sig;
        summary_table{i, 6} = n_non_cpp_sig;
        summary_table{i, 7} = n_both_sig;
        summary_table{i, 8} = n_only_cpp_sig;
        summary_table{i, 9} = n_only_non_cpp_sig;
        summary_table{i, 10} = agreement_pct;
    else
        fprintf('  Warning: sig_prob not found for one or both methods\n');
        % Fill with NaN
        summary_table{i, 1} = [cpp_method ' vs ' non_cpp_method];
        summary_table{i, 2} = NaN;
        summary_table{i, 3} = NaN;
        summary_table{i, 4} = NaN;
        summary_table{i, 5} = NaN;
        summary_table{i, 6} = NaN;
        summary_table{i, 7} = NaN;
        summary_table{i, 8} = NaN;
        summary_table{i, 9} = NaN;
        summary_table{i, 10} = NaN;
    end
    
    % === Process sig_prob_neg ===
    if isfield(data.(cpp_method), 'sig_prob_neg') && isfield(data.(non_cpp_method), 'sig_prob_neg')
        cpp_sig_prob_neg = full(data.(cpp_method).sig_prob_neg);
        non_cpp_sig_prob_neg = full(data.(non_cpp_method).sig_prob_neg);
        
        % Get dimensions
        [num_rows_neg, num_reps_neg] = size(cpp_sig_prob_neg);
        
        % Calculate differences for each repetition
        diff_sig_prob_neg = cpp_sig_prob_neg - non_cpp_sig_prob_neg;
        abs_diff_sig_prob_neg = abs(diff_sig_prob_neg);
        
        % Summary statistics (averaged across repetitions)
        mean_diff_neg = mean(mean(abs_diff_sig_prob_neg, 2));
        max_diff_neg = max(max(abs_diff_sig_prob_neg));
        
        % Calculate correlation per row (across repetitions)
        corr_vals_neg = zeros(num_rows_neg, 1);
        for row = 1:num_rows_neg
            corr_vals_neg(row) = corr(cpp_sig_prob_neg(row,:)', non_cpp_sig_prob_neg(row,:)');
        end
        corr_val_neg = mean(corr_vals_neg);
        
        % Determine significant edges (for each repetition)
        cpp_sig_neg = cpp_sig_prob_neg > threshold;
        non_cpp_sig_neg = non_cpp_sig_prob_neg > threshold;
        
        % Calculate agreement percentage per repetition, then average
        agreement_per_rep_neg = zeros(1, num_reps_neg);
        for rep = 1:num_reps_neg
            agreement_per_rep_neg(rep) = 100 * mean(cpp_sig_neg(:,rep) == non_cpp_sig_neg(:,rep));
        end
        agreement_pct_neg = mean(agreement_per_rep_neg);
        
        % Display results
        fprintf('  sig_prob_neg statistics (α=%.2f):\n', alpha);
        fprintf('    Mean absolute difference: %.6f\n', mean_diff_neg);
        fprintf('    Max absolute difference: %.6f\n', max_diff_neg);
        fprintf('    Mean correlation across rows: %.6f\n', corr_val_neg);
        fprintf('    Agreement percentage (mean): %.2f%%\n\n', agreement_pct_neg);
        
        % Store in summary table
        summary_table{i, 11} = mean_diff_neg;
        summary_table{i, 12} = max_diff_neg;
        summary_table{i, 13} = corr_val_neg;
        summary_table{i, 14} = agreement_pct_neg;
    else
        fprintf('  Warning: sig_prob_neg not found for one or both methods\n\n');
        % Fill with NaN
        summary_table{i, 11} = NaN;
        summary_table{i, 12} = NaN;
        summary_table{i, 13} = NaN;
        summary_table{i, 14} = NaN;
    end
end

% Display summary table
fprintf('\n===== Summary Table (α=%.2f) =====\n\n', alpha);
disp('Method Pair | Mean Diff | Max Diff | Corr | CPP Sig | Non-CPP Sig | Both Sig | Only CPP | Only Non-CPP | Agreement %');
disp('------------|-----------|----------|------|---------|-------------|----------|----------|--------------|------------');

for i = 1:size(summary_table, 1)
    if ~isempty(summary_table{i, 1})
        fprintf('%s | %.6f | %.6f | %.4f | %.1f | %.1f | %.1f | %.1f | %.1f | %.2f%%\n', ...
                summary_table{i, 1}, summary_table{i, 2}, summary_table{i, 3}, summary_table{i, 4}, ...
                summary_table{i, 5}, summary_table{i, 6}, summary_table{i, 7}, summary_table{i, 8}, ...
                summary_table{i, 9}, summary_table{i, 10});
    end
end

fprintf('\n===== sig_prob_neg Summary (α=%.2f) =====\n\n', alpha);
disp('Method Pair | Mean Diff | Max Diff | Mean Corr | Agreement %');
disp('------------|-----------|----------|----------|------------');

for i = 1:size(summary_table, 1)
    if ~isempty(summary_table{i, 1})
        fprintf('%s | %.6f | %.6f | %.4f | %.2f%%\n', ...
                summary_table{i, 1}, summary_table{i, 11}, summary_table{i, 12}, ...
                summary_table{i, 13}, summary_table{i, 14});
    end
end

% Return a formatted table
result_table = cell2table(summary_table, 'VariableNames', headers);

% Display completion message
fprintf('\nComparison complete!\n');

if nargout > 0
    varargout{1} = result_table;
end
end