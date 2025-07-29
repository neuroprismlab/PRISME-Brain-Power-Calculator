function [existing_repetitions, ids_sampled, meta_data] = check_calculation_status(RP)
%% check_calculation_status
% **Description**
% Checks which statistical methods already have repetitions computed and saved to disk.
% It returns a struct mapping each method to the number of repetitions available
% in the consolidated results file.
%
% **Inputs**
% - `RP` (struct): Configuration structure containing:
%   * `save_directory` – path to the directory with output files.
%   * `data_set` – name of the dataset.
%   * `test_name` – label of the statistical test.
%   * `test_type` – type of test ('t', 't2', etc.).
%   * `n_subs_subset` – number of subjects for current subsample.
%   * `testing` – logical flag for test/debug mode.
%   * `all_full_stat_type_names` – list of method names to check.
%   * `ground_truth` - flag indicating if this is ground truth data.
%
% **Outputs**
% - `existing_repetitions` (struct): Map from method name to the number of valid repetitions.
%
% **Workflow**
% 1. Check if the consolidated results file exists.
% 2. If it exists, load the metadata and check for method_current_rep field.
% 3. For each requested method, get the current repetition count or default to 0.
% 4. If the file doesn't exist or can't be loaded, default to 0 repetitions for all methods.
%
% **Dependencies**
% - `create_and_check_rep_file.m`
%
% **Notes**
% - This function works with the consolidated file format where all methods are stored in a single file.
%
% **Author**: Fabricio Cravo
% **Date**: March 2025
% **Modified**: April 2025 - Updated for consolidated file structure
    
    %% Check if correct dataset first
    % Get first .mat file in the folder for dataset validation
    mat_files = dir(fullfile(RP.save_directory, '*.mat'));

    if ~isempty(mat_files)
        % Extract current dataset filename (no path, no extension)
        [~, current_dataset_name, ~] = fileparts(RP.data_dir);
        
        dataset_found = false;
        stored_dataset_name = '';

        
        % Loop through all .mat files to find one with dataset info
        for file_idx = 1:length(mat_files)
            file_path = fullfile(RP.save_directory, mat_files(file_idx).name);
            
            % Look for dataset info in any of the files
            try
                loaded_data = load(file_path, 'meta_data');
                stored_dataset_name = loaded_data.meta_data.rep_parameters.data_dir;
                [~, stored_dataset_name, ~] = fileparts(stored_dataset_name);
                dataset_found = true;
                break; % Found it, exit loop
            catch
                % This file doesn't have dataset info, try next one
                continue;
            end
        end
          
        if dataset_found && ~strcmp(stored_dataset_name, current_dataset_name)
            error(['The stored dataset name in the current analysed files and the given dataset for this ' ...
                'calculation do not match']);
        end 
    end
    
    %% Check number of repetitions
    % Initialize output
    existing_repetitions = struct();
    
    % Resolve file path
    [existence, file_path] = create_and_check_rep_file(RP.save_directory, RP.output, RP.test_name, ...
        RP.test_type, RP.n_subs_subset, RP.testing, RP.ground_truth);

    % Initialize all methods to 0 repetitions
    for i = 1:length(RP.all_full_stat_type_names)
        method_name = RP.all_full_stat_type_names{i};
        existing_repetitions.(method_name) = 0;
    end

    if existence

        try
            loaded_data = load(file_path, 'meta_data');
    
            if isfield(loaded_data, 'meta_data')
                meta_data = loaded_data.meta_data;
                ids_sampled = meta_data.repetition_ids;

                %% Validate number of subjects in repetition IDs
                actual_n_subs = size(ids_sampled, 1);
                % t2 test draws in double
                if strcmp(RP.test_type, 't2')
                   actual_n_subs = actual_n_subs/2;
                end
                expected_n_subs = RP.n_subs_subset;
                
                if actual_n_subs ~= expected_n_subs
                    error(['Subject count mismatch! Existing file has %d subjects but current analysis ' ...
                           'requires %d subjects. Please delete the existing results file: %s'], ...
                           actual_n_subs, expected_n_subs, file_path);
                end
                
                % Extract method_current_rep
                if isfield(meta_data, 'method_current_rep')
                    method_reps = meta_data.method_current_rep;
                    method_names = fieldnames(method_reps);
                    for i = 1:length(method_names)
                        method_name = method_names{i};
                        if isfield(existing_repetitions, method_name)
                            existing_repetitions.(method_name) = method_reps.(method_name);
                        end
                    end
                end

                ids_sampled = meta_data.repetition_ids;
                required_reps = RP.n_repetitions;
             
                % Check if we have enough repetition IDs
                if length(ids_sampled) < required_reps
                    fprintf('Need to expand repetition IDs from %d to %d\n', ...
                        length(ids_sampled), required_reps);
                    
                    % Calculate how many new repetitions we need
                    n_additional_reps = required_reps - length(ids_sampled);
                    
                    % Draw only the additional repetitions needed
                    new_ids = draw_repetition_ids(RP, 'n_reps', n_additional_reps);
                    
                    % Append the new IDs to the existing ones
                    ids_sampled = [ids_sampled, new_ids];
                    
                    % Update meta_data
                    meta_data.repetition_ids = ids_sampled;
                    
                    % Save updated meta_data
                    
                    if ~RP.test_disable_save
                        meta_data = create_meta_data_file(file_path, RP, ids_sampled, existing_repetitions);
                        fprintf('Updated results file with %d additional repetition IDs: %s\n', ...
                            n_additional_reps, file_path);
                    end
                    
                end
                
            else
                error('Meta_data missing in file: %s. Please delete file to continue calculations', file_path);
            end

        catch 
            error('Corrupted file in %s. Please delete it or add correct meta-data.\n', file_path);
        end

    else
        % File does not exist — initialize new meta_data
        ids_sampled = draw_repetition_ids(RP);
    
        meta_data = struct();
        meta_data.repetition_ids = ids_sampled;
        meta_data.method_current_rep = struct();
        for i = 1:length(RP.all_full_stat_type_names)
            method_name = RP.all_full_stat_type_names{i};
            meta_data.method_current_rep.(method_name) = 0;
        end
    
        % Save initialized file
        if ~RP.test_disable_save
            meta_data = create_meta_data_file(file_path, RP, ids_sampled, existing_repetitions);
            fprintf('Initialized results file with repetition IDs: %s\n', file_path);
        end
    end


    % If we need to recalculate - set everything to zero again
    if RP.recalculate 
        for i = 1:length(RP.all_full_stat_type_names)
            method_name = RP.all_full_stat_type_names{i};
            existing_repetitions.(method_name) = 0;
        end
    end
     

end
