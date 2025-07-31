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
    [existence, output_file] = create_and_check_rep_file(RP.save_directory, RP.output, RP.test_name, ...
                                                        RP.test_type, RP.n_subs_subset, RP.testing, RP.ground_truth);

    if ~existence
        error('A base file named % with meta-data should exist to append incremental results')
    end

    % To finish this function
    % complete_file_append_sol_struct
    % compact_file_append_sol_struct
    
    %% Save data from files
    switch RP.subsample_file_type
        
        case 'full_file'
            complete_file_append_sol_struct(RP, output_file, all_pvals, all_pvals_neg, ...
                edge_stats_all, cluster_stats_all, method_timing_all, current_batch)

        case 'compact_file'
            compact_file_append_sol_struct(RP, output_file, all_pvals, all_pvals_neg, ...
                edge_stats_all, cluster_stats_all, method_timing_all, current_batch)

        otherwise
            error('Placeholder')

    end
    
    %% Update repetition calculations in meta_data
    temp_data = load(output_file, 'meta_data');
           
    % Update meta_data with existing data
    meta_data = temp_data.meta_data;

    %% Update repetition storage
    for stat_id = 1:length(RP.all_full_stat_type_names)
        method_name = RP.all_full_stat_type_names{stat_id};

        % Calculate which repetitions need to be saved for this method
        existing_reps = RP.existing_repetitions.(method_name);
        reps_to_save = current_batch(cellfun(@(x) x > existing_reps, current_batch));
        
        if isempty(reps_to_save)
            continue; % Nothing to save for this method
        end
        
        % Update meta_data with current repetition index for this method
        meta_data.method_current_rep.(method_name) = reps_to_save{end};
    end
    
    save(output_file, 'meta_data', '-append');

end