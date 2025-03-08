function [pvals_rep, pvals_rep_neg] = pf_repetition_loop(i_rep, STATS, GLM_stats, GLM, RP)
      
    % Select the edge statistics for this repetition
    edge_stats_rep = GLM_stats.edge_stats';
    edge_stats_rep_neg = GLM_stats.edge_stats_neg';
    cluster_stats_rep = GLM_stats.cluster_stats';
    cluster_stats_rep_neg = GLM_stats.cluster_stats_neg';
    
    % Load precomputed permutations
    if STATS.has_permutation
        
        script_dir = fileparts(mfilename('fullpath'));  
        parent_dir = fileparts(script_dir);  
        perm_file = fullfile(parent_dir, 'GLM_permutations', sprintf('permutation_%d.mat', i_rep));
        
        if ~exist(perm_file, 'file')
            perm_data = generate_permutation_for_repetition(i_rep, GLM, RP, false); 
        else 
            perm_data = load(perm_file, 'permuted_data', 'permuted_network_data');
        end
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