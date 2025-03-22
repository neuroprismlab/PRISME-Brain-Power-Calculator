function [edge_stats, cluster_stats, pvals_method, pvals_method_neg] = ...
    pf_repetition_loop(rep_id, X_subs, Y_subs, RPc, UI)
%% pf_repetition_loop
% Description:
% Executes a single repetition of the benchmarking loop by computing GLM
% statistics and permutations, extracting edge and cluster-level results, and 
% calculating p-values for each statistical method specified in the configuration.
%
% Inputs:
% - rep_id (int): Index of the current repetition.
% - X_subs (matrix): Design matrix for the current subject subset.
% - Y_subs (matrix): Brain data matrix (features × subjects) for the subset.
% - RPc (parallel.pool.Constant): Constant-wrapped configuration structure.
% - UI (struct): Structure containing NBS test configuration parameters.
%
% Outputs:
% - edge_stats (matrix): GLM-derived edge-level statistics.
% - cluster_stats (matrix or struct): Cluster-level statistics computed via NBS.
% - pvals_method (struct): Struct containing positive p-values for each method.
% - pvals_method_neg (struct): Struct containing negative p-values for each method.
%
% Workflow:
% 1. Compute GLM statistics and permutation-based null distributions by calling
%    glm_and_perm_computation.
% 2. Extract edge and cluster statistics from the GLM output.
% 3. For each statistical method skip computation if the current repetition
% is already computed. Otherwise, compute p-values using p_value_from_method and store the results.
%
% Dependencies:
% - glm_and_perm_computation.m
% - p_value_from_method.m
%
% Notes:
% - Negative p-values (pvals_method_neg) are computed for legacy reasons; currently,
%   the negative test statistic is derived by negating the positive value.
% - Repetition skipping is based on RPc.Value.existing_repetitions.
%
% Author: Fabricio Cravo  
% Date: March 2025

    % Compute GLM and permutations
    [GLM_stats, ~, STATS] = glm_and_perm_computation( ...
        X_subs, Y_subs, RPc.Value, UI, RPc.Value.is_permutation_based);
    
     % Assign computed statistics
    edge_stats = GLM_stats.edge_stats;
    cluster_stats = GLM_stats.cluster_stats;

    % Store computed edge and cluster statistics
    pvals_method = struct();
    pvals_method_neg = struct();
    
    % Compute p-values for each statistical method
    for stat_id = 1:length(RPc.Value.all_cluster_stat_types)
        STATS.statistic_type = RPc.Value.all_cluster_stat_types{stat_id};
        STATS.omnibus_type = RPc.Value.omnibus_type;

        % Stop computing for this method if we reached its required repetitions
        if rep_id <= RPc.Value.existing_repetitions.(STATS.statistic_type)
            continue;
        end
        
        [pvals, pvals_neg] = p_value_from_method(STATS, GLM_stats);
        pvals_method.(STATS.statistic_type) = pvals;
        pvals_method_neg.(STATS.statistic_type) = pvals_neg;
    end
    
 
end
