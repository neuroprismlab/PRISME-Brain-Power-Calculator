function [data_set_name, data_set_base, data_set_map] = get_data_set_name(Dataset, Params)  
%% get_data_set_name
% **Description**
% Extracts dataset identifiers from the input structure, if the user
%

    if ~isfield(Params, 'dataset_name') || isnan(Params.dataset_name)
        data_set_base = Dataset.study_info.dataset;
        data_set_map =  Dataset.study_info.map;
        data_set_name = strcat(Dataset.study_info.dataset, '_', Dataset.study_info.map);
    else
        data_set_name = Params.data_set;
    
    end
    
end