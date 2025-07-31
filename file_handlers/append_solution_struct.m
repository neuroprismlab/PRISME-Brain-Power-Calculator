function append_solution_struct(RP, output_file, ...
    all_pvals, all_pvals_neg, edge_stats_all, cluster_stats_all, method_timing_all, current_batch)
    
    % To finish this function
    % complete_file_append_sol_struct
    % compact_file_append_sol_struct
    
    %% Save data from files
    switch RP.subsample_file_type
        
        case 'full_file'
            complete_file_append_sol_struct(RP, output_file, all_pvals, all_pvals_neg, ...
                edge_stats_all, cluster_stats_all, method_timing_all, current_batch)

        otherwise
            error('Placeholder')

    end
    
    %% Update repetition calculations in meta_data
    temp_data = load(output_dir, 'meta_data');
           
    % Update meta_data with existing data
    meta_data = temp_data.meta_data;

    %% Update repetition storage
    for stat_id = 1:length(RP.all_full_stat_type_names)

        % Calculate which repetitions need to be saved for this method
        existing_reps = RP.existing_repetitions.(method_name);
        reps_to_save = current_batch(cellfun(@(x) x > existing_reps, current_batch));
        
        if isempty(reps_to_save)
            continue; % Nothing to save for this method
        end
        
        % Update meta_data with current repetition index for this method
        meta_data.method_current_rep.(method_name) = reps_to_save{end};
    end
    keyboard;

end

