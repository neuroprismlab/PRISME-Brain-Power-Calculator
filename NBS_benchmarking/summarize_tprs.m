function PowerRes = summarize_tprs(summary_type, method_data, gt_data, Params, method_name, file_type, meta_data)
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
            [~, save_settings] = summary_tools.calculate_positives(method_data, save_settings);

            error('The code is buggy - Fix the tasks and stat_types loop')
                       
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE AND AGGREGATE TRUE POSITIVES
% i.e., combine effect size and positives above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    case 'calculate_tpr'
    
        %% Check if already calculated and get file_name
        %data_set_name = strcat(file_meta_data.dataset, '_', file_meta_data.map);
        %test_components = get_test_components_from_meta_data(file_meta_data.test_components);
        %[~, file_name] = create_and_check_rep_file('', data_set_name, test_components, ...
        %                                           file_meta_data.test, file_meta_data.subject_number, ...
        %                                           file_meta_data.testing_code, false);
        
        if isstring(Params.pthresh_second_level)
            alpha = str2double(Params.pthresh_second_level);
        else
            alpha = Params.pthresh_second_level;
        end
    
    
        %% Calculate positives here
        PowerRes = summary_tools.calculate_positives(method_data, alpha, file_type);
    
        %% Calculate true positives
        PowerRes = summary_tools.calculate_tpr(method_data, gt_data, Params.tpr_dthresh, PowerRes, method_name, ...
            meta_data);
        
        %% Calculate false positives
        PowerRes = summary_tools.calculate_fpr(method_data, gt_data, Params.tpr_dthresh, PowerRes, method_name, ...
            meta_data);
           
end



