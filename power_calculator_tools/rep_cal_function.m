function rep_cal_function(Params)
%% rep_cal_function
% **Description**
%   Loads dataset information, configures parameters,
%   initializes parallel processing, and iterates through different statistical 
%   tests to benchmark power estimation.
%
% **Inputs**
%   - 'Params' (struct) - see setparams
%
% **Workflow**
%   1. Load dataset if not already in memory.
%   2. Set up experiment parameters and initialize dataset attributes.
%   3. Create output directory for results.
%   4. Configure parallel workers.
%   5. Iterate through test conditions and extract subject data.
%   6. Generate brain connectivity masks from the node structure.
%   7. Execute benchmarking analysis.
%
% **Example Usage**
% ```matlab
%   Params = setparams();
%   rep_cal_function(Params);
% ```
%
% **Dependencies**
%   - setup_experiment_data.m
%   - get_data_set_name.m
%   - atlas_data_set_map.m
%   - create_output_directory.m
%   - setup_parallel_workers.m
%   - infer_test_from_data.m
%   - subs_data_from_score_condition.m
%   - subs_data_from_contrast.m
%   - create_masks_from_nodes.m
%   - run_benchmarking.m
%
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025
%
    
    %% Check cpp part of code - not necessary for gt
    if ~Params.ground_truth
        Params = check_mex_binaries(Params);
    end

    if ~exist('Dataset', 'var')
        Dataset = load(Params.data_dir);
        Dataset.file_name = Params.data_dir;
    end
    
    %% Set .n_nodes, .n_var, .n_repetitions, .mask
    [Params.mask, Params.n_var, Params.n_nodes] = setup_experiment_data(Dataset);
    [Params.output, Params.data_set_base, Params.data_set_map] = get_data_set_name(Dataset, Params);
    Params.atlas_file = atlas_data_set_map(Params);

    %% Variables are nodes or edges (voxel - activation, or fc edges)
    Params.variable_type = get_variable_type(Dataset);

    %% Check method validity
    Params = check_stat_method_class_validity(Params);
    
    %% Finish method naming
    [Params.all_full_stat_type_names, Params.full_name_method_map] = extract_submethod_info(Params);
    
    %% Create output directory - setup save directory
    Params = create_output_directory(Params);

    %% Parallel Workers 
    % Uncoment the disp line if setup is commented out - as reminder 
    Params.parallel = setup_parallel_workers(Params.parallel, Params.n_workers);   
   
    OutcomeData = Dataset.outcome;
    BrainData = Dataset.brain_data;
        
    studies = fieldnames(OutcomeData);
    
    for ti = 1:length(studies)
        t = studies{ti};
        
        test_number = str2double(erase(string(ti), 'test'));
        if ~isempty(Params.tests_to_skip) && Params.tests_to_skip(test_number)
            continue          
        end

        % Fix RP both tasks
        % RP - stands for Repetition Parameter
       
        RP = Params;

        % Specific study mask data (some datasets have masks for each study)
        % The specific mask overrides the generic
        [RP.mask, RP.n_var, RP.n_nodes] = study_specific_mask(Dataset, Params, t);
        [RP.flat_to_spatial, RP.spatial_to_flat] = create_spatial_flat_map(RP);
        [RP.triumask, RP.trilmask] = create_masks_from_nodes(size(RP.mask, 1));

        % Create graph converter (flat to graph)
        RP.unflat_matrix_fun = unflatten_matrix(RP.mask, 'variable_type', ...
            RP.variable_type, 'flat_to_spatial', RP.flat_to_spatial, 'spatial_to_flat', RP.spatial_to_flat);

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

        % Sets ground truth parameters for gt calculation
        % Future note, avoid this, for clarity, make sure each function returns exactly
        % what is changed - to be fixed
        if Params.ground_truth
            RP = setup_ground_truth_parameters(RP);
        end
       
        run_benchmarking(RP, Y, X)
        
    end
    
end
