function flat_m = flat_matrix(unflat_matrix, mask)
    if isempty(unflat_matrix)
        flat_m = [];  % Return empty array for empty input
    else
        flat_m = unflat_matrix(mask);
    end

end
