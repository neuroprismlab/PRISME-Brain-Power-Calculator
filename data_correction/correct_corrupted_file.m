% Script to fix corrupted meta_data in NBS results file

% Input and output file paths
input_file = '/Users/f.cravogomes/Downloads/abcd_fc-test1-t2-subs_20.mat';
output_dir = '/Users/f.cravogomes/Desktop/Cloned Repos/Power_Calculator/power_calculator_results/abcd_fc';

% Load the corrupted file
fprintf('Loading corrupted file...\n');
data = load(input_file);

% Get all field names (methods) from the file
all_fields = fieldnames(data);

% Remove non-method fields
non_method_fields = {'edge_level_stats', 'network_level_stats', 'meta_data'};
method_fields = setdiff(all_fields, non_method_fields);

% Extract methods that don't contain 'cpp'
regular_methods = {};
for i = 1:length(method_fields)
    if isempty(strfind(method_fields{i}, '_cpp'))
        regular_methods{end+1} = method_fields{i};
    end
end

fprintf('Found %d regular methods (without "_cpp")\n', length(regular_methods));

% Update meta_data
if isfield(data, 'meta_data')
    fprintf('Updating meta_data...\n');
    
    % Initialize method_list if needed
    if ~isfield(data.meta_data, 'method_list') || isempty(data.meta_data.method_list)
        data.meta_data.method_list = {};
    end
    
    % Update method_list with all methods
    for i = 1:length(method_fields)
        if ~ismember(method_fields{i}, data.meta_data.method_list)
            data.meta_data.method_list{end+1} = method_fields{i};
        end
    end
    
    % Initialize method_current_rep if needed
    if ~isfield(data.meta_data, 'method_current_rep') || ~isstruct(data.meta_data.method_current_rep)
        data.meta_data.method_current_rep = struct();
    end
    
    % Add all methods to method_current_rep with 500 repetitions
    for i = 1:length(method_fields)
        if ~isfield(data.meta_data.method_current_rep, method_fields{i})
            data.meta_data.method_current_rep.(method_fields{i}) = 500;
        end
    end
else
    fprintf('Error: meta_data field not found in the file\n');
    return;
end

% Create output directory if it doesn't exist
[~, filename, ext] = fileparts(input_file);
output_file = fullfile(output_dir, [filename, ext]);

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('Created output directory: %s\n', output_dir);
end

% Save the corrected file
fprintf('Saving corrected file to: %s\n', output_file);
save(output_file, '-struct', 'data', '-v7.3');

fprintf('Done!\n');