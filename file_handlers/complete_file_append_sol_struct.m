function complete_file_append_sol_struct(RP, output_file, all_pvals, all_pvals_neg, ...
                edge_stats_all, cluster_stats_all, method_timing_all, current_batch)

    %% Save edge and network level stuff
    temp_data = load(output_file, 'edge_level_stats', 'network_level_stats');
    edge_level_stats = temp_data.edge_level_stats;
    network_level_stats = temp_data.network_level_stats;

    % Get min existing repetition across all methods for edge/network stats
    min_existing_rep = inf;
    for stat_id = 1:length(RP.all_full_stat_type_names)
        method_name = RP.all_full_stat_type_names{stat_id};
        min_existing_rep = min(min_existing_rep, RP.existing_repetitions.(method_name));
    end
    
    % Update edge and network statistics for repetitions that might be new
    for i_cell = 1:numel(current_batch)
        i = current_batch{i_cell};  % Actual repetition index
        
        % Only update if this repetition is new for at least one method
        if i > min_existing_rep
            edge_level_stats(:, i) = edge_stats_all{i_cell};
            network_level_stats(:, i) = cluster_stats_all{i_cell};
        end
    end
    
    save(output_file, 'edge_level_stats', 'network_level_stats', '-append');
    
    %% Define sig_threashold
    save_threshold = RP.save_significance_thresh;

    %% Save method data
    % Process each method
    for stat_id = 1:length(RP.all_full_stat_type_names)
        method_name = RP.all_full_stat_type_names{stat_id};
        
        % Calculate which repetitions need to be saved for this method
        existing_reps = RP.existing_repetitions.(method_name);
        reps_to_save = current_batch(cellfun(@(x) x > existing_reps, current_batch));
        
        % Get method metadata
        method_class_name = RP.full_name_method_map(method_name);
        method_instance = feval(method_class_name);
        
        % Determine size based on method level
        switch extract_stat_level(method_instance.level)
            case "whole_brain"
                required_size = [1, RP.n_repetitions];
            case "network"
                required_size = [length(unique(RP.edge_groups)) - 1, RP.n_repetitions];
            case "variable"
                required_size = [RP.n_var, RP.n_repetitions];
            otherwise
                error("Unknown statistic level: %s", method_instance.level);
        end

        file_info = whos('-file', output_file);
        file_vars = {file_info.name};
        
        if ismember(method_name, file_vars)
            % Load just this method's struct
            loaded_data = load(output_file, method_name);
            method_struct = loaded_data.(method_name);
        else
            % Initialize new method struct
            method_struct = struct();
            method_struct.total_time = 0;
            method_struct.sig_prob = sparse([], [], [], required_size(1), required_size(2));
            method_struct.sig_prob_neg = sparse([], [], [], required_size(1), required_size(2));
        end

        % Update p-values for new repetitions
        for i_cell = 1:numel(reps_to_save)
            i = reps_to_save{i_cell};  % repetition index
            j = find(cellfun(@(x) isequal(x, i), current_batch));  % index in current_batch
            
            % Convert and store p-values as significance probabilities
            p_values = all_pvals{j}.(method_name);
            sig_prob = 1 - p_values;  % Higher value = more significant
            sig_prob(sig_prob < (1 - save_threshold)) = 0;  % Zero out non-significant values
            method_struct.sig_prob(:, i) = sparse(sig_prob);
        
            p_values_neg = all_pvals_neg{j}.(method_name);
            sig_prob_neg = 1 - p_values_neg;
            sig_prob_neg(sig_prob_neg < (1 - save_threshold)) = 0;
            method_struct.sig_prob_neg(:, i) = sparse(sig_prob_neg);     
        end

        % Update method metadata in the struct
        method_struct.meta_data.level = method_instance.level;
        method_struct.meta_data.parent_method = method_class_name;
        method_struct.meta_data.is_permutation_based = method_instance.permutation_based;
        
        % Sum timing data from this batch using cellfun with anonymous function
        total_batch_time = sum(cellfun(@(timing_struct) timing_struct.(method_name), method_timing_all));

        method_struct.total_time = method_struct.total_time + total_batch_time;
        
        % Use eval to save method struct with dynamic name (unavoidable)
        eval([method_name ' = method_struct;']);
        save(output_file, method_name, '-append');        

    end

end