function [mask] = check_mask_validity(RP)
%% check_mask_validity
% Ensures RP.mask uses the canonical upper-triangular convention.
% Only applies to functional connectivity ('fc') data - other data types
% (e.g. voxel/activation) don't use edge triangles and are passed through untouched.

    mask = RP.mask;
    
    if ~strcmp(RP.data_set_map, 'fc')
        return
    end
    
    is_upper = isequal(mask, triu(mask, 1));
    is_lower = isequal(mask, tril(mask, -1));
    
    if is_upper
        % Already canonical - nothing to do
        return
    
    elseif is_lower
        % Lower triangular - mirror across diagonal to get upper
        mask = mask';
    
    else
        % Not cleanly triangular (e.g. entries on both sides, or a full
        % symmetric matrix). Take the upper triangle as the source of
        % truth.
        mask = triu(mask, 1);
    end

end