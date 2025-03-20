function [data_set_name, data_set_base, data_set_map] = get_data_set_name(Dataset)  
%% get_data_set_name
% **Description**
% Extracts dataset identifiers from the input structure, including the base 
% dataset name and map type (e.g., functional connectivity). Constructs the 
% full dataset name by combining both the dataset origin and the map type.
%
% **Inputs**
% - `Dataset` (struct): Contains study information with fields:
%   * `study_info.dataset` (string) – Base dataset name.
%   * `study_info.map` (string) – Dataset map identifier.
%
% **Outputs**
% - `data_set_name` (string) – Combined dataset name (`'dataset_map'`).
% - `data_set_base` (string) – Base dataset name.
% - `data_set_map` (string) – Dataset map identifier.
%
% **Example Usage**
% ```matlab
% Dataset.study_info.dataset = 'Experiment1';
% Dataset.study_info.map = 'MappingA';
% [name, base, map] = get_data_set_name(Dataset);
% % name = 'Experiment1_MappingA'
% ```
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025

    data_set_base = Dataset.study_info.dataset;
    data_set_map =  Dataset.study_info.map;
    data_set_name = strcat(Dataset.study_info.dataset, '_', Dataset.study_info.map);
    
end