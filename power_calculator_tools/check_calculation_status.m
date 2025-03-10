function existing_repetitions = check_calculation_status(RP)
    % Check how many repetitions exist for each statistical method file
    %
    % Outputs:
    %   - existing_repetitions: A cell array where each entry corresponds to the
    %     number of repetitions stored in each method file.
    %   - files_checked: A cell array with the paths of the checked files.

    % Initialize outputs
    num_methods = length(RP.all_cluster_stat_types);
    existing_repetitions = struct();
    files_checked = cell(num_methods, 1);

    % Iterate through all methods and check existing repetitions
    for stat_id = 1:num_methods
        RP.cluster_stat_type = RP.all_cluster_stat_types{stat_id};
        
        % I hate the Omnibus thing. I need to fix this
        if ~strcmp(RP.cluster_stat_type, 'Omnibus')
            omnibus_str = 'nobus';
        else
            omnibus_str = RP.omnibus_type;
        end

        % Get the filename using create_and_check_rep_file
        [existence, file_path] = create_and_check_rep_file(RP.save_directory, RP.data_set, RP.test_name, ...
                                                           RP.test_type, RP.cluster_stat_type, ...
                                                           omnibus_str, RP.n_subs_subset, ...
                                                           RP.testing, RP.ground_truth);
        
        files_checked{stat_id} = file_path;

        if existence
            try
                % Load the saved file
                loaded_data = load(file_path, 'brain_data');
                
                % Check how many repetitions exist
                if isfield(loaded_data, 'brain_data') && isfield(loaded_data.brain_data, 'pvals_all')
                    existing_repetitions.(RP.cluster_stat_type) = size(loaded_data.brain_data.pvals_all, 2);
                else
                    existing_repetitions.(RP.cluster_stat_type) = 0; % File exists but no repetitions found
                end

            catch
                warning('Error loading %s. Assuming 0 repetitions.', file_path);
                existing_repetitions.(RP.cluster_stat_type) = 0;
            end
        else
            existing_repetitions.(RP.cluster_stat_type) = 0; % File does not exist
        end
    end
end