function [GLM_stats, STATS] = precompute_glm_data(X, Y, RP, UI, ids_sampled)
    
    GLM_stats = struct();
    GLM_stats.edge_stats_all = zeros(RP.n_var, RP.n_repetitions);
    GLM_stats.edge_stats_all_neg = zeros(RP.n_var, RP.n_repetitions);

    for i_rep=1: RP.n_repetitions

        rep_sub_ids = ids_sampled(:, i_rep);
        
        % Draw reps from original data and reorder according to atlas
        Y_rep = Y(:, rep_sub_ids);
        Y_rep = apply_atlas_order(Y_rep, RP.atlas_file, RP.mask, RP.n_subs_subset); 
        
        % For the r test - we draw from X and invert X and Y
        if strcmp(RP.test_type, 'r')
            X_rep = X(rep_sub_ids, :);
        else
            X_rep = RP.X_rep;
        end
                  
        % Assign setup_benchmark parameters to new UI
        UI_new = UI;
        
        % Set this repetition design matrix and Y_rep 
        UI_new.design.ui = X_rep;
        UI_new.matrices.ui = Y_rep;
        UI_new.contrast.ui = RP.nbs_contrast;  
        
        %% Fit GLM and get edge stats with POSITIVE contrast
        nbs = set_up_nbs_parameters(UI_new);
        GLM = NBSglm_setup_smn(nbs.GLM);
        GLM_stats.edge_stats_all(:, i_rep) = NBSglm_smn(GLM);
        GLM_stats.edge_stats_all_neg(:, i_rep) = -GLM_stats.edge_stats_all(:, i_rep);
        
        %% Average everything for network-based stats
        edge_stat_square = unflatten_matrix(GLM_stats.edge_stats_all(:, i_rep), RP.mask);
        edge_stat_square = get_network_average(edge_stat_square, RP.edge_groups);
        GLM_stats.cluster_stats_all(:, i_rep) = edge_stat_square;
        GLM_stats.cluster_stats_all_neg(:, i_rep) = -edge_stat_square;
        
        if check_if_permutation_method(RP)
            generate_permutation_for_repetition(i_rep, GLM, RP.n_perms, RP.n_var)
        end 

    end
    
    %% Get an example of stats here
    % And pass reusable variables from GLM
    STATS = nbs.STATS;
    GLM_stats.parameters.contrast = GLM.contrast;
    GLM_stats.parameters.test = GLM.test;
    GLM_stats.parameters.perm = GLM.perms;
    GLM_stats.parameters.n_predictors = GLM.n_predictors;
    GLM_stats.parameters.n_GLMs = GLM.n_GLMs;
    GLM_stats.parameters.n_observations = GLM.n_observations;

end


