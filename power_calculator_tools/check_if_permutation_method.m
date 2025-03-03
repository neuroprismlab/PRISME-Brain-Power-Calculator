function is_permutation = check_if_permutation_method(RP)
    %
    % This function determines whether at least one of the methods in
    % `RP.all_cluster_stat_types` requires precomputed permutations.
    %

    % List of methods that require permutations
    permutation_methods = {'Size', 'TFCE', 'Constrained', 'Constrained_FWER', 'Omnibus'};

    % If forcing permutation, return true immediately
    if RP.force_permute
        is_permutation = true;
        return;
    end
    
    % Check if **any** method in RP.all_cluster_stat_types requires permutations
    if any(ismember(permutation_methods, RP.all_cluster_stat_types))
        is_permutation = true;
        return;
    end

    % Default case: no permutation needed
    is_permutation = false;
end