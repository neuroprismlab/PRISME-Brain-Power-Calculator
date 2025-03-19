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
        
        % Assign to rp - 
        RP.existing_repetitions = existing_repetitions;
        RP.max_rep_pending = max_rep_pending;

        % Check if all methods are complete
        if max_rep_pending == 0
            fprintf('All repetitions already computed for test %s and subs %d. Skipping...\n', ...
                RP.test_name, RP.n_subs_subset);
            continue;
        end

        fprintf('Computing repetitions: %s\n', jsonencode(num_pending_per_method));

        process_repetition_batches(X, Y, RP, UI, ids_sampled);
         
        fprintf('Finished test %s and subs %d.\n', RP.test_name, RP.n_subs_subset);

    end

end
  
