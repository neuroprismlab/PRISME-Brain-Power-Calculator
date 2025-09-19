function [average_array, c_above_80] = ...
    average_heat_map_gen(method, n_subs, directory, varargin)   
%
% For the paper: Shitf - down to select for paste
% - average_heat_map_gen('Constrained_FDR',80,'/Users/f.cravogomes/Desktop/Pc_Res_Updated/SHOCK Paper Results/power_calculation/hcp_fc')
% - average_heat_map_gen('Size_cpp',500,'/Users/f.cravogomes/Desktop/Pc_Res_Updated/SHOCK Paper Results/power_calculation/abcd_100_sex/')

    % Create parser object
    p = inputParser;
    
    % Add required parameters
    addOptional(p, 'title', 'Heatmap');
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
 
        if get_sub_number_from_meta_data(data.meta_data) ~= n_subs
            continue
        end

        data_acrs_tasks{end + 1} = data.(method).tpr;
    end
    
    % Calculate average accross tasks 
    data_acrs_tasks = cat(3, data_acrs_tasks{:});
    average_array = mean(data_acrs_tasks, 3);

    c_above_80 = sum(average_array > 80, 'all');
    
    % Get unflattening function based on experiment mask
    mask = get_mask_from_meta_data(data.meta_data);
    unflat_matrix_fun = unflatten_matrix(mask);

    % Unflat
    if ~strcmp( ...
            get_stats_level_from_method_data(method, data.(method), data.meta_data), ...
            'network')

        try
            power_data = unflat_matrix_fun(average_array);
        catch
            error('File type lacking TPR - please check if it is truly a power results file')
        end
    
        if ~ismatrix(power_data)
            error('This script is for two dimensional heatmaps. The data was flattened to a non-2D array')
        end
        
    else
        edge_matrix = data.meta_data.rep_parameters.edge_groups;
        power_data = zeros(size(edge_matrix));

        for lin_id = 1:numel(edge_matrix)
            [row, col] = ind2sub(size(edge_matrix), lin_id);
            power_index = edge_matrix(row, col);
            
            if power_index == 0
                continue
            end
            power_data(row, col) = average_array(power_index);
            power_data(col, row) = average_array(power_index);
        end

    end
    
    edge_groups = get_edge_groups_from_meta_data(data.meta_data);
    edge_groups_line = edge_groups(1, :);

    
    previous_number = edge_groups_line(1);
    network_boundaries = cell(0);
    for i_e = 1:numel(edge_groups_line)
        current_number = edge_groups_line(i_e);
        
        % Zeroes don't count
        if current_number == 0
            continue;
        end
        
        % Zeroes indicate no boundaries so we ignore them
        if previous_number == 0
            previous_number = current_number;
        end

        if current_number ~= previous_number
            network_boundaries{end + 1} = i_e; %#ok
            previous_number = current_number;
        end
        
    end
    
    % Figure config
    figure('Position', [100, 100, 800, 700]);
    
    imagesc(power_data);
    
    c = colorbar;
    c.FontSize = 12;
    c.FontWeight = 'bold';
    c.Label.String = 'Power (%)';
    c.Label.FontSize = 14;
    c.Label.FontWeight = 'bold';
    
    title(heatmap_title, 'FontSize', 16, 'FontWeight', 'bold');
    
    xlabel(x_label, 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(y_label, 'FontSize', 14, 'FontWeight', 'bold');
    
    set(gca, 'FontSize', 11, 'FontWeight', 'normal');
    
    set(gca, 'LineWidth', 1.5);
    
    set(gca, 'Layer', 'top');
    set(gca, 'GridLineStyle', '-');
    set(gca, 'GridColor', [0.5, 0.5, 0.5]);
    set(gca, 'GridAlpha', 0.1);
    grid on;

    add_network_lines_from_starts(network_boundaries);
    
    heat_map_color = custom_colors('sci_blu');
    colormap(heat_map_color);
    
    axis square;  
    
    set(gca, 'TickDir', 'out');
    set(gca, 'Box', 'on');  

end


