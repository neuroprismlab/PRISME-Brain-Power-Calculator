function [mvg_group, n_groups_mvm] = set_multivariate_group(RP)

    % Explicit matrix supplied -> use as-is
    if ~isequaln(RP.multivariate_group, NaN)
        mvg_group = RP.multivariate_group;
        n_groups_mvm = size(mvg_group, 1);
        return
    end

    % No atlas / no groups -> nothing to build
    if isempty(RP.edge_groups) || RP.n_networks == 0
        mvg_group = NaN;
        n_groups_mvm = 0;
        return
    end

    % Reuse the same flatten that builds Y's rows -> guaranteed alignment
    edge_labels = RP.flat_matrix_fun(RP.edge_groups);   % same order as Y rows
    edge_labels = edge_labels(:)';
    group_ids   = unique(edge_labels(edge_labels > 0)); % drop 0 = unassigned
    mvg_group   = sparse(group_ids(:) == edge_labels);        % n_groups x n_edges logical
    n_groups_mvm = numel(group_ids);

end