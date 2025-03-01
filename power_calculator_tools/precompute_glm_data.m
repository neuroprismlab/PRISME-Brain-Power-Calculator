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

        UI_new_neg = UI_new;
        UI_new_neg.contrast.ui = RP.nbs_contrast_neg;
        
        %% Fit GLM and get edge stats with NEGATIVE contrast
        nbs_neg = set_up_nbs_parameters(UI_new);
        GLM_neg = NBSglm_setup_smn(nbs_neg.GLM);
        GLM_stats.edge_stats_all_neg(:, i_rep) = NBSglm_smn(GLM_neg);
        
        %% Average everything for network-based stats
        edge_stat_square = unflatten_matrix(GLM_stats.edge_stats_all(:, i_rep), RP.mask);
        edge_stat_square = get_network_average(edge_stat_square, RP.edge_groups);
        GLM_stats.cluster_stats_all(:, i_rep) = edge_stat_square;
        
        edge_stat_square_neg = unflatten_matrix(GLM_stats.edge_stats_all_neg(:, i_rep), RP.mask);
        edge_stat_square_neg = get_network_average(edge_stat_square_neg, RP.edge_groups);
        GLM.cluster_stats_all_neg(:, i_rep) = edge_stat_square_neg;
        
    end
    
    %% Get an example of stats here
    STATS = nbs.STATS;
    
end


