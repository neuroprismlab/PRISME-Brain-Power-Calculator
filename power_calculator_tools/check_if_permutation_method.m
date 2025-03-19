function is_permutation = check_if_permutation_method(RP)
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