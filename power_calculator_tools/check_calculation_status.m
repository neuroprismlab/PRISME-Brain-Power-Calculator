function existing_repetitions = check_calculation_status(RP)
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

% Initialize the output structure
existing_repetitions = struct();

% Get the filename for the consolidated results file
[existence, file_path] = create_and_check_rep_file(RP.save_directory, RP.data_set, RP.test_name, ...
                                                RP.test_type, RP.n_subs_subset, ...
                                                RP.testing, RP.ground_truth);

% Initialize all methods to 0 repetitions first
for i = 1:length(RP.all_full_stat_type_names)
    method_name = RP.all_full_stat_type_names{i};
    existing_repetitions.(method_name) = 0;
end

% If the file exists, try to load the metadata
if existence
    try
        % Load just the metadata for efficiency
        loaded_data = load(file_path, 'meta_data');
        
        % Check if metadata and method_current_rep field exist
        if isfield(loaded_data, 'meta_data') && isfield(loaded_data.meta_data, 'method_current_rep')
            % Update repetition counts for all methods that exist in the file
            method_reps = loaded_data.meta_data.method_current_rep;
            method_names = fieldnames(method_reps);
            
            % Update counts for methods that exist in the file
            for i = 1:length(method_names)
                method_name = method_names{i};
                % Only update if this is a method we're looking for
                if isfield(existing_repetitions, method_name)
                    existing_repetitions.(method_name) = method_reps.(method_name);
                end
            end
        else
            warning('File %s exists but does not contain method_current_rep data.', file_path);
            % All methods remain at 0 repetitions (already initialized)
        end
    catch
        warning('Error loading %s. Assuming 0 repetitions for all methods.', file_path);
        % All methods remain at 0 repetitions (already initialized)
    end
end

end