function [GLM_stats, STATS, All_GLM] = precompute_glm_data(X, Y, RP, UI, ids_sampled)
    
    % Remove permutation directory and everything inside
    if exist('./GLM_permutations', 'dir')
        rmdir('./GLM_permutations', 's');  
    end
    
    % Check if permutation-based methods are needed (done once to avoid redundant calls)
    is_permutation_based = check_if_permutation_method(RP);
    
    % Precompute & Store Only Required Data Per Repetition
    Y_subs = cell(1, RP.n_repetitions);
    X_subs = cell(1, RP.n_repetitions);
    GLM_stats = cell(1, RP.n_repetitions);  % Store struct per repetition
    All_GLM = cell(1, RP.n_repetitions); % Store one GLM per repetion

    for i_rep = 1:RP.n_repetitions
        rep_sub_ids = ids_sampled(:, i_rep);
        Y_subs{i_rep} = Y(:, rep_sub_ids);
        
        if strcmp(RP.test_type, 'r')
            X_subs{i_rep} = X(rep_sub_ids, :);
        else
            X_subs{i_rep} = RP.X_rep;
        end
    end

    % Parallel or sequential execution
    if RP.parallel
        parfor i_rep = 1:RP.n_repetitions
            [GLM_stats_rep, GLM] = process_repetition(i_rep, X_subs{i_rep}, Y_subs{i_rep}, RP, ...
                UI, is_permutation_based);
            
            % Store computed results
            GLM_stats{i_rep} = GLM_stats_rep;
            All_GLM{i_rep} = GLM;
        end
    else
        for i_rep = 1:RP.n_repetitions
            [GLM_stats_rep, GLM] = process_repetition(i_rep, X_subs{i_rep}, Y_subs{i_rep}, RP, ...
                UI, is_permutation_based);
            
            % Store computed results
            GLM_stats{i_rep} = GLM_stats_rep;
            All_GLM{i_rep} = GLM;
        end
    end

    %% Total GLM for parameters (only for reference, not used in parallel)
    UI.design.ui = X;
    UI.matrices.ui = Y;
    nbs = set_up_nbs_parameters(UI);
    
    %% Return stat parameters 
    STATS = nbs.STATS;
    STATS.has_permutation = is_permutation_based;

    if ~RP.precompute_permutations
        fprintf('Skipping precomputing permutations (on-demand generation enabled).\n');
    end
end

%% ======================= External Helper Function =======================

function [GLM_stats_rep, GLM] = process_repetition(i_rep, X_rep, Y_rep, RP, UI, is_permutation_based)
    % Extract the subject indices for this repetition
    %rep_sub_ids = ids_sampled(:, i_rep);
    
    % Draw repetitions from original data and reorder according to atlas
    %Y_rep = Y(:, rep_sub_ids);
    %Y_rep = apply_atlas_order(Y_rep, RP.atlas_file, RP.mask, RP.n_subs_subset);
    
    % Adjust X_rep if using correlation tests
    %if strcmp(RP.test_type, 'r')
    %    X_rep = X(rep_sub_ids, :);
    %else
    %    X_rep = RP.X_rep;
    %end
    
    % Assign new parameters to UI
    UI_new = UI;
    UI_new.design.ui = X_rep;
    UI_new.matrices.ui = Y_rep;
    UI_new.contrast.ui = RP.nbs_contrast;
    
    % Fit GLM and compute edge statistics (positive contrast)
    nbs = set_up_nbs_parameters(UI_new);
    GLM = NBSglm_setup_smn(nbs.GLM);
    edge_stats_pos = NBSglm_smn(GLM);
    
    % Compute negative contrast directly from the positive
    edge_stats_neg = -edge_stats_pos;
    
    % Compute network-based statistics
    edge_stat_square = unflatten_matrix(edge_stats_pos, RP.mask);
    cluster_stat_pos = get_network_average(edge_stat_square, RP.edge_groups);
    
    % Store results in struct
    GLM_stats_rep = struct();
    GLM_stats_rep.edge_stats = edge_stats_pos;
    GLM_stats_rep.edge_stats_neg = edge_stats_neg;
    GLM_stats_rep.cluster_stats = cluster_stat_pos;
    GLM_stats_rep.cluster_stats_neg = -cluster_stat_pos;

    GLM_stats_rep.parameters.contrast = GLM.contrast;
    GLM_stats_rep.parameters.test = GLM.test;
    GLM_stats_rep.parameters.perm = GLM.perms;
    GLM_stats_rep.parameters.n_predictors = GLM.n_predictors;
    GLM_stats_rep.parameters.n_GLMs = GLM.n_GLMs;
    GLM_stats_rep.parameters.n_observations = GLM.n_observations;
    
    % Generate precomputed permutations if required
    if is_permutation_based && RP.precompute_permutations
        generate_permutation_for_repetition(i_rep, GLM, RP, true);
    end
    
end