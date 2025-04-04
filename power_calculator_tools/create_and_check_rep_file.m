function [existence, full_file_path] = create_and_check_rep_file(data_dir, data_set_name, test_components, ...
                                                                 test_type, rep_subject_number, testing, ...
                                                                 is_gt)
%% create_and_check_rep_file
% **Description**
% Constructs a filename for a repetition result file based on various test and 
% dataset parameters and checks whether the file exists in the specified directory.
%
% **Inputs**
% - data_dir (string): Directory where result files are stored. If NaN, only the 
%   filename is returned.
% - data_set_name (string): Name of the dataset.
% - test_components (string): Component string for the test (e.g., specific test 
%   label or condition).
% - test_type (string): Type of test (e.g., 't', 't2', 'pt', etc.).
% - stat_type (string): Name of the statistical method. For non-Omnibus methods, this 
%   will force the omnibus type to 'nobus'.
% - omnibus_type (string): Specifies the omnibus method label (used only if stat_type is 'Omnibus').
% - rep_subject_number (int): Number of subjects in the current repetition; used 
%   to build a subject-specific string.
% - testing (logical or numeric): Flag indicating if the test is in testing mode.
%
% **Outputs**
% - existence (logical): True if the file exists, false otherwise.
% - full_file_path (string): Full path (or filename if data_dir is NaN) of the 
%   repetition file.
%
% **Workflow**
% 1. Construct a subject number string (e.g., 'subs_20') based on rep_subject_number.
% 2. For non-Omnibus methods, override omnibus_type to 'nobus'.
% 3. Build the filename using sprintf. If stat_type is not 'Ground_Truth', include 
%    all components; otherwise, exclude the subject number.
% 4. Append '-test.mat' if in testing mode, else append '.mat'.
% 5. If a data directory is provided, combine it with the filename to form the full file path 
%    and check file existence; otherwise, return the filename alone.
%
% **Notes**
% - When stat_type is not 'Omnibus', omnibus_type is forced to 'nobus'.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025
    
    %% Preprocess inputs
    subject_number_str = strcat('subs_', int2str(rep_subject_number));
   

    %% Make file name
    if ~is_gt
        rep_file_name = sprintf('%s-%s-%s-%s', data_set_name, test_components, test_type, ...
                                subject_number_str);
    else
        rep_file_name = sprintf('%s-%s-%s-%s', data_set_name, test_components, test_type, ...
                                'Ground_Truth');
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