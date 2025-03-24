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
        method_instance = feval(STATS.statistic_type);
        
        % Check if the method has sub_methods
        has_submethods = isprop(method_instance, 'submethod');

        if has_submethods
            submethods = method_instance.submethod;
            submethods_struct = struct();
        
            for i = 1:numel(submethods)
                sub = submethods{i};
                full_name = [STATS.statistic_type '_' sub];
        
                % Compute only if:
                % - this submethod is selected, AND
                % - this repetition has not been completed yet
                if ismember(sub, RPc.Value.all_submethods) && ...
                   rep_id > RPc.Value.existing_repetitions.(full_name)
                    submethods_struct.(sub) = true;
                else
                    submethods_struct.(sub) = false;
                end
            end
        
            % Skip method if no submethods need computation
            if ~any(struct2array(submethods_struct))
                continue;
            end
        
            STATS.submethods = submethods_struct;
        
        else
            % No submethods — check if this method should run
            if ~ismember(STATS.statistic_type, RPc.Value.all_cluster_stat_types) || ...
               rep_id <= RPc.Value.existing_repetitions.(STATS.statistic_type)
                continue;
            end
        
            STATS.submethods = struct();  % Just for consistency
        end
        
        [pvals, pvals_neg] = p_value_from_method(STATS, GLM_stats);
        
        %% Assign pvals to results
        if isstruct(pvals) && isstruct(pvals_neg)
            submethods = fieldnames(pvals);
            for i = 1:numel(submethods)
                name = [STATS.statistic_type '_' submethods{i}];
                pvals_method.(name) = pvals.(submethods{i});
                pvals_method_neg.(name) = pvals_neg.(submethods{i});
            end
        elseif ~isstruct(pvals) && ~isstruct(pvals_neg)
            % Simple vector case
            pvals_method.(STATS.statistic_type) = pvals;
            pvals_method_neg.(STATS.statistic_type) = pvals_neg;
        else
            error("Mismatch between pvals and pvals_neg: one is a struct and the other is not.");
        end
    end
    
 
end
