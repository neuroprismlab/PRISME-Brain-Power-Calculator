function [FWER_rep, edge_stats_rep, pvals_rep, cluster_stats_rep, ...
          FWER_rep_neg, edge_stats_rep_neg, pvals_rep_neg, cluster_stats_rep_neg] = ...
          pf_repetition_loop(i_rep, ids_sampled, STATS, GLM_stats)
      
    % Select the edge statistics for this repetition
    edge_stats_rep = GLM_stats.edge_stats_all(:, i_rep);
    edge_stats_rep_neg = GLM_stats.edge_stats_all_neg(:, i_rep);
    
    % Dynamically call the method from './statistical_methods/'
    pvals_rep = run_method(RP.cluster_stat_type, 'statistical_parameters', STATS, ...
        'edge_stats', edge_stats_rep, RP);
    pvals_rep_neg = run_method(RP.cluster_stat_type, edge_stats_rep_neg, RP);
    
    % Check for significant findings for FWER
    FWER_rep = any(pvals_rep(:) < RP.alpha);
    FWER_rep_neg = any(pvals_rep_neg(:) < RP.alpha);
    
    % Compute cluster stats only if necessary
    if contains(RP.cluster_stat_type, {'cNBS', 'Omnibus'})
        cluster_stats_rep = run_method(RP.cluster_stat_type, edge_stats_rep, RP, 'cluster_stats');
        cluster_stats_rep_neg = run_method(RP.cluster_stat_type, edge_stats_rep_neg, RP, 'cluster_stats');
    else
        cluster_stats_rep = [];
        cluster_stats_rep_neg = [];
    end

    % Ensure correct shape when only 1 repetition
    if RP.n_repetitions == 1
        cluster_stats_rep = reshape(cluster_stats_rep, [], 1);
        cluster_stats_rep_neg = reshape(cluster_stats_rep_neg, [], 1);
    end
end