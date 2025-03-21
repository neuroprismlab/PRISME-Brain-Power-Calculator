function is_permutation = check_if_permutation_method(RP)
%% check_if_permutation_method
% **Description**
% Determines whether any method specified in `RP.all_cluster_stat_types` requires 
% permutation-based computation. Returns `true` if permutation tests are needed, 
% otherwise returns `false`. If ground truth is being evaluated, permutations are 
% always skipped. If `RP.force_permute` is set to true, permutation is forced.
%
% **Inputs**
% - `RP` (struct): Configuration structure containing:
%   * `ground_truth` (logical): Whether to skip permutation logic entirely.
%   * `force_permute` (logical): If true, bypass automatic detection and force permutation mode.
%   * `all_cluster_stat_types` (cell array of strings): List of method names.
%
% **Outputs**
% - `is_permutation` (logical): True if at least one method is permutation-based.
%
% **Workflow**
% 1. Skip permutation if ground truth mode is active.
% 2. Return `true` if `force_permute` is enabled.
% 3. Loop through `all_cluster_stat_types`, dynamically instantiate each method,
%    and check if the class has a `permutation_based` property set to `true`.
% 4. Return early if any method is permutation-based.
%
% **Dependencies**
% - Each method in `RP.all_cluster_stat_types` must correspond to a class constructor.
%
% **Notes**
% - If a method class is missing or invalid, a warning is issued and skipped.
% - The `permutation_based` property must be defined in the class for this to work.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025

    %
    % This function determines whether at least one of the methods in
    % `RP.all_cluster_stat_types` requires precomputed permutations.
    %
    if RP.ground_truth
        is_permutation = false;
        return;
    end
    
    % If forcing permutation, return true immediately
    if RP.force_permute
        is_permutation = true;
        return;
    end

    % Check if any method in RP.all_cluster_stat_types has permutation_based = true
    is_permutation = false;
    for i = 1:length(RP.all_cluster_stat_types)
        method_name = RP.all_cluster_stat_types{i};
        try
            % Instantiate the class dynamically
            method_class = feval(method_name);

            % Check if the instantiated class has 'permutation_based' property
            if isprop(method_class, 'permutation_based') && method_class.permutation_based
                is_permutation = true;
                return;  % No need to check further, exit early
            end
        catch
            warning('Method %s not found or invalid. Skipping.', method_name);
        end
    end
end