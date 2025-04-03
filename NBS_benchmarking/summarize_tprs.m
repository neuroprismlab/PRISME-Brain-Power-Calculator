function PowerRes = summarize_tprs(summary_type, rep_data, gt_data, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script summarizes results data to ultimately compare true positive
% rates across levels of inference.
% 
% specify first arg ('summary_type') as follows:
% 
%       'dcoeff':           calculate dcoefficients for each task/ground truth level
% 
%       'positives':        calculate positives for each task/stat
% 
%       'calculate_tpr':    calculate true positive rates for each task/stat
%                           relies on completion of 'dcoeff' & 'positives'   
% 
%       'visualize_gt':     visualize ground truth, comparing levels of inference (ground truth)
%                           relies on completion of 'dcoeff'
% 
%       'visualize_tpr':    visualize true positive rates, comparing levels of inference
%                           relies on completion of 'tpr'
%
% Usage 1. 'positives'
%  summarize_tprs('positives', 'tasks', {'SOCIAL_v_REST'}, 'stat_types', {'Size_Extent'}, 'grsize', 40, 'make_figs', 0,
% 'save_logs',0);
%
% Task choices: SOCIAL_v_REST; WM_v_REST; GAMBLING_v_REST; RELATIONAL_v_REST; EMOTION_v_REST; MOTOR_v_REST; 
% GAMBLING_v_REST
%
% Usage 2. 'visualize_tpr'
%   summarize_tprs('visualize_tpr','grsize',120,'save_figs',0,'save_logs',0, 'do_combined',0);
%
% Requirements:
%   for 'dcoefficients': ground truth test statistics (see calculate_ground_truth.m)
%   for 'positives': benchmarking results
%   for 'tpr': dcoefficients and positives
%   for 'visualize: 'tpr' for all tasks and stat types
%
% Relies on: summary_tools.m (defined functions), setparams_summary.m (defines misc params),
%   set_datetimestr_and_files.m (defines file parts)
%
% Recommended to first run with local access to data for calculate_positives
% --this intermediate file is slow to create but can then be
% used to recreate any summaries/visualizations. Note that this step
% doesn't rely on the ground truth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% PARSE PARAMETERS

% parse user input
% something is up with the validator when I added this required arg, so I removed (i.e.,   ,
% @(x)validateattributes(x,{'char','cell'},{'nonempty'})   )

p = inputParser;
% addOptional(p,'summary_type',summary_type_default);
addRequired(p,'summary_type');
addOptional(p,'tpr_dthresh', 0);
addOptional(p,'save_directory', NaN)
parse(p, summary_type, varargin{:});

% summary_type=p.Results.summary_type;
tpr_dthresh = p.Results.tpr_dthresh;
save_directory = p.Results.save_directory;

if isnan(save_directory)
    error('Save directory not specified')
end

% Make save directory if it does not exist

if ~isfolder(save_directory)
    mkdir(save_directory)
end

%% MAIN

switch summary_type

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE POSITIVES
% note: this is the only one where individual stat_types can be specificied
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    case 'positives'
    
    % There is only one task and one stat type per calculation now
    for t=1:length(tasks)
        for s=1:length(stat_types)
            
            task = tasks{t};
            stat_type = stat_types{s};

            % calculate and save tpr (checking before saving is built in)
            [~, save_settings] = summary_tools.calculate_positives(rep_data, save_settings);

            error('The code is buggy - Fix the tasks and stat_types loop')
                       
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE AND AGGREGATE TRUE POSITIVES
% i.e., combine effect size and positives above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

case 'calculate_tpr'

    %% Check if already calculated and get file_name
    data_set_name = strcat(rep_data.meta_data.dataset, '_', rep_data.meta_data.map);
    test_components = get_test_components_from_meta_data(rep_data.meta_data.test_components);
    [~, file_name] = create_and_check_rep_file(save_directory, data_set_name, test_components, ...
                                               rep_data.meta_data.test, rep_data.meta_data.significance_method, ...
                                               rep_data.meta_data.subject_number, ...
                                               rep_data.meta_data.testing_code);
    
    [f_location, f_name, f_ext] = fileparts(file_name);
    f_name = strcat('pr-', f_name);
    file_name = fullfile(f_location, [f_name, f_ext]);
    
    %% Do we repeat the calculations at each time?
    %if isfile(file_name)
    %    PowerRes = nan;
    %    return;
    %end    
    

    %% Calculate positives here
    PowerRes = summary_tools.calculate_positives(rep_data);

    %% Calculate true positives
    PowerRes = summary_tools.calculate_tpr(rep_data, gt_data, tpr_dthresh, PowerRes);

    power_data = PowerRes;
    meta_data = rep_data.meta_data;

    save(file_name, "power_data", "meta_data");
    fprintf('Saved file %s\n', file_name);
           
end



