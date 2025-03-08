function [FWER_rep, pvals_rep, FWER_rep_neg,  pvals_rep_neg] = pf_repetition_loop(i_rep, STATS, GLM_stats, GLM, RP)
      
    % Select the edge statistics for this repetition
    edge_stats_rep = GLM_stats.edge_stats_all(:, i_rep);
    edge_stats_rep_neg = GLM_stats.edge_stats_all_neg(:, i_rep);
    cluster_stats_rep = GLM_stats.cluster_stats_all(:, i_rep);
    cluster_stats_rep_neg = GLM_stats.cluster_stats_all_neg(:, i_rep);
    
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
   

    % Check for significant findings for FWER
    FWER_rep = any(pvals_rep(:) < STATS.alpha);
    FWER_rep_neg = any(pvals_rep_neg(:) < STATS.alpha);

end