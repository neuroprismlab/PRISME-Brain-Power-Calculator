function [pvals_rep, pvals_rep_neg] = p_value_from_method(STATS, GLM_stats)
%% p_value_from_method
% Computes p-values for a given statistical method by dynamically calling the
% appropriate routine from the statistical methods folder.
%
% Inputs:
%   - STATS: Structure containing statistical parameters, including:
%         - STATS.statistic_type: Name of the statistical method to use.
%   - GLM_stats: Structure containing computed GLM results, including:
%         - GLM_stats.edge_stats: Edge-level test statistics.
%         - GLM_stats.cluster_stats: Cluster-level test statistics.
%         - GLM_stats.parameters: GLM parameters.
%         - GLM_stats.perm_data: Permutation data (if available).
%
% Outputs:
%   - pvals_rep: P-values for positive effects computed by the method.
%   - pvals_rep_neg: P-values for negative effects computed by the method.
%
% Workflow:
%   1. Retrieve edge and cluster statistics from GLM_stats.
%   2. Instantiate the method using feval and check if it is permutation-based.
%   3. If permutation-based, load precomputed permutation data.
%   4. Dynamically call run_method to compute p-values for the positive effect.
%   5. Similarly, compute p-values for the negative effect by negating the test statistics.
%
% Author: Fabricio Cravo | Date: March 2025
      
    % Select the edge statistics for this repetition
    edge_stats_rep = GLM_stats.edge_stats;
    cluster_stats_rep = GLM_stats.cluster_stats;
    
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
                               'edge_stats', -edge_stats_rep, 'network_stats', -cluster_stats_rep, ...
                               'glm_parameters', GLM_stats.parameters, ...
                               'permuted_edge_data', -perm_data.permuted_data, ...
                               'permuted_network_data', -perm_data.permuted_network_data);
  

end