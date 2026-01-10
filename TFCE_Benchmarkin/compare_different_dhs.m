%% TFCE Speed Comparison - LaTeX Table Generator
% Generates LaTeX tables for IC-TFCE vs TFCE speed comparison

clear; clc;

% Directory with result files
results_dir = '/Users/f.cravogomes/Desktop/Cloned Repos/PRISME-Brain-Power-Calculator/power_calculator_results/re_tfce_speed_comp';

% Method names
ic_tfce_methods = {'IC_TFCE_FC_cpp_dh1', 'IC_TFCE_FC_cpp_dh5', 'IC_TFCE_FC_cpp_dh10', 'IC_TFCE_FC_cpp_dh25'};
tfce_methods = {'TFCE_cpp_dh1', 'TFCE_cpp_dh5', 'TFCE_cpp_dh10', 'TFCE_cpp_dh25'};
exact_method = 'Exact_FC_TFCE_cpp';
dh_values = [1, 5, 10, 25];
n_subs_list = [20, 80, 200];

% Load all result files
result_files = dir(fullfile(results_dir, '**/*.mat'));
fprintf('Found %d result files\n', length(result_files));

% Initialize storage
ic_tfce_times = struct();
tfce_times = struct();
exact_tfce_times = struct();

for ns = n_subs_list
    key = sprintf('n%d', ns);
    ic_tfce_times.(key) = cell(1, length(dh_values));
    tfce_times.(key) = cell(1, length(dh_values));
    exact_tfce_times.(key) = [];
    for i = 1:length(dh_values)
        ic_tfce_times.(key){i} = [];
        tfce_times.(key){i} = [];
    end
end

% Process each file
for f = 1:length(result_files)
    filepath = fullfile(result_files(f).folder, result_files(f).name);
    data = load(filepath);
    
    if ~isfield(data, 'meta_data') || ~isfield(data.meta_data, 'n_subs')
        continue;
    end
    
    n_subs = data.meta_data.n_subs;
    key = sprintf('n%d', n_subs);
    
    if ~ismember(n_subs, n_subs_list)
        continue;
    end
    
    % Extract times for each dh value
    for i = 1:length(dh_values)
        if isfield(data, ic_tfce_methods{i}) && isfield(data.(ic_tfce_methods{i}), 'total_time')
            ic_tfce_times.(key){i}(end+1) = data.(ic_tfce_methods{i}).total_time;
        end
        if isfield(data, tfce_methods{i}) && isfield(data.(tfce_methods{i}), 'total_time')
            tfce_times.(key){i}(end+1) = data.(tfce_methods{i}).total_time;
        end
    end
    
    % Extract Exact TFCE time
    if isfield(data, exact_method) && isfield(data.(exact_method), 'total_time')
        exact_tfce_times.(key)(end+1) = data.(exact_method).total_time;
    end
end

% Generate LaTeX output
fprintf('\n\n%% ========== COPY BELOW ==========\n\n');

fprintf('\\begin{table}[h!]\n');
fprintf('\\centering\n');
fprintf('\\caption{Runtime comparison of TFCE implementations across varying sample sizes.}\n');
fprintf('\\label{tab:tfce_comparison}\n\n');

labels = {'(a)', '(b)', '(c)'};

for ns_idx = 1:length(n_subs_list)
    ns = n_subs_list(ns_idx);
    key = sprintf('n%d', ns);
    
    fprintf('\\vspace{0.5em}\n');
    fprintf('\\textbf{%s N = %d}\n\n', labels{ns_idx}, ns);
    fprintf('\\begin{tabular}{cccc}\n');
    fprintf('\\hline\n');
    fprintf('dh & IC\\_TFCE (s) & TFCE (s) & Speedup \\\\\n');
    fprintf('\\hline\n');
    
    for i = 1:length(dh_values)
        ic_mean = mean(ic_tfce_times.(key){i});
        tfce_mean = mean(tfce_times.(key){i});
        speedup = tfce_mean / ic_mean;
        fprintf('%d & %.4f & %.4f & %.2fx \\\\\n', dh_values(i), ic_mean, tfce_mean, speedup);
    end
    
    fprintf('\\hline\n');
    fprintf('\\end{tabular}\n\n');
end

% Exact TFCE table - by subject size
fprintf('\\vspace{0.5em}\n');
fprintf('\\textbf{(d) Exact TFCE}\n\n');
fprintf('\\begin{tabular}{cccc}\n');
fprintf('\\hline\n');
fprintf('N & Exact TFCE (s) & \\begin{tabular}[c]{@{}c@{}}Speedup\\\\IC-TFCE\\end{tabular} & \\begin{tabular}[c]{@{}c@{}}Speedup\\\\TFCE\\end{tabular} \\\\\n');
fprintf('\\hline\n');

for ns_idx = 1:length(n_subs_list)
    ns = n_subs_list(ns_idx);
    key = sprintf('n%d', ns);
    
    exact_mean = mean(exact_tfce_times.(key));
    % Compare to dh=1 (finest discretization)
    ic_mean_dh1 = mean(ic_tfce_times.(key){1});
    tfce_mean_dh1 = mean(tfce_times.(key){1});
    
    speedup_ic = exact_mean / ic_mean_dh1;
    speedup_tfce = exact_mean / tfce_mean_dh1;
    
    fprintf('%d & %.4f & %.2fx & %.2fx \\\\\n', ns, exact_mean, speedup_ic, speedup_tfce);
end

fprintf('\\hline\n');
fprintf('\\end{tabular}\n\n');
fprintf('\\end{table}\n');

fprintf('\n%% ========== END COPY ==========\n');