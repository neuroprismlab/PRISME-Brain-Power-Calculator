function [data_set_name, data_set_base, data_set_map] = get_data_set_name(Dataset, Params)  
%% get_data_set_name
% **Description**
% Extracts dataset identifiers from the input structure, if the user
%

    if ~isfield(Params, 'output') || any(isnan(Params.output))
        data_set_base = Dataset.study_info.dataset;
        data_set_map = Dataset.study_info.map;
        
            % Check if Dataset.file_name has an extension
            [~, name, ext] = fileparts(Dataset.file_name);
            if ~isempty(ext)
                data_set_name = name;  % Use filename without extension
            else
                data_set_name = Dataset.file_name;  % Use as-is if no extension
            end
    else
        data_set_map = Dataset.study_info.map;
        data_set_base = Dataset.study_info.dataset;
        data_set_name = Params.output;
    end
    

end