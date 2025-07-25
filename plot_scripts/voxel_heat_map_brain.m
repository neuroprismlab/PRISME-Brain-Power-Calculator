function voxel_heat_map = voxel_heat_map_brain(method, n_subs, directory, varargin)
%
%   Future note - I think the ploting scripts could be better managed,
%   currently they are developped to individually
%   However, I can see a point to directly updating them consistently
%  
%   Usage for paper:
%   - voxel_heat_map_brain('Size_Node_cpp',40,'/Users/f.cravogomes/Desktop/Pc_Res_Updated/power_calculation/s_hcp_act_noble_1')
     
    % Create parser object
    p = inputParser;
    
    % Add required parameters
    addOptional(p, 'title', 'Brain Heatmap');
    addOptional(p, 'xaxis_label', '');
    addOptional(p, 'yaxis_label', '');

    % Parse the inputs
    parse(p, varargin{:});

    % Access parsed values
    heatmap_title = p.Results.title;
    x_label = p.Results.xaxis_label;
    y_label = p.Results.yaxis_label;


    % Get files from directory 
    try
        files = dir(fullfile(directory, '*.mat'));
    catch
        error('Unable to open directory')
    end

    if isempty(files)
        error('No files detected or the path is not a directory')
    end
    
    % Str pattern - it is also verified in the metadata to avoid matching
    % substring issues
    n_files = numel(files);
    subs_str = ['subs_', num2str(n_subs)];
    
    % Get data from files 
    data_acrs_tasks = cell(0);
    for i_f = 1:n_files
        
        if ~contains(files(i_f).name, subs_str, 'IgnoreCase', true)
            continue
        end

        data = load(fullfile(files(i_f).folder, files(i_f).name));

        if data.meta_data.subject_number ~= n_subs
            continue
        end
        
        data_acrs_tasks{end + 1} = data.(method).tpr;
    end

    % Calculate average accross tasks 
    data_acrs_tasks = cat(3, data_acrs_tasks{:});
    average_array = mean(data_acrs_tasks, 3);
    
    % Here we have to recreate the struct used for the flat back to
    % spatial creator function
    Flat_creator = struct();
    Flat_creator.mask = data.meta_data.rep_parameters.mask;
    Flat_creator.n_var = data.meta_data.rep_parameters.n_var;
    Flat_creator.variable_type = 'node';
    
    % This function converts tpr data from flatenned to brain position
    [flat_to_spatial, ~] = create_spatial_flat_map(Flat_creator);

    % Check for three dimensions:
    if numel(flat_to_spatial{1}) ~= 3
        error('This script is designed for 3d brain heatmaps')
    end
    
    % Position voxels power in correct spots - get power_values
    voxel_heat_map = zeros(size(Flat_creator.mask));
    for i_f = 1:numel(average_array)
        
        [x, y, z] = deal(flat_to_spatial{i_f}{:});
        
        voxel_heat_map(x, y, z) = average_array(i_f);
    end
    power_values = voxel_heat_map(Flat_creator.mask);

    % Get all brain coordinates directly from the mask
    [x_l, y_l, z_l] = ind2sub(size(Flat_creator.mask), find(Flat_creator.mask));

    scatter3(x_l, y_l, z_l, 50, power_values, 'filled');
    colorbar;

end