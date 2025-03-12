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
       
        num_pending_per_method = structfun(@(x) max(RP.n_repetitions - x, 0), existing_repetitions, ...
            'UniformOutput', false);
        max_rep_pending = max(structfun(@(x) x, num_pending_per_method));
        
        % Check if all methods are complete
        if max_rep_pending == 0
            fprintf('All repetitions already computed. Skipping...\n');
            continue;
        end

        fprintf('Computing repetitions: %s\n', jsonencode(num_pending_per_method));

        % Prealocate space for pvals
        % **Group Methods by Level**
        all_pvals = initialize_global_pvals(RP, UI, max_rep_pending);
        all_pvals_neg = initialize_global_pvals(RP, UI, max_rep_pending);

        % Preallocate edge and cluster statistics storage
        % Preallocate edge and cluster statistics storage as cell arrays
        edge_stats_all = cell(1, max_rep_pending);
        cluster_stats_all = cell(1, max_rep_pending);

        % **Pre-fill each cell with zeroes - for parfor
        for i = 1:max_rep_pending
            edge_stats_all{i} = zeros(RP.n_var, 1)';
            cluster_stats_all{i} = zeros(length(unique(UI.edge_groups.ui)) - 1, 1)';
        end

        % Precompute X and Y subsets for all repetitions to avoid broadcast issues
        X_reps = cell(1, max_rep_pending);
        Y_reps = cell(1, max_rep_pending);

        for rep_idx = 1:max_rep_pending
            rep_sub_ids = ids_sampled(:, rep_idx);
            
            if strcmp(RP.test_type, 'r')
                X_reps{rep_idx} = X(rep_sub_ids, :);
            else
                X_reps{rep_idx} = RP.X_rep;
            end
            
            Y_reps{rep_idx} = Y(:, rep_sub_ids);
        end

        % Define as parallel constants to minimize redundant memory transfer
        Xc = parallel.pool.Constant(X_reps);
        Yc = parallel.pool.Constant(Y_reps); 

        % **Loop through missing repetitions**
        RPc = parallel.pool.Constant(RP);
        NRc = parallel.pool.Constant(num_pending_per_method);
        if ~RP.parallel

            
            'Hii'


        else

            parfor rep_idx = 1:numel(all_pvals)
                
                edge_row = edge_stats_all{rep_idx};
                cluster_row = cluster_stats_all{rep_idx};

                % Compute GLM and permutations
                [GLM_stats, ~, STATS] = glm_and_perm_computation( ...
                    Xc.Value{rep_idx}, Yc.Value{rep_idx}, RPc.Value, UI, RPc.Value.is_permutation_based);
                
                 % Assign computed statistics
                edge_row = GLM_stats.edge_stats;
                cluster_row = GLM_stats.cluster_stats;

                % Store back into the cell array
                edge_stats_all{rep_idx} = edge_row;
                cluster_stats_all{rep_idx} = cluster_row;

                % Store computed edge and cluster statistics
                local_pvals = all_pvals{rep_idx};
                local_pvals_neg = all_pvals_neg{rep_idx};
                
                % Compute p-values for each statistical method
                for stat_id = 1:length(RPc.Value.all_cluster_stat_types)
                    STATS.statistic_type = RPc.Value.all_cluster_stat_types{stat_id};
                    STATS.omnibus_type = RPc.Value.omnibus_type;

                     % Stop computing for this method if we reached its required repetitions
                    if rep_idx > NRc.Value.(STATS.statistic_type)
                        continue;
                    end
                    
                    [pvals, pvals_neg] = pf_repetition_loop(STATS, GLM_stats);
                    local_pvals.(STATS.statistic_type) = pvals;
                    local_pvals_neg.(STATS.statistic_type) = pvals_neg;
                end

                 % Write back to the main cell array
                all_pvals{rep_idx} = local_pvals; 
                all_pvals_neg{rep_idx} = local_pvals_neg;
                
              
            end
          
           
       
        end
       

        save_incremental_results(RPc.Value, all_pvals, all_pvals_neg, edge_stats_all, ...
            cluster_stats_all, NRc.Value); 

    end

end
  
