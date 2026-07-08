function check_multivariate_group(RP)
%% check_multivariate_group
% Validates the multivariate grouping against the selected methods.
%   - If a multivariate method is selected, a grouping must exist.
%   - When a grouping exists, it must be n_groups x n_var so each column
%     corresponds to one variable (edge/voxel).
%
% **Author**: Fabricio Cravo

    has_group = ~isequaln(RP.multivariate_group, NaN);
    
    % A multivariate method needs a grouping to run
    if RP.has_mvm && ~has_group
        error('check_multivariate_group:missingGroup', ...
            ['A multivariate method was selected but no multivariate ' ...
            'grouping is available. Set RP.atlas_file or provide ' ...
            'RP.multivariate_group.']);
    end
    
    % No grouping and no multivariate method -> nothing to check
    if ~has_group
        return
    end
    
    % Grouping present -> column count must match n_var
    n_cols = size(RP.multivariate_group, 2);
    if n_cols ~= RP.n_var
        error('check_multivariate_group:sizeMismatch', ...
            ['Multivariate group has %d columns but RP.n_var = %d. ' ...
            'Each column must correspond to one variable (edge/voxel).'], ...
            n_cols, RP.n_var);
    end
end