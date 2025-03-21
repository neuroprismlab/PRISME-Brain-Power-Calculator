function process_repetition_batches(X, Y, RP, UI, ids_sampled)
   
    batches_indexes = split_into_batches(RP.max_rep_pending, RP.batch_size);

    for i_bat = 1:numel(batches_indexes)
        batch = batches_indexes{i_bat};
        batch_size = numel(batches_indexes{i_bat});
        
        % Prealocate variables
        X_subs = cell(1, batch_size);
        Y_subs = cell(1, batch_size);

        all_pvals = initialize_global_pvals(RP, batch_size);
        all_pvals_neg = initialize_global_pvals(RP, batch_size);

        edge_stats_all = cell(1, batch_size);
        cluster_stats_all = cell(1, batch_size);
        
        % Prepare sub samples for this batch
        for j = 1:batch_size
            rep_id = batch{j};

            rep_sub_ids = ids_sampled(:, rep_id);
            Y_subs{j} = Y(:, rep_sub_ids);
        
            if strcmp(RP.test_type, 'r')
                X_subs{j} = X(rep_sub_ids, :);
            else
                X_subs{j} = RP.X_rep;
            end
   
        end
        
        % **Loop through missing repetitions**
        RPc = parallel.pool.Constant(RP);
        if ~RP.parallel

            for j = 1:batch_size
            rep_id = batch{j};
            
            [edge_stats_all{j}, cluster_stats_all{j}, all_pvals{j}, all_pvals_neg{j}] = ....
                pf_repetition_loop(rep_id, X_subs{j}, Y_subs{j}, RPc, UI);
          
            end
    
        else

            parfor j = 1:batch_size
            rep_id = batch{j};
            
            [edge_stats_all{j}, cluster_stats_all{j}, all_pvals{j}, all_pvals_neg{j}] = ....
                pf_repetition_loop(rep_id, X_subs{j}, Y_subs{j}, RPc, UI);
          
            end

        end

        save_incremental_results(RP, all_pvals, all_pvals_neg, ...
                                 edge_stats_all, cluster_stats_all, batch)
        
        fprintf('Repetition %d completed \n', batch{end});
        
    end 

    
  
end

