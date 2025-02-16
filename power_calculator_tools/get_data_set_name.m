function [data_set_name, data_set_base, data_set_map] = get_data_set_name(Study_Info)
    
    data_set_base = Study_Info.dataset;
    data_set_map =  Study_Info.map;
    data_set_name = strcat(Study_Info.dataset, '_', Study_Info.map);
end