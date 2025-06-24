function variable_type = get_variable_type(Dataset)
    
    if ~isfield(Dataset.study_info, 'map')
        error(['The dataset must contain a field in study_info named map that indicates if it is activation ' ...
            'or functional connectivity data'])
    end
    
    switch Dataset.study_info.map

        case 'fc'
            variable_type = 'edge';

        case 'act'
            variable_type = 'node';
        
        otherwise
            error('Variable type %s is not valid', Dataset.study_info.map)
        
    end

end