function [GLM_stats, GLM, STATS] = ...
    glm_and_perm_computation(X_rep, Y_rep, STATS, UI, is_permutation_based)
%% glm_and_perm_computation
% Description:
% Fits a general linear model (GLM) to the data and computes permutation‐based
% statistics if required. It sets up NBS parameters from the provided UI and RP,
% fits the GLM, calculates edge-level statistics, computes network-based statistics,
% and optionally generates permutation data.
%
% Inputs:
% - X_rep (matrix): Design matrix for the GLM.
% - Y_rep (matrix): Data matrix (features × subjects) for the GLM.
% - RP (struct): Configuration structure with parameters such as nbs_contrast,
%   mask, and edge_groups.
% - UI (struct): Structure containing NBS parameters (design, contrast, etc.).
% - is_permutation_based (logical): Flag indicating whether to generate permutation data.
%
% Outputs:
% - GLM_stats (struct): Structure containing edge and cluster statistics, and various GLM parameters.
% - GLM (struct): Fitted GLM structure from NBSglm_setup_smn.
% - STATS (struct): Statistics extracted from the NBS parameter setup.
%
% Workflow:
% 1. Update the UI structure with current design, matrices, and contrast.
% 2. Set up NBS parameters using the updated UI.
% 3. Extract STATS from the NBS parameter structure.
% 4. Fit the GLM and compute edge-level statistics.
% 5. Compute network-based statistics by unflattening edge statistics and averaging
%    over predefined edge groups.
% 6. Store GLM outputs and parameters into GLM_stats.
% 7. If permutation-based analysis is enabled, generate permutation data.
%
% Dependencies:
% - set_up_nbs_parameters.m
% - NBSglm_setup_smn.m
% - NBSglm_smn.m
% - unflatten_matrix.m
% - get_network_average.m
% - generate_permutation_for_repetition.m
%
% Notes:
% - The computed edge and network statistics (= cluster) are transposed before storage.
% - Permutation data is generated only if is_permutation_based is true.
%
% Author: Fabricio Cravo  
% Date: March 2025

    % Assign new parameters to UI
    UI_new = UI;
    UI_new.design.ui = X_rep;
    UI_new.matrices.ui = Y_rep;
    UI_new.contrast.ui = STATS.nbs_contrast;
    
    % Fit GLM and compute edge statistics (positive contrast)
    nbs = set_up_nbs_parameters(UI_new);
    
    % Find GLM and edge_stats
    GLM = NBSglm_setup_smn(nbs.GLM);
    edge_stats = GLM_fit(GLM);
    
    % Compute network-based statistics
    flat_edge_groups = flat_matrix(STATS.edge_groups, STATS.mask);
    cluster_stat = get_network_average(edge_stats, flat_edge_groups);
    
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
        GLM_stats.perm_data = generate_permutation_for_repetition(GLM, STATS);
    end

end