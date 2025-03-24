function save_incremental_results(RP, all_pvals, all_pvals_neg, ...
    edge_stats_all, cluster_stats_all, current_batch)
%% save_incremental_results
% Updates and saves incremental results for each statistical method in the NBS
% benchmarking pipeline. For each method specified in RP.all_cluster_stat_types, it
% loads existing results (if any), updates the p-values and statistics for new
% repetitions from the current batch, and then saves the updated file.
%
% Inputs:
%   - RP: Configuration structure containing fields such as save_directory, data_set,
%         test_name, test_type, omnibus_type, n_subs_subset, testing, ground_truth,
%         all_cluster_stat_types, edge_groups, n_repetitions, n_var, and existing_repetitions.
%   - all_pvals: Cell array where each cell contains a struct of positive p-values
%                for each method.
%   - all_pvals_neg: Cell array with a struct of negative p-values (deprecated) for each method.
%   - edge_stats_all: Cell array of edge statistics for each repetition.
%   - cluster_stats_all: Cell array of cluster statistics for each repetition.
%   - current_batch: Cell array of repetition indices for the current batch.
%
% Outputs:
%   - No in-memory output. Results are saved to disk.
%
% Workflow:
%   1. Loop through each method in RP.all_cluster_stat_types.
%   2. For each method, generate the expected output file name using
%      create_and_check_rep_file.
%   3. Load existing results if the file exists; otherwise, initialize new storage.
%   4. Ensure that result fields (pvals_all, pvals_all_neg, edge_stats_all,
%      cluster_stats_all) are properly initialized.
%   5. For each repetition in the current batch that is new, update the result fields.
%   6. Update metadata and save the updated file.
%
% Dependencies:
%   - create_and_check_rep_file.m
%   - get_omnibus_type.m
%
% Notes:
%   - Only repetitions that have not been computed previously are updated.
%
% Author: Fabricio Cravo | Date: March 2025

    for stat_id = 1:length(RP.all_full_stat_type_names)
        method_name = RP.all_full_stat_type_names{stat_id};
        
        [existence, output_dir] = create_and_check_rep_file(RP.save_directory, RP.data_set, RP.test_name, ...
                                                            RP.test_type, method_name, ...
                                                            RP.n_subs_subset, RP.testing);

        output_dir_path = fileparts(output_dir);
        if ~exist(output_dir_path, 'dir')
            mkdir(output_dir_path);
        end

        if existence
            % **Load existing data**
            load(output_dir, 'brain_data', 'meta_data');
        else
            % **Initialize new storage**
            brain_data = struct();
            meta_data = struct();
        end

        % **Ensure pvals_all is initialized correctly**
        method_class_name = RP.full_name_method_map(method_name);
        method_instance = feval(method_class_name);  % Instantiate the method
        
        switch method_instance.level
            case "whole_brain"
                required_size = [1, RP.n_repetitions];
            case "network"
                required_size = [length(unique(RP.edge_groups)) - 1, RP.n_repetitions];
            case "edge"
                required_size = [RP.n_var, RP.n_repetitions];
            otherwise
                error("Unknown statistic level: %s", method_instance.level);
        end

        % **Initialize fields in brain_data if they don't exist**
        if ~isfield(brain_data, 'pvals_all') || isempty(brain_data.pvals_all)
            brain_data.pvals_all = nan(required_size);  % Preallocate with NaNs
        end
        if ~isfield(brain_data, 'pvals_all_neg') || isempty(brain_data.pvals_all_neg)
            brain_data.pvals_all_neg = nan(required_size);  % Preallocate with NaNs
        end
        if ~isfield(brain_data, 'edge_stats_all') || isempty(brain_data.edge_stats_all)
            brain_data.edge_stats_all = nan(RP.n_var, RP.n_repetitions);
        end
        if ~isfield(brain_data, 'cluster_stats_all') || isempty(brain_data.cluster_stats_all)
            brain_data.cluster_stats_all = nan(length(unique(RP.edge_groups)) - 1, RP.n_repetitions);
        end
        
        % **Only save repetitions that are newly computed**
        existing_reps = RP.existing_repetitions.(method_name);
        reps_to_save = current_batch(cellfun(@(x) x > existing_reps, current_batch)); 

        if isempty(reps_to_save)
            continue; % Nothing to save for this method
        end

        for i_cell = 1:numel(reps_to_save)
            i = reps_to_save{i_cell};
            j = find(cellfun(@(x) isequal(x, i), current_batch));

            % Extract method-specific p-values from struct inside cell array
            if isfield(all_pvals{j}, method_name)  % Ensure the field exists
                brain_data.pvals_all(:, i) = all_pvals{j}.(method_name);  % Store p-values
            end
            if isfield(all_pvals_neg{j}, method_name)  % Ensure the field exists for negative values
                brain_data.pvals_all_neg(:, i) = all_pvals_neg{j}.(method_name);
            end
          
            brain_data.edge_stats_all(:, i) = edge_stats_all{j};
            brain_data.cluster_stats_all(:, i) = cluster_stats_all{j};
        end

        % **Update metadata**
        meta_data.dataset = RP.data_set_base;
        meta_data.map = RP.data_set_map;
        meta_data.test = RP.test_type;
        meta_data.test_components = strsplit(RP.test_name, '_');
        meta_data.subject_number = RP.n_subs_subset;
        meta_data.testing_code = RP.testing;
        meta_data.test_type = method_name;
        meta_data.parent_method = method_class_name;
        meta_data.statistic_level = method_instance.level;
        meta_data.rep_parameters = RP;
        meta_data.date = datetime("today");

        % **Save updated file**
        save(output_dir, 'brain_data', 'meta_data');
        
    end
    
end