function GLM_stats = precompute_glm_data(X, Y, RP, UI, ids_sampled)
    
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
    
        nbs = set_up_nbs_parameters(UI_new);
        GLM = NBSglm_setup_smn(nbs.GLM);
        GLM_stats = NBSglm_smn(GLM);

    end

end


