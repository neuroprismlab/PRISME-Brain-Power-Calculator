function compact_file_append_sol_struct(RP, output_file, all_pvals, all_pvals_neg, ...
                edge_stats_all, cluster_stats_all, method_timing_all, current_batch)

    %% Save edge and network level stuff
    temp_data = load(output_file, 'edge_level_stats', 'network_level_stats', ...
        'edge_mean_squared_error', 'network_mean_squared_error', 'meta_data');
    
    edge_level_stats = temp_data.edge_level_stats;
    network_level_stats = temp_data.network_level_stats;
    edge_mean_squared_error = temp_data.edge_mean_squared_error;
    network_mean_squared_error = temp_data.network_mean_squared_error;
    
    max_existing_rep = max(cellfun(@(method_name) RP.existing_repetitions.(method_name), ...
                    RP.all_full_stat_type_names));

    % Update edge and network statistics for repetitions that might be new
    for i_cell = 1:numel(current_batch)
        i = current_batch{i_cell}; % Actual repetition index


        % Only update if this repetition is new for at least one method
        if i > max_existing_rep
            % For Welford's algorithm, we need to track count
            n = i;  % Current repetition number serves as count
            
            % Update sum
            edge_level_stats = edge_level_stats + edge_stats_all{i_cell};
            network_level_stats = network_level_stats + cluster_stats_all{i_cell};

            if i == 1
                continue;
            end


            % Calculate delta from old mean
            old_mean_edge = edge_level_stats / (n - 1);
            old_mean_network = network_level_stats / (n - 1);
            
            delta_edge = edge_stats_all{i_cell} - old_mean_edge;
            delta_network = cluster_stats_all{i_cell} - old_mean_network;          
            
            % Update mean squared error using Welford's formula
            new_mean_edge = edge_level_stats / n;
            new_mean_network = network_level_stats / n;
            
            delta2_edge = edge_stats_all{i_cell} - new_mean_edge;
            delta2_network = cluster_stats_all{i_cell} - new_mean_network;
            
            edge_mean_squared_error = edge_mean_squared_error + delta_edge .* delta2_edge;
            network_mean_squared_error = network_mean_squared_error + delta_network .* delta2_network;

        end
    end
    
    % Save back to file - only the existing fields
    save(output_file, 'edge_level_stats', 'network_level_stats', ...
        'edge_mean_squared_error', 'network_mean_squared_error', '-append');
    
    %% Save method stuff
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
                required_size = [1, 1];
            case "network"
                required_size = [length(unique(RP.edge_groups)) - 1, 1];
            case "variable"
                required_size = [RP.n_var, 1];
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
            method_struct.positives = zeros(required_size(1), required_size(2));
            method_struct.negatives = zeros(required_size(1), required_size(2));
            method_struct.total_calculations = 0;

        end


        % Update p-values for new repetitions
        for i_cell = 1:numel(reps_to_save)
            i = reps_to_save{i_cell};  % repetition index
            j = find(cellfun(@(x) isequal(x, i), current_batch));  % index in current_batch
            
            % Convert and store p-values as significance probabilities
            p_values = all_pvals{j}.(method_name);
            sig_prob = 1 - p_values;  % Higher value = more significant
            sig_prob(sig_prob < (1 - RP.pthresh_second_level)) = 0;  % Zero out non-significant values
            sig_prob(sig_prob > (1 - RP.pthresh_second_level)) = 1; % One for significant
            sig_prob = reshape(sig_prob, [], 1);
            method_struct.positives = method_struct.positives + sig_prob;
        
             % Convert and store p-values as significance probabilities
            p_values = all_pvals_neg{j}.(method_name);
            sig_prob = 1 - p_values;  % Higher value = more significant
            sig_prob(sig_prob < (1 - RP.pthresh_second_level)) = 0;  % Zero out non-significant values
            sig_prob(sig_prob > (1 - RP.pthresh_second_level)) = 1; % One for significant
            sig_prob = reshape(sig_prob, [], 1);
            method_struct.negatives = method_struct.negatives + sig_prob;

            method_struct.total_calculations = method_struct.total_calculations + 1;
        end
        

        has_field = cellfun(@(timing_struct) isfield(timing_struct, method_name), method_timing_all);
    

        if any(has_field)
            valid_indices = find(has_field);
            total_batch_time = sum(cellfun(@(timing_struct) timing_struct.(method_name), ...
                method_timing_all(valid_indices)));
            method_struct.total_time = method_struct.total_time + total_batch_time;
        end
     

        % Use eval to save method struct with dynamic name (unavoidable)
        eval([method_name ' = method_struct;']);
        save(output_file, method_name, '-append');
    end


end