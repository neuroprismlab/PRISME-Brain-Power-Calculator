function process_repetition_batches(X, Y, RP, UI)
%% process_repetition_batches
% Description:
% Executes benchmarking repetitions in mini-batches, optionally using parallel 
% computation. For each batch of repetition indices, data is subsampled, analyzed, 
% and saved incrementally. Handles test-type-specific design matrix behavior and 
% manages output across repetitions.
%
% Inputs:
% - `X` (matrix): Design matrix or input scores (used only for correlation tests).
% - `Y` (matrix): Brain connectivity data (edges × subjects).
% - `RP` (struct): Configuration structure for benchmarking, includes:
%   * `parallel` – use parallel execution (logical).
%   * `test_type`, `X_rep`, `batch_size`, `max_rep_pending`, etc.
% - `UI` (struct): Structure with NBS test configuration (see `setup_benchmarking`).
% - `RP.ids_sampled` (matrix): Subsampled subject indices (columns = repetitions).
%
% Workflow:
% 1. Split repetition IDs into batches of size `batch_size`.
% 2. For each batch:
%    - Subsample `X` and `Y` for each repetition.
%    - Preallocate output containers (`pvals`, `stats`, etc.).
%    - Execute `pf_repetition_loop` using either serial or parallel execution.
%    - Save results incrementally via `save_incremental_results`.
%
% Outputs:
% - Results are saved to disk in batches; no in-memory output is returned.
%
% Dependencies:
% - `split_into_batches.m`
% - `initialize_global_pvals.m`
% - `pf_repetition_loop.m`
% - `save_incremental_results.m`
%
% Notes:
% - For test type `'r'`, `X` is subsampled; otherwise, `RP.X_rep` is reused.
% - `RP` is passed as a `parallel.pool.Constant`(RPc) in parallel mode.
%
% Author: Fabricio Cravo  
% Date: March 2025
   
    batches_indexes = split_into_batches(RP.existing_repetitions, RP.max_rep_pending, RP.batch_size);

    for i_bat = 1:numel(batches_indexes)
        batch = batches_indexes{i_bat};
        batch_size = numel(batches_indexes{i_bat});
        
        % Prealocate variables
        X_subs = cell(1, batch_size);
        Y_subs = cell(1, batch_size);

        all_pvals = initialize_global_pvals(RP, batch_size);
        all_pvals_neg = initialize_global_pvals(RP, batch_size);

        method_timing_all = initialize_method_timming(RP, batch_size);

        edge_stats_all = cell(1, batch_size);
        cluster_stats_all = cell(1, batch_size);
        
        % Prepare sub samples for this batch
        for j = 1:batch_size
            rep_id = batch{j};
        
            rep_sub_ids = RP.ids_sampled(:, rep_id);
            Y_subs{j} = Y(:, rep_sub_ids);
        
            if strcmp(RP.test_type, 'r')
                X_subs{j} = X(rep_sub_ids, :);
            else
                X_subs{j} = RP.X_rep;
            end
            
        end

        % Create empty STATS structure
        STATS = struct();

        % Fill with only what workers need
        STATS.n_var = RP.n_var;
        STATS.n_perms = RP.n_perms;
        STATS.variable_type = RP.variable_type;
        STATS.nbs_contrast = RP.nbs_contrast;
        STATS.mask = RP.mask;
        STATS.edge_groups = RP.edge_groups;
        STATS.test_type = RP.test_type;
        STATS.unflatten_matrix = RP.unflat_matrix_fun;
        STATS.mask = RP.mask;
        STATS.existing_repetitions = RP.existing_repetitions;
        STATS.all_submethods = RP.all_submethods;
        STATS.all_cluster_stat_types = RP.all_cluster_stat_types;
        STATS.is_permutation_based = RP.is_permutation_based; 
        STATS.thresh = RP.tthresh_first_level;
        STATS.alpha = RP.pthresh_second_level;

        % **Loop through missing repetitions**
        STATSc = parallel.pool.Constant(STATS);
        if ~RP.parallel

            for j = 1:batch_size
            rep_id = batch{j};
            
            [edge_stats_all{j}, cluster_stats_all{j}, all_pvals{j}, all_pvals_neg{j}, method_timing_all{j}] = ...
                pf_repetition_loop(rep_id, X_subs{j}, Y_subs{j}, STATSc.Value, UI);
    
            end
    
        else

            parfor j = 1:batch_size
            rep_id = batch{j};
            
            [edge_stats_all{j}, cluster_stats_all{j}, all_pvals{j}, all_pvals_neg{j}, method_timing_all{j}] = ...
                pf_repetition_loop(rep_id, X_subs{j}, Y_subs{j}, STATSc.Value, UI);
          
            end

        end

        % Check output format before saving
        check_pval_output_data(RP, all_pvals, all_pvals_neg);
        
        % Save
        if ~RP.test_disable_save
            save_incremental_results(RP, all_pvals, all_pvals_neg, ...
                                    edge_stats_all, cluster_stats_all, method_timing_all, batch)
        end
        fprintf('Repetition %d completed \n', batch{end});

    end 

    
  
end

