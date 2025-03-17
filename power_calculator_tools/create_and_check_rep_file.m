function [existence, full_file_path] = create_and_check_rep_file(data_dir, data_set_name, test_components, ...
                                                                 test_type, stat_type, ...
                                                                 omnibus_type, rep_subject_number, testing, ...
                                                                 ground_truth)
    
    %% Preprocess inputs
    subject_number_str = strcat('subs_', int2str(rep_subject_number));
   
    % If not omnibus, set it to none
    if ~strcmp(stat_type, 'Omnibus')
        omnibus_type = 'nobus';
    end

    %% Make file name
    if ~strcmp(stat_type, 'Ground_Truth')
        rep_file_name = sprintf('%s-%s-%s-%s-%s-%s', data_set_name, test_components, test_type, ...
                                stat_type, omnibus_type, subject_number_str);
    else
        rep_file_name = sprintf('%s-%s-%s-%s-%s', data_set_name, test_components, test_type, ...
                            stat_type, omnibus_type);
    end

    if testing == 1
        rep_file_name = strcat(rep_file_name, '-test.mat');
    else
        rep_file_name = strcat(rep_file_name, '.mat');
    end
    
    if ~isnan(data_dir)
        % Create the full path to the file
        full_file_path = fullfile(data_dir, rep_file_name);
        
        % Check if the file exists
        existence = isfile(full_file_path);
    else
        full_file_path = rep_file_name;
        existence = false;
    end
    
end