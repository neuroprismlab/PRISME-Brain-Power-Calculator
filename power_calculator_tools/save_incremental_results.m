function save_incremental_results(RP, all_pvals, all_pvals_neg, ...
    edge_stats_all, cluster_stats_all, method_timing_all, current_batch)
%% save_incremental_results
% Updates and saves incremental results for each statistical method in the NBS
% benchmarking pipeline, with optimized memory usage through sparse matrices.
%
% Inputs:
%   - RP: Configuration structure containing fields such as save_directory, data_set,
%         test_name, test_type, n_subs_subset, testing, edge_groups, n_repetitions,
%         n_var, and existing_repetitions.
%   - all_pvals: Cell array where each cell contains a struct of positive p-values
%                for each method.
%   - all_pvals_neg: Cell array with a struct of negative p-values for each method.
%   - edge_stats_all: Cell array of edge statistics for each repetition.
%   - cluster_stats_all: Cell array of cluster statistics for each repetition.
%   - current_batch: Cell array of repetition indices for the current batch.
%
% Outputs:
%   - No in-memory output. Results are saved to disk.
%
% Key Memory Optimization:
%   - P-values are stored as sparse matrices of significance probabilities (1-pval)
%   - Each method has its own struct with data and metadata fields
%   - Each method struct is stored separately in the file for selective loading
%   - Significance values below threshold (p > 0.10) are zeroed out
%
% Author: Fabricio Cravo | Date: March 2025
% Modified: April 2025 - Memory optimization with sparse matrices

    % Create a consolidated output filename
    [existence, output_dir] = create_and_check_rep_file(RP.save_directory, RP.output, RP.test_name, ...
                                                        RP.test_type, RP.n_subs_subset, RP.testing, RP.ground_truth);

    output_dir_path = fileparts(output_dir);
    if ~exist(output_dir_path, 'dir')
        mkdir(output_dir_path);
    end

    % Define the significance threshold for sparse storage
    sig_threshold = RP.save_significance_thresh;

    % Always create fresh meta_data
    meta_data = struct();
    meta_data.output = RP.output;
    meta_data.dataset = RP.data_set_base;
    meta_data.map = RP.data_set_map;
    meta_data.test = RP.test_type;
    meta_data.test_components = strsplit(RP.test_name, '_');
    meta_data.subject_number = RP.n_subs_subset;
    meta_data.testing_code = RP.testing;
    meta_data.repetition_ids = RP.ids_sampled;
    RP = rmfield(RP, 'ids_sampled');
    meta_data.rep_parameters = RP;
    meta_data.date = datetime("today");
    meta_data.method_list = RP.all_full_stat_type_names;
    meta_data.method_current_rep = struct();
    
    % Initialize or load edge_level_stats and network_level_stats
    if existence
        % Check if edge_level_stats and network_level_stats exist
        file_info = whos('-file', output_dir);
        file_vars = {file_info.name};
        
        if ismember('edge_level_stats', file_vars) && ismember('network_level_stats', file_vars)
            temp_data = load(output_dir, 'edge_level_stats', 'network_level_stats');
            edge_level_stats = temp_data.edge_level_stats;
            network_level_stats = temp_data.network_level_stats;
        else
            edge_level_stats = nan(RP.n_var, RP.n_repetitions);
            network_level_stats = nan(length(unique(RP.edge_groups)) - 1, RP.n_repetitions);
        end

        if ismember('meta_data', file_vars) 
            temp_data = load(output_dir, 'meta_data');
            
            % Update meta_data with existing data
            temp_meta_data = temp_data.meta_data;
            if isfield(temp_meta_data, 'method_list') && ~isempty(temp_meta_data.method_list)
                % Concatenate method_list without duplicates
                meta_data.method_list = unique([meta_data.method_list, temp_meta_data.method_list]);
            end
            
            % Merge method_current_rep fields
            if isfield(temp_meta_data, 'method_current_rep') && isstruct(temp_meta_data.method_current_rep)
                % Get field names from both structures
                existing_methods = fieldnames(temp_meta_data.method_current_rep);
                
                % Initialize method_current_rep if empty
                if ~isfield(meta_data, 'method_current_rep') || ~isstruct(meta_data.method_current_rep)
                    meta_data.method_current_rep = struct();
                end
                
                % Copy fields from existing structure
                for i = 1:length(existing_methods)
                    method_name = existing_methods{i};
                    meta_data.method_current_rep.(method_name) = temp_meta_data.method_current_rep.(method_name);
                end
            else
                meta_data.method_current_rep = struct();
            end

        end
   
    else
        % Initialize new storage
        edge_level_stats = nan(RP.n_var, RP.n_repetitions);
        network_level_stats = nan(length(unique(RP.edge_groups)) - 1, RP.n_repetitions);
    end
    
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
    
    % Save the edge_level_stats and network_level_stats
    if existence
        save(output_dir, 'edge_level_stats', 'network_level_stats', '-append');
    else
        save(output_dir, 'edge_level_stats', 'network_level_stats', 'meta_data', '-v7.3');
    end

    % Process each method
    for stat_id = 1:length(RP.all_full_stat_type_names)
        method_name = RP.all_full_stat_type_names{stat_id};
        
        % Calculate which repetitions need to be saved for this method
        existing_reps = RP.existing_repetitions.(method_name);
        reps_to_save = current_batch(cellfun(@(x) x > existing_reps, current_batch));
        
        if isempty(reps_to_save)
            continue; % Nothing to save for this method
        end
        
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
        
        % Variable name for this method
        method_var_name = method_name;
        
        % Load or initialize method data
        if existence
            file_info = whos('-file', output_dir);
            file_vars = {file_info.name};
            
            if ismember(method_var_name, file_vars)
                % Load just this method's struct
                cmd = ['load(output_dir, ''' method_var_name ''');'];
                eval(cmd);
                
                % Get the loaded variable (have to use eval due to dynamic naming)
                cmd = ['method_struct = ' method_var_name ';'];
                eval(cmd);
            else
                % Initialize new method struct
                method_struct = struct();
                method_struct.total_time = 0;
                method_struct.sig_prob = sparse([], [], [], required_size(1), required_size(2));
                method_struct.sig_prob_neg = sparse([], [], [], required_size(1), required_size(2));
                method_struct.meta_data = struct();
            end
        else
            % Initialize new method struct
            method_struct = struct();
            method_struct.total_time = 0;
            method_struct.sig_prob = sparse([], [], [], required_size(1), required_size(2));
            method_struct.sig_prob_neg = sparse([], [], [], required_size(1), required_size(2));
            method_struct.meta_data = struct();
        end
        
        % Update p-values for new repetitions
        for i_cell = 1:numel(reps_to_save)
            i = reps_to_save{i_cell};  % repetition index
            j = find(cellfun(@(x) isequal(x, i), current_batch));  % index in current_batch
            
            % Convert and store p-values as significance probabilities
            p_values = all_pvals{j}.(method_name);
            sig_prob = 1 - p_values;  % Higher value = more significant
            sig_prob(sig_prob < (1 - sig_threshold)) = 0;  % Zero out non-significant values
            method_struct.sig_prob(:, i) = sparse(sig_prob);
        
            p_values_neg = all_pvals_neg{j}.(method_name);
            sig_prob_neg = 1 - p_values_neg;
            sig_prob_neg(sig_prob_neg < (1 - sig_threshold)) = 0;
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
        eval([method_var_name ' = method_struct;']);
        save(output_dir, method_var_name, '-append');
        
        % Update meta_data with current repetition index for this method
        meta_data.method_current_rep.(method_name) = reps_to_save{end};
    end
    
    % Save the updated meta_data at the end
    save(output_dir, 'meta_data', '-append');

    fprintf('Saved results to %s\n', output_dir);
end