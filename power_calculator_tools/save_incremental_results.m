function save_incremental_results(RP, all_pvals, edge_stats_all, cluster_stats_all, completed_reps)
    for stat_id = 1:length(RP.all_cluster_stat_types)
        RP.cluster_stat_type = RP.all_cluster_stat_types{stat_id};
        
        [existence, output_dir] = create_and_check_rep_file(RP.save_directory, RP.data_set, RP.test_name, ...
                                                            RP.test_type, RP.cluster_stat_type, ...
                                                            RP.omnibus_type, RP.n_subs_subset, ...
                                                            RP.testing, RP.ground_truth);

        output_dir_path = fileparts(output_dir);  % Extract directory path
        if ~exist(output_dir_path, 'dir')
            mkdir(output_dir_path);  % Create directory if it doesn't exist
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
        method_instance = feval(RP.cluster_stat_type);  % Instantiate the method
        
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

        % **Initialize pvals_all if it doesn't exist**
        if ~isfield(brain_data, 'pvals_all') || isempty(brain_data.pvals_all)
            brain_data.pvals_all = nan(required_size);  % Preallocate with NaNs
        end

        % **Store computed repetitions without overwriting previous ones**
        for rep_idx = 1:length(completed_reps)
            rep_id = completed_reps(rep_idx);
            
            % Store computed p-values
            brain_data.pvals_all(:, rep_id) = all_pvals.(RP.cluster_stat_type)(:, rep_idx);
        end

        % **Ensure edge and cluster statistics are properly stored as matrices**
        if ~isfield(brain_data, 'edge_stats_all') || isempty(brain_data.edge_stats_all)
            brain_data.edge_stats_all = nan(size(edge_stats_all, 1), RP.n_repetitions);  % Preallocate as NaNs
        end
        if ~isfield(brain_data, 'cluster_stats_all') || isempty(brain_data.cluster_stats_all)
            brain_data.cluster_stats_all = nan(size(cluster_stats_all, 1), RP.n_repetitions);
        end

        % Store edge and cluster statistics if available
        if ~isempty(edge_stats_all)
            brain_data.edge_stats_all(:, completed_reps) = edge_stats_all(:, completed_reps);
        end
        if ~isempty(cluster_stats_all)
            brain_data.cluster_stats_all(:, completed_reps) = cluster_stats_all(:, completed_reps);
        end

        % **Update metadata**
        meta_data.dataset = RP.data_set_base;
        meta_data.map = RP.data_set_map;
        meta_data.test = RP.test_type;
        meta_data.test_components = strsplit(RP.test_name, '_');
        meta_data.omnibus = get_omnibus_type(RP);
        meta_data.subject_number = RP.n_subs_subset;
        meta_data.testing_code = RP.testing;
        meta_data.test_type = RP.cluster_stat_type;
        meta_data.rep_parameters = RP;
        meta_data.date = datetime("today");

        % **Save updated file**
        save(output_dir, 'brain_data', 'meta_data');
        fprintf('Saved %d repetitions for %s to %s\n', length(completed_reps), RP.cluster_stat_type, output_dir);
    end
end