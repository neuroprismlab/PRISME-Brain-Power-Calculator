function run_benchmarking(RP, Y, X)
%% run_benchmarking
% **Description**
% Runs statistical benchmarking using the implemented and requested statistical methods 
% across a range of subsample sizes. For each subset size, it sets up 
% benchmarking configurations, checks for completed repetitions, and processes 
% the remaining repetitions using batch execution.
%
% **Inputs**
% - `RP` (struct): Configuration structure with experiment parameters, including:
%   * `list_of_nsubset` – list of sample sizes.
%   * `n_repetitions` – number of repetitions to compute.
%   * `test_name` – test identifier.
% - `Y` (matrix): Brain data matrix (features × subjects).
% - `X` (matrix): Design matrix for statistical testing.
%
% **Workflow**
% For each subsample size:
% 1. Update configuration with current subset size.
% 2. Extract atlas-related parameters (e.g., node networks).
% 3. Set up the benchmarking UI and sample IDs for repetition.
% 4. Check how many repetitions have already been computed for each method.
% 5. Skip iteration if all repetitions are done.
% 6. Otherwise, compute the remaining repetitions in batches.
%
% **Dependencies**
% - `set_n_subs_subset.m`
% - `extract_atlas_related_parameters.m`
% - `setup_benchmarking.m`
% - `draw_repetition_ids.m`
% - `check_calculation_status.m`
% - `process_repetition_batches.m`
%
% **Notes**
% - Updates `RP` with fields like `existing_repetitions` and `max_rep_pending`.
% - Skips processing if no repetitions are pending for a method.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025


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

        fprintf('Computing repetitions for test "%s", subsample size %d: %s\n', ...
                RP.test_name, RP.n_subs_subset, jsonencode(num_pending_per_method));

        process_repetition_batches(X, Y, RP, UI, ids_sampled);
         
        fprintf('Finished test %s and subs %d.\n', RP.test_name, RP.n_subs_subset);

    end

end
  
