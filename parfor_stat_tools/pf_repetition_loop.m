function [pvals_rep, pvals_rep_neg] = pf_repetition_loop(STATS, GLM_stats)
      
    % Select the edge statistics for this repetition
    edge_stats_rep = GLM_stats.edge_stats';
    edge_stats_rep_neg = GLM_stats.edge_stats_neg';
    cluster_stats_rep = GLM_stats.cluster_stats';
    cluster_stats_rep_neg = GLM_stats.cluster_stats_neg';
    
    % Load precomputed permutations
    method_instance = feval(STATS.statistic_type);

    if method_instance.permutation_based
        perm_data = GLM_stats.perm_data; 
    else 
        perm_data.permuted_data = [];
        perm_data.permuted_network_data = [];
    end

    
    % Dynamically call the method from './statistical_methods/'
    % Positive effect pvalues
    pvals_rep = run_method(STATS.statistic_type, 'statistical_parameters', STATS, ...
                           'edge_stats', edge_stats_rep, 'network_stats', cluster_stats_rep, ...
                           'glm_parameters', GLM_stats.parameters, ...
                           'permuted_edge_data', perm_data.permuted_data, ...
                           'permuted_network_data', perm_data.permuted_network_data);
    
    % Negative effect pvalues
    pvals_rep_neg = run_method(STATS.statistic_type, 'statistical_parameters', STATS, ...
                           'edge_stats', edge_stats_rep_neg, 'network_stats', cluster_stats_rep_neg, ...
                           'glm_parameters', GLM_stats.parameters, ...
                           'permuted_edge_data', -perm_data.permuted_data, ...
                           'permuted_network_data', -perm_data.permuted_network_data);
  

end