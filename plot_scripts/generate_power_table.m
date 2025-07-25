function power_table = generate_power_table(directory, varargin)
% GENERATE_POWER_TABLE Creates a table with power values and curve parameters
% for each individual study (no averaging across studies)
%
% Inputs:
%   directory - path to power calculation results
%   'undesired_subject_numbers' - cell array of subject numbers to exclude
%   'excluded_methods' - cell array of method names to exclude from table
%
% Outputs:
%   power_table - MATLAB table with power values and curve parameters
%
% Shortcut usage paste:
%   abcd_fc - 

%% Check if input is a directory
if ~isfolder(directory)
    error('Input must be a directory name')
end

%% Parse varargin
p = inputParser;
addParameter(p, 'undesired_subject_numbers', {}, @iscell);
addParameter(p, 'excluded_methods', {'Size', 'Constrained_FDR', 'Constrained_FWER', 'TFCE'}, @iscell);
parse(p, varargin{:});

excluded_methods = p.Results.excluded_methods;

%% Get power data (without averaging across studies)
multi_variable_data = multi_experiment_average(directory); 
data_agregator = struct();

sub_numbers = {};
test_names = {};

% First loop: prepare empty structs for all subjects
% Extract number of subjects and test names
% Be mindful test_numbers and sub_numbers do not appears in the numerical
% order
for ri = 1:numel(multi_variable_data)
    res = multi_variable_data{ri};
    
    test = res.meta_data.rep_parameters.test_name;

    n_subs = res.meta_data.subject_number;
    n_subs = ['subs_' num2str(n_subs)];
    
    if ~ismember(test, test_names)
        test_names{end + 1} = test; %#ok
    end
    
    if ~ismember(n_subs, sub_numbers)
        sub_numbers{end + 1} = n_subs; %#ok
    end
   
    % Check and create test field if it doesn't exist
    if ~isfield(data_agregator, test)
        data_agregator.(test) = struct();
    end

    if ~isfield(data_agregator, n_subs)
        data_agregator.(test).(n_subs) = struct();
    end
end


% Collect individual study data (no averaging)
for ri = 1:numel(multi_variable_data)
    res = multi_variable_data{ri};

    n_subs = res.meta_data.subject_number;
    n_subs = ['subs_' num2str(n_subs)];

    test = res.meta_data.rep_parameters.test_name;
    
    for mi = 1:numel(res.meta_data.method_list)
        method = res.meta_data.method_list{mi};
        
        % Skip excluded methods
        if ismember(method, excluded_methods)
            continue;
        end
        
        data_agregator.(test).(n_subs).(method) = res.mean.(method);
    end

end

sub_numbers_numeric = str2double(extractAfter(sub_numbers, 'subs_'));
[sorted_nums, sort_idx] = sort(sub_numbers_numeric);
sorted_sub_numbers = sub_numbers(sort_idx);

% Get all unique methods (excluding those filtered out)
first_subject = sub_numbers{1};
first_test = test_names{1};
methods = fieldnames(data_agregator.(first_test).(first_subject));

%% Process each method and study combination
sorted_tests = natural_sort(test_names);

n_table_elements = numel(sorted_tests) * numel(methods);

% Initialize table data arrays
table_test = cell(n_table_elements, 1);
table_method = cell(n_table_elements, 1);
table_subs_power = cell(n_table_elements, numel(sorted_sub_numbers));
table_parameters = cell(n_table_elements, 2);
table_r_squared = cell(n_table_elements, 1);

% Counter for table rows
row_idx = 0;

for ti = 1:numel(sorted_tests)
    test = sorted_tests{ti};
        
    for mi = 1:numel(methods)
        method = methods{mi};
        row_idx = row_idx + 1;
        
        % Use cellfun to extract power values for this method across all subject numbers
        power_values = cellfun(@(sub_num) data_agregator.(test).(sub_num).(method), ...
                                sorted_sub_numbers, 'UniformOutput', false); 
        x = sorted_nums;
        y = cell2mat(power_values);

        [~, ~, r_sqr, fit_p] = fit_power_curve(x, y);

        % Populate table data
        table_test{row_idx} = test;
        table_method{row_idx} = method;
        table_r_squared{row_idx} = r_sqr;
        table_parameters{row_idx, 1} = fit_p(1);  % Scale parameter
        table_parameters{row_idx, 2} = fit_p(2);  % Shape parameter
        
        % Store power values for each subject number (in natural order)
        for si = 1:numel(sorted_sub_numbers)
            table_subs_power{row_idx, si} = y(si);
        end
    end
end
 
table_method = plot_method_name_map(table_method);
table_method = table_method';

% Aggregate all data into one matrix
power_table = [table_test, table_method, table_subs_power, table_parameters, table_r_squared];

end