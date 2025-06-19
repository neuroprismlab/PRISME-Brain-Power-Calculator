function [mask, n_var, n_nodes] = study_specific_mask(Dataset, Params, study)
    
    flag_no_local_mask = false;

    % For now, only activation studies with one contrast have specific
    % study masks
    if isfield(Dataset.outcome.(study), 'contrast') && numel(Dataset.outcome.(study).contrast) == 1 ...
        && ~isnan(Dataset.outcome.(study).contrast)
        contrast = Dataset.outcome.(study).contrast{1};
        
        if isfield(Dataset.brain_data.(contrast), 'mask')
            mask = Dataset.brain_data.(contrast).mask;
            n_var = sum(mask(:));
            n_nodes = size(mask, 1);
        else
            flag_no_local_mask = true;
        end

    else
        % For the reason above we return early
        flag_no_local_mask = true;
    end
    
    if flag_no_local_mask
        
        mask = Params.mask;
        n_var = Params.n_var;
        n_nodes = Params.n_nodes;

    end


end