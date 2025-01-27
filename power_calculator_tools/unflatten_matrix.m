function unflat_matrix = unflatten_matrix(flat_matrix, mask)

    % - reorder_matrix_by_atlas only applies to shen atlas
        % - full information before reordering
    temp_y = zeros(size(mask));
    temp_y(mask) = flat_matrix;
    % make full matrix, not upper or lower tri, before reordering
    % if all(mask(triu_mask)==0) | all(mask(tril_mask_without_diag)==0) % lower triangular
    unflat_matrix = temp_y + temp_y';

end
