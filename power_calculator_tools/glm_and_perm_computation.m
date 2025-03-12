function [GLM_stats, GLM, STATS] = ...
    glm_and_perm_computation(X_rep, Y_rep, RP, UI, is_permutation_based)

    % Assign new parameters to UI
    UI_new = UI;
    UI_new.design.ui = X_rep;
    UI_new.matrices.ui = Y_rep;
    UI_new.contrast.ui = RP.nbs_contrast;
    
    % Fit GLM and compute edge statistics (positive contrast)
    nbs = set_up_nbs_parameters(UI_new);
    
    % Get STASTS from nbs
    STATS = nbs.STATS;
    
    % Find GLM and edge_stats
    GLM = NBSglm_setup_smn(nbs.GLM);
    edge_stats = NBSglm_smn(GLM);
    
    % Compute network-based statistics
    edge_stat_square = unflatten_matrix(edge_stats, RP.mask);
    cluster_stat = get_network_average(edge_stat_square, RP.edge_groups);
    
    % Transpose 
    edge_stats = edge_stats';
    cluster_stat = cluster_stat';
    
    % Store results in struct
    GLM_stats = struct();
    GLM_stats.edge_stats = edge_stats;
    GLM_stats.cluster_stats = cluster_stat;

    GLM_stats.parameters.contrast = GLM.contrast;
    GLM_stats.parameters.test = GLM.test;
    GLM_stats.parameters.perm = GLM.perms;
    GLM_stats.parameters.n_predictors = GLM.n_predictors;
    GLM_stats.parameters.n_GLMs = GLM.n_GLMs;
    GLM_stats.parameters.n_observations = GLM.n_observations;
    
    % Generate precomputed permutations if required
    if is_permutation_based
        GLM_stats.perm_data = generate_permutation_for_repetition(GLM, RP);
    end

end