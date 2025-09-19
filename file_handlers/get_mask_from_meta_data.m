function mask = get_mask_from_meta_data(meta_data)

    if isfield(meta_data, 'mask')
        mask = meta_data.mask;
        return;
    end 

    if isfield(meta_data, 'rep_parameters')
        mask = meta_data.rep_parameters.mask;
        return
    end

end