function rep_cal_function(Params)
    
    disp(Params.data_dir)

    if ~exist('Dataset', 'var')
        Dataset = load(Params.data_dir);
    end
    
    
    %% Set n_nodes, n_var, n_repetitions 
    Params = setup_experiment_data(Params, Dataset);
    Params = create_output_directory(Params);
    Params.data_set = get_data_set_name(Dataset);
    Params.atlas_file = atlas_data_set_map(Params);

    %% Parallel Workers 
    %setup_parallel_workers(Params.parallel, Params.n_workers);
    
    OutcomeData = Dataset.outcome;
    BrainData = Dataset.brain_data;
        
    tests = fieldnames(OutcomeData);
    
    for ti = 1:length(tests)
        
        t = tests{ti};
        % Fix RP both tasks
        % RP - stands for Repetition Parameters
        RP = Params;
    
        RP = infer_test_from_data(RP, OutcomeData.(t), BrainData);
        
        % bellow - gets: test name, subject data, subject numbers, subids, and number of subjects
        [~, Y , RP] = subs_data_from_contrast(RP, OutcomeData.(t).contrast, BrainData);
        
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
