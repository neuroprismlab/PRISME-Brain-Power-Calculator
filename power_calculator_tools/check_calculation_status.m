function [existing_repetitions, ids_sampled] = check_calculation_status(RP)
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

    % Initialize output
    existing_repetitions = struct();
    
    % Resolve file path
    [existence, file_path] = create_and_check_rep_file(RP.save_directory, RP.data_set, RP.test_name, ...
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
    
                % Optionally: you can attach repetition_ids to RP here
                if isfield(meta_data, 'repetition_ids')

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
                        save(file_path, 'meta_data', '-v7.3');
                        fprintf('Updated results file with %d additional repetition IDs: %s\n', ...
                            n_additional_reps, file_path);
                        
                    end
                 
                end
            else
                warning('meta_data missing in file: %s', file_path);
            end

        catch ME
            warning('Failed to load meta_data from %s. Assuming 0 reps.\n%s', file_path, ME.message);
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
        save(file_path, 'meta_data', '-v7.3');
        fprintf('Initialized results file with repetition IDs: %s\n', file_path);
    end
    
end
