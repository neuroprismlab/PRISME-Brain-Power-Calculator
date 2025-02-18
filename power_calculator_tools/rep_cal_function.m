function rep_cal_function(Params)

    if ~exist('Dataset', 'var')
        Dataset = load(Params.data_dir);
    end
    
    %% Set .n_nodes, .n_var, .n_repetitions, .mask
    Params.ground_truth = false;
    Params = setup_experiment_data(Params, Dataset);
    [Params.data_set, Params.data_set_base, Params.data_set_map] = get_data_set_name(Dataset);
    Params.atlas_file = atlas_data_set_map(Params);
    
    %% Create output directory - setup save directory
    Params = create_output_directory(Params);

    %% Parallel Workers 
    % Uncoment the disp line if setup is commented out - as reminder 
    Params.parallel = setup_parallel_workers(Params.parallel, Params.n_workers);
   
    OutcomeData = Dataset.outcome;
    BrainData = Dataset.brain_data;
        
    tests = fieldnames(OutcomeData);
    
    for ti = 1:length(tests)
        t = tests{ti};
        % Fix RP both tasks
        % RP - stands for Repetition Parameter
       
        RP = Params;
        
        [RP, test_type_origin] = infer_test_from_data(RP, OutcomeData.(t), BrainData);
        
        % Important, X is calculated here for all test_types
        % However, only the r test type will use this test
        switch test_type_origin
            
            % Here: RP.test_name, RP.n_subs_1, RP.n_subs_2, RP.n_subs
            case 'score_cond'
                [X, Y , RP] = subs_data_from_score_condition(RP, OutcomeData.(t), BrainData, t);
           
            case 'contrast'
                [X, Y , RP] = subs_data_from_contrast(RP, OutcomeData.(t).contrast, BrainData);
            
            otherwise
                error('Test type origin not found')

        end  

        [RP.triumask, RP.trilmask] = create_masks_from_nodes(size(RP.mask, 1));

        run_benchmarking(RP, Y, X)
        
    
    end

end
