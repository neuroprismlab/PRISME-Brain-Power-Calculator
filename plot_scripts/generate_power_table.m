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

%% Check if input is a directory
if ~isfolder(directory)
    error('Input must be a directory name')
end

%% Parse varargin
p = inputParser;
addParameter(p, 'undesired_subject_numbers', {}, @iscell);
addParameter(p, 'excluded_methods', {'Size', 'Constrained_FDR', 'Constrained_FWER', 'TFCE'}, @iscell);
parse(p, varargin{:});

undesired_subject_numbers = p.Results.undesired_subject_numbers;
excluded_methods = p.Results.excluded_methods;

%% Get power data (without averaging across studies)
multi_variable_data = multi_experiment_average(directory); 
data_agregator = struct();

% First loop: prepare empty structs for all subjects
for ri = 1:numel(multi_variable_data)
    res = multi_variable_data{ri};
    n_subs = res.meta_data.subject_number;
    n_subs = ['subs_' num2str(n_subs)];
    
    if ~isfield(data_agregator, n_subs)
        data_agregator.(n_subs) = struct();
    end
end

% Collect individual study data (no averaging)
for ri = 1:numel(multi_variable_data)
    res = multi_variable_data{ri};
    n_subs = res.meta_data.subject_number;
    n_subs = ['subs_' num2str(n_subs)];
    
    for mi = 1:numel(res.meta_data.method_list)
        method = res.meta_data.method_list{mi};
        
        % Skip excluded methods
        if ismember(method, excluded_methods)
            continue;
        end
        
        if ~isfield(data_agregator.(n_subs), method)
            data_agregator.(n_subs).(method) = {res.individual.(method)}; % Individual studies, not mean
        else
            data_agregator.(n_subs).(method){end+1} = res.individual.(method);
        end
    end
end

%% Prepare table data
sub_numbers = fieldnames(data_agregator);
results_x = str2double(extractAfter(sub_numbers, 'subs_'))'; % Subject numbers

% Get all unique methods (excluding those filtered out)
first_subject = sub_numbers{1};
methods = fieldnames(data_agregator.(first_subject));

% Initialize table variables
study_ids = {};
study_types = {};
method_names = {};
param1_values = []; % Scale parameter (λ)
param2_values = []; % Shape parameter (k)
r_squared_values = [];

% Power values at different sample sizes
power_20 = [];
power_40 = [];
power_80 = [];
power_120 = [];
power_200 = [];

%% Process each method and study combination
row_count = 0;

for mi = 1:numel(methods)
    method = methods{mi};
    
    % Get all individual studies for this method across all subject numbers
    all_studies = [];
    for fi = 1:numel(sub_numbers)
        subn = sub_numbers{fi};
        all_studies = [all_studies, data_agregator.(subn).(method)];
    end
    
    % Process each individual study
    for study_idx = 1:numel(all_studies)
        row_count = row_count + 1;
        
        % Collect power values for this study across subject numbers
        results_y = zeros(1, numel(sub_numbers));
        for fi = 1:numel(sub_numbers)
            subn = sub_numbers{fi};
            if study_idx <= numel(data_agregator.(subn).(method))
                results_y(fi) = data_agregator.(subn).(method){study_idx};
            else
                results_y(fi) = NaN; % Missing data
            end
        end
        
        % Skip if too much missing data
        if sum(~isnan(results_y)) < 3
            continue;
        end
        
        % Fit power curve using your default function
        [curve_params, r_squared] = fit_power_curve_params(results_x, results_y);
        
        % Store study information
        study_ids{row_count} = sprintf('Study_%03d', study_idx);
        study_types{row_count} = determine_study_type(study_idx); % You'll need to implement this
        method_names{row_count} = method_name_assigment(method);
        
        % Store curve parameters
        param1_values(row_count) = curve_params(1); % Scale parameter
        param2_values(row_count) = curve_params(2); % Shape parameter
        r_squared_values(row_count) = r_squared;
        
        % Calculate power at specific sample sizes using fitted curve
        default_func = @(params, x) 100*(1 - exp(-(x./params(1)).^params(2)));
        
        power_20(row_count) = default_func(curve_params, 20);
        power_40(row_count) = default_func(curve_params, 40);
        power_80(row_count) = default_func(curve_params, 80);
        power_120(row_count) = default_func(curve_params, 120);
        power_200(row_count) = default_func(curve_params, 200);
    end
end

%% Create MATLAB table
power_table = table(study_ids', study_types', method_names', ...
                   param1_values', param2_values', r_squared_values', ...
                   power_20', power_40', power_80', power_120', power_200', ...
                   'VariableNames', {'Study_ID', 'Study_Type', 'Method', ...
                   'Scale_Param', 'Shape_Param', 'R_Squared', ...
                   'Power_n20', 'Power_n40', 'Power_n80', 'Power_n120', 'Power_n200'});

%% Display summary
fprintf('Generated power table with %d rows\n', height(power_table));
fprintf('Methods included: %s\n', strjoin(unique(method_names), ', '));
fprintf('Studies per method: %d\n', numel(unique(study_ids)));

end
