function rep_cal_function(Params)

    if ~exist('Dataset', 'var')
        Dataset = load(Params.data_dir);
    end
    
    %% Set n_nodes, n_var, n_repetitions 
    Params = setup_experiment_data(Params, Dataset);
    Params = create_output_directory(Params);
    [Params.data_set, Params.data_set_base, Params.data_set_map] = get_data_set_name(Dataset);
    Params.atlas_file = atlas_data_set_map(Params);

    %% Parallel Workers 
    % Uncoment the disp line if setup is commented out - as reminder 
    Params.parallel = setup_parallel_workers(Params.parallel, Params.n_workers);
    % disp('Debugging: Setup parallel workers deactived')
    
    disp(Params.parallel)

    OutcomeData = Dataset.outcome;
    BrainData = Dataset.brain_data;
        
    tests = fieldnames(OutcomeData);
    
    for ti = 1:length(tests)
        t = tests{ti};
        % Fix RP both tasks
        % RP - stands for Repetition Parameters
       
        RP = Params;
        
        
        [RP, test_type_origin] = infer_test_from_data(RP, OutcomeData.(t), BrainData);
        
        % bellow - gets: test name, subject data, subject numbers, subids, and number of subjects
        switch test_type_origin
            
            case 'score_cond'
                [~, Y , RP] = subs_data_from_score_condtion(RP, OutcomeData.(t), BrainData);
           
            case 'contrast'
                [~, Y , RP] = subs_data_from_contrast(RP, OutcomeData.(t).contrast, BrainData);
            
            otherwise
                error('Test type origin not found')
        end
        
        [RP.triumask, RP.trilmask] = create_masks_from_nodes(size(RP.mask, 1));
        
        % Sets parameters which are different than gt
        %% TODO: THIS DOES NOT MAKE SENSE
        RP = setup_parameters_for_rp(RP);
    
        run_benchmarking(RP, Y)
        
        %if RP.testing == 1 && ti == 2
        %    return;
        %end
    
    end

end
