function run_benchmarking(RP, Y, X)
% Do NBS-based method benchmarking (cNBS, TFCE, etc)

    for id_nsub_list = 1:length(RP.list_of_nsubset)
        RP.n_subs_subset = RP.list_of_nsubset{id_nsub_list};
        RP = set_n_subs_subset(RP);

        [RP.node_nets, RP.trilmask_net, RP.edge_groups] = extract_atlas_related_parameters(RP, Y);
        
        % Prepare benchmarking setup
        [UI, RP] = setup_benchmarking(RP);
        ids_sampled = draw_repetition_ids(RP);

        % Check which repetitions are already computed for each method
        existing_repetitions = check_calculation_status(RP);
        
        % Define function to get subset of X (to avoid redundant copying)
        if strcmp(RP.test_type, 'r')
            get_X_rep = @(rep_sub_ids) X(rep_sub_ids, :);
        else
            get_X_rep = @(~) RP.X_rep;
        end

        % Get the number of pending repetition
        min_existing_reps = min(structfun(@max, existing_repetitions));
        pending_repetitions = find(min_existing_reps + 1 : RP.n_repetitions);
        num_pending = length(pending_repetitions);

        if num_pending == 0
            fprintf('All %d repetitions already computed. Skipping...\n', RP.n_repetitions);
            continue;
        end

        fprintf('Computing %d repetitions...\n', num_pending);

      
        % Preallocate all_pvals structure before parfor
        all_pvals = struct();
        for stat_id = 1:length(RP.all_cluster_stat_types)
            method_instance = feval(RP.all_cluster_stat_types{stat_id});  % Instantiate method
            
            % Get the required size based on method level
            switch method_instance.level
                case "whole_brain"
                    all_pvals.(RP.all_cluster_stat_types{stat_id}) = zeros(1, num_pending);
                
                case "network"
                    all_pvals.(RP.all_cluster_stat_types{stat_id}) = ...
                        zeros(length(unique(UI.edge_groups.ui)) - 1, num_pending);
                
                case "edge"
                    all_pvals.(RP.all_cluster_stat_types{stat_id}) = zeros(RP.n_var, num_pending);
                
                otherwise
                    error("Unknown statistic level: %s", method_instance.level);
            end
        end

        % **Loop through missing repetitions**
        RPc = parallel.pool.Constant(RP);
        if ~RP.parallel

            for rep_idx = 1:num_pending
                i_rep = pending_repetitions(rep_idx);
                rep_sub_ids = ids_sampled(:, i_rep);
    
                % Compute GLM and permutations
                [GLM_stats, ~, STATS] = glm_and_perm_computation( ...
                    get_X_rep(rep_sub_ids), Y(:, rep_sub_ids), RPc.Value, UI, RPc.Value.is_permutation_based);
                
    
                % Compute p-values for each statistical method
                for stat_id = 1:length(RP.all_cluster_stat_types)
                    STATS.statistic_type = RPc.Value.all_cluster_stat_types{stat_id};
                    STATS.omnibus_type = RPc.Value.omnibus_type;
                    
                    all_pvals.(RPc.Value.cluster_stat_type){rep_idx} = pf_repetition_loop(STATS, GLM_stats);
                end
                
                % **Save Every 25% of Repetitions**
                save_every = ceil(RP.n_repetitions*RP.batch_save_fraction);
                if mod(rep_idx, save_every) == 0 || rep_idx == num_pending
                    fprintf('Saving progress at repetition %d/%d...\n', rep_idx, num_pending);
                    save_incremental_results(RP, all_pvals, GLM_stats.edge_stats', GLM_stats.cluster_stats', ...
                        pending_repetitions(1:rep_idx));
                end
            end
        
        else

            parfor rep_idx = 1:num_pending
                i_rep = pending_repetitions(rep_idx);
                rep_sub_ids = ids_sampled(:, i_rep);
    
                % Compute GLM and permutations
                [GLM_stats, ~, STATS] = glm_and_perm_computation( ...
                    get_X_rep(rep_sub_ids), Y(:, rep_sub_ids), RPc.Value, UI, RPc.Value.is_permutation_based);
                
    
                % Compute p-values for each statistical method
                for stat_id = 1:length(RPc.Value.all_cluster_stat_types)
                    STATS.statistic_type = RPc.Value.all_cluster_stat_types{stat_id};
                    STATS.omnibus_type = RPc.Value.omnibus_type;
                    
                    all_pvals.(RPc.Value.cluster_stat_type)(:, rep_idx) = pf_repetition_loop(STATS, GLM_stats);
                end
                
                % **Save Every 25% of Repetitions**
                save_every = ceil(RPc.Value.n_repetitions*RPc.Value.batch_save_fraction);
                if mod(rep_idx, save_every) == 0 || rep_idx == num_pending
                    fprintf('Saving progress at repetition %d/%d...\n', rep_idx, num_pending);
                    save_incremental_results(RP, all_pvals, GLM_stats.edge_stats', GLM_stats.cluster_stats', ...
                        pending_repetitions(1:rep_idx));
                end
            end

        end


    end
end