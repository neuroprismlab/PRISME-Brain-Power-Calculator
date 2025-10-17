function multi_method_diff_heatmap_generation(varargin)
    
    % For paper, the function call
    % plot_aggregated_power_curve('/Users/f.cravogomes/Desktop/Pc_Res_Updated/SHOCK Paper Results/power_calculation/abcd_100_sex')
    % plot_aggregated_power_curve('/Users/f.cravogomes/Desktop/Pc_Res_Updated/SHOCK Paper Results/power_calculation/s_hcp_act_noble_1')

    %% Parse varargin
    % Create input parser
    p = inputParser;
    
    default_dir = '/Users/f.cravogomes/Desktop/Cloned Repos/Power_Calculator/power_calculator_results/power_calculation/tfce_power_comp';
    default_sub_number = 20;
    default_base_method = 'IC_TFCE_FC_cpp_dh25';
    % Don't forget the @ or it runs the function
    default_figure_function = @fig_tfce_comparison;
    
     % Add optional parameter
    addParameter(p, 'dir', default_dir);
    addParameter(p, 'sub_number', default_sub_number);
    addParameter(p, 'base_method', default_base_method);
    addParameter(p, 'figure_function', default_figure_function)
  
    % Parse input
    parse(p, varargin{:});
    
    directory = p.Results.dir;
    sub_number = p.Results.sub_number;
    base_method = p.Results.base_method;
    figure_function = p.Results.figure_function;
    
    %% Check if input is a directory
    if ~isfolder(directory)
        error('Input must be a directory name')
    end
    %%%%% Config end %%%%%%%%%%%%%%%%%%%%%%%%%%%

    file_structs = dir(fullfile(directory, '*.mat'));
    files = cell(length(file_structs), 1);
    for i = 1:length(file_structs)
        files{i} = fullfile(directory, file_structs(i).name);
    end
    
    % Get some data from example meta-data 
    ex_meta_data = load(files{1}).meta_data;
    unflat_function = unflatten_matrix(ex_meta_data.mask, 'variable_type', 'edge');
    methods = ex_meta_data.method_list;
    
    % Heat map storage
    store_heat_maps = zeros(numel(files), numel(methods), size(ex_meta_data.mask, 1), size(ex_meta_data.mask, 2));
    
    % Create a index for each method to store in the main datastructure
    map_method_index = containers.Map();
    m_idx = 1;
    map_method_index(base_method) = m_idx;
    for i_m = 1:numel(methods)
        method = methods{i_m};
        
        if strcmp(method, base_method)
            continue;
        else
            m_idx = m_idx + 1;
            map_method_index(method) = m_idx;
        end
      
    end
    
    
    % Process each file to calculate difference between heatmaps 
    i_file_sub = 1;
    for i_f= 1:numel(files)
        full_file = files{i_f};

        data = load(full_file);

        if data.meta_data.n_subs ~= sub_number
            continue
        end 
        
        try
            base_heatmap = unflat_function(data.(base_method).tpr);
            store_heat_maps(i_file_sub, 1, :, :) = base_heatmap;
        catch
            error('Base method not found in data')
        end
  
        for i_m = 1:numel(methods)
            method = methods{i_m};

            if strcmp(method, base_method)
                continue;
            end

            diff_heat_map = unflat_function(data.(method).tpr) - base_heatmap; 
            m_idx = map_method_index(method);
            store_heat_maps(i_file_sub, m_idx, :, :) = diff_heat_map;
        end

        i_file_sub = i_file_sub + 1;
    end
    store_heat_maps = store_heat_maps(1:i_file_sub-1, :, :, :);
    avg_heat_maps = squeeze(mean(store_heat_maps, 1));

    figure_data = struct();
    figure_data.avg_heat_maps = avg_heat_maps;
    figure_data.method_list = methods;
    figure_data.map_method_index = map_method_index;
    figure_data.base_method_name = base_method;

    figure_function(figure_data);

end

