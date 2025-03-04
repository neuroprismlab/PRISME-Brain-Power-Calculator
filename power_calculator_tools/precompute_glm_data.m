function [GLM_stats, STATS] = precompute_glm_data(X, Y, RP, UI, ids_sampled)
    % Initialize GLM_stats structure
    edge_stats_all = zeros(RP.n_var, RP.n_repetitions);
    edge_stats_all_neg = zeros(RP.n_var, RP.n_repetitions);
    cluster_stats_all = zeros(numel(unique(RP.edge_groups)) - 1, RP.n_repetitions);
    cluster_stats_all_neg = zeros(numel(unique(RP.edge_groups)) - 1, RP.n_repetitions);
    
    % Check if permutation-based methods are needed (done once to avoid redundant calls)
    is_permutation_based = check_if_permutation_method(RP);

    % Parallel or sequential execution
    if RP.parallel
        parfor i_rep = 1:RP.n_repetitions
            GLM_stats_rep = process_repetition(i_rep, X, Y, RP, UI, ids_sampled, is_permutation_based);
            
            % Store computed results
            edge_stats_all(:, i_rep) = GLM_stats_rep.edge_stats_all;
            edge_stats_all_neg(:, i_rep) = GLM_stats_rep.edge_stats_all_neg;
            cluster_stats_all(:, i_rep) = GLM_stats_rep.cluster_stats_all;
            cluster_stats_all_neg(:, i_rep) = GLM_stats_rep.cluster_stats_all_neg;
        end
    else
        for i_rep = 1:RP.n_repetitions
            GLM_stats_rep = process_repetition(i_rep, X, Y, RP, UI, ids_sampled, is_permutation_based);
            
            % Store computed results
            edge_stats_all(:, i_rep) = GLM_stats_rep.edge_stats_all;
            edge_stats_all_neg(:, i_rep) = GLM_stats_rep.edge_stats_all_neg;
            cluster_stats_all(:, i_rep) = GLM_stats_rep.cluster_stats_all;
            cluster_stats_all_neg(:, i_rep) = GLM_stats_rep.cluster_stats_all_neg;
        end
    end
    
    %% Total GLM for parameters 
    UI.design.ui = X;
    UI.matrices.ui = Y;
    nbs = set_up_nbs_parameters(UI);
    GLM = NBSglm_setup_smn(nbs.GLM);
    
    %% Returning edge statistics
    GLM_stats = struct();
    GLM_stats.edge_stats_all = edge_stats_all;
    GLM_stats.edge_stats_all_neg = edge_stats_all_neg;
    GLM_stats.cluster_stats_all = cluster_stats_all;
    GLM_stats.cluster_stats_all_neg = cluster_stats_all_neg;
    
    %% Returning GLM parameters
    GLM_stats.parameters.contrast = GLM.contrast;
    GLM_stats.parameters.test = GLM.test;
    GLM_stats.parameters.perm = GLM.perms;
    GLM_stats.parameters.n_predictors = GLM.n_predictors;
    GLM_stats.parameters.n_GLMs = GLM.n_GLMs;
    GLM_stats.parameters.n_observations = GLM.n_observations;

    %% Return stat parameters 
    STATS = nbs.STATS;
    STATS.has_permutation = is_permutation_based;
end

%% ======================= External Helper Function =======================

function GLM_stats_rep = process_repetition(i_rep, X, Y, RP, UI, ids_sampled, is_permutation_based)
    % Extract the subject indices for this repetition
    rep_sub_ids = ids_sampled(:, i_rep);
    
    % Draw repetitions from original data and reorder according to atlas
    Y_rep = Y(:, rep_sub_ids);
    Y_rep = apply_atlas_order(Y_rep, RP.atlas_file, RP.mask, RP.n_subs_subset);
    
    % Adjust X_rep if using correlation tests
    if strcmp(RP.test_type, 'r')
        X_rep = X(rep_sub_ids, :);
    else
        X_rep = RP.X_rep;
    end
    
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
    GLM_stats_rep.edge_stats_all = edge_stats_pos;
    GLM_stats_rep.edge_stats_all_neg = edge_stats_neg;
    GLM_stats_rep.cluster_stats_all = cluster_stat_pos;
    GLM_stats_rep.cluster_stats_all_neg = -cluster_stat_pos;
    
    % Generate precomputed permutations if required
    if is_permutation_based
        generate_permutation_for_repetition(i_rep, GLM, RP);
    end
    
end