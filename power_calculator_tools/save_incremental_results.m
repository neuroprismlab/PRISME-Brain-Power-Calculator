function save_incremental_results(RP, all_pvals, edge_stats_all, cluster_stats_all, completed_reps)
    for stat_id = 1:length(RP.all_cluster_stat_types)
        RP.cluster_stat_type = RP.all_cluster_stat_types{stat_id};
        
        [existence, output_dir] = create_and_check_rep_file(RP.save_directory, RP.data_set, RP.test_name, ...
                                                            RP.test_type, RP.cluster_stat_type, ...
                                                            RP.omnibus_str, RP.n_subs_subset, ...
                                                            RP.testing, RP.ground_truth);

        if existence
            % **Load existing data**
            load(output_dir, 'brain_data', 'meta_data');
        else
            % **Initialize new storage**
            brain_data = struct();
            meta_data = struct();
        end

        % **Store new computed repetitions**
        for rep_idx = 1:length(completed_reps)
            rep_id = completed_reps(rep_idx);
            brain_data.pvals_all(:, rep_id) = all_pvals.(RP.cluster_stat_type){rep_idx};
            brain_data.edge_stats_all{rep_id} = edge_stats_all{rep_idx};
            brain_data.cluster_stats_all{rep_id} = cluster_stats_all{rep_idx};
        end

        % Update metadata
        meta_data.dataset = RP.data_set_base;
        meta_data.map = RP.data_set_map;
        meta_data.test = RP.test_type;
        meta_data.test_components = strsplit(RP.test_name, '_');
        meta_data.omnibus = RP.omnibus_str;
        meta_data.subject_number = RP.n_subs_subset;
        meta_data.testing_code = RP.testing;
        meta_data.test_type = RP.cluster_stat_type;
        meta_data.rep_parameters = RP;
        meta_data.date = datetime("today");

        % **Save updated file**
        save(output_dir, 'brain_data', 'meta_data', '-append');
        fprintf('Saved %d repetitions for %s to %s\n', length(completed_reps), RP.cluster_stat_type, output_dir);
    end
end