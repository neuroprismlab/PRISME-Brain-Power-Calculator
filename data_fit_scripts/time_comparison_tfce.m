% TFCE Speed Comparison Analysis Script
clear; clc;

% Set directory path
dir_path = ['/Users/f.cravogomes/Desktop/Cloned Repos/Power_Calculator/' ...
    'power_calculator_results/tfce_cpp_speed_cmp'];

% Get all .mat files
mat_files = dir(fullfile(dir_path, '*.mat'));

% Initialize storage - columns: n_subs, dh, ic_time, tfce_time
results = [];
dh_values = [1, 5, 10, 25];

% Process each file
fprintf('Processing %d files...\n', length(mat_files));

row = 0;
for f = 1:length(mat_files)
    data = load(fullfile(dir_path, mat_files(f).name));
    
    if ~isfield(data, 'meta_data') || ~isfield(data.meta_data, 'n_subs')
        continue;
    end
    
    n_subs = data.meta_data.n_subs;
    
    for dh = dh_values
        ic_field = sprintf('IC_TFCE_FC_cpp_dh%d', dh);
        tfce_field = sprintf('TFCE_cpp_dh%d', dh);
        
        if isfield(data, ic_field) && isfield(data, tfce_field) && ...
           isfield(data.(ic_field), 'total_time') && ...
           isfield(data.(tfce_field), 'total_time')
            
            row = row + 1;
            results(row, :) = [n_subs, dh, data.(ic_field).total_time, data.(tfce_field).total_time];
        end
    end
end

exact_tfce_results = [];
% I am here
for f = 1:length(mat_files)
    data = load(fullfile(dir_path, mat_files(f).name));
    
    if ~isfield(data, 'meta_data') || ~isfield(data.meta_data, 'n_subs')
        continue;
    end
    
    n_subs = data.meta_data.n_subs;
    
    row = row + 1;
    exact_tfce_results(row, :) = [n_subs, data.Exact_FC_TFCE_cpp.total_time];
       
end

% Generate LaTeX tables
unique_n_subs = unique(results(:,1));

dh_results = struct();

for ns = unique_n_subs'
    ns_data = results(results(:,1) == ns, :);
    
    fprintf('\\begin{table}[h!]\n');
    fprintf('\\centering\n');
    fprintf('\\caption{TFCE Speed Comparison for n\\_subs = %d}\n', ns);
    fprintf('\\begin{tabular}{|c|c|c|c|c|}\n');
    fprintf('\\hline\n');
    fprintf('dh & IC\\_TFCE (s) & TFCE (s) & Speedup & n\\_files \\\\\n');
    fprintf('\\hline\n');
    
    for dh = dh_values
        dh_data = ns_data(ns_data(:,2) == dh, 3:4);
        
        if ~isempty(dh_data)
            mean_ic = mean(dh_data(:,1));
            mean_tfce = mean(dh_data(:,2));
            speedup = mean_tfce / mean_ic;
            
            fprintf('%d & %.4f & %.4f & %.2fx & %d \\\\\n', ...
                dh, mean_ic, mean_tfce, speedup, size(dh_data, 1));
        end

        if dh == 1
            ns_string = ['n_', num2str(ns)];
            dh_results.(ns_string).ic_tfce = mean_ic;
            dh_results.(ns_string).tfce = mean_tfce;
        end
    end
    

    fprintf('\\hline\n');
    fprintf('\\end{tabular}\n');
    fprintf('\\end{table}\n\n');
end


fprintf('\\begin{table}[h!]\n');
fprintf('\\centering\n');
fprintf('\\caption{Exact TFCE Results\n', ns);
fprintf('\\begin{tabular}{|c|c|c|c|c|}\n');
fprintf('\\hline\n');
fprintf('dh & IC\\_TFCE (s) & TFCE (s) & Speedup & n\\_files \\\\\n');
fprintf('\\hline\n');

for ns = unique_n_subs'
    exact_data = exact_tfce_results(exact_tfce_results(:,1) == ns, :);
    mean_exact = mean(exact_data(:,2));

    ns_string = ['n_', num2str(ns)];
    speed_ic = dh_results.(ns_string).ic_tfce/mean_exact;
    speed_tfce = dh_results.(ns_string).tfce/mean_exact;

    fprintf('%d & %.4f & %.3fx & %.3fx & %d \\\\\n', ...
        dh, mean_exact, speed_ic, speed_tfce, size(dh_data, 1));
end

fprintf('\\hline\n');
fprintf('\\end{tabular}\n');
fprintf('\\end{table}\n\n');
