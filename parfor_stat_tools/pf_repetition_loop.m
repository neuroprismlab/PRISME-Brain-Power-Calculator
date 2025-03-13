function [edge_stats, cluster_stats, pvals_method, pvals_method_neg] = ...
    pf_repetition_loop(rep_id, X_subs, Y_subs, RPc, UI)

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
