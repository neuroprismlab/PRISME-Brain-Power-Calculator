 function average_network_based_power(varargin)
    % For paper, the function call
    % plot_aggregated_power_curve('/Users/f.cravogomes/Desktop/Pc_Res_Updated/SHOCK Paper Results/power_calculation/abcd_100_sex')
    % plot_aggregated_power_curve('/Users/f.cravogomes/Desktop/Pc_Res_Updated/SHOCK Paper Results/power_calculation/s_hcp_act_noble_1')
    
    %% Parse varargin
    % Create input parser
    p = inputParser;
    default_dir = '/Users/f.cravogomes/Desktop/Pc_Res_Updated/TFCE Paper Results/tfce_voxel_power_comp/power_calculation/';
    default_undesired_sub_numbers = {};
    default_map = map_tfce_comp;
    default_attribute_name = 'tpr';
    default_top_k = 10;
    
    % Add optional parameter
    addParameter(p, 'dir', default_dir);
    addParameter(p, 'undesired_subject_numbers', default_undesired_sub_numbers);
    addParameter(p, 'map_function', default_map);
    addParameter(p, 'attribute_name_calculation', default_attribute_name)
    addParameter(p, 'top_k', default_top_k)
    
    % Parse input
    parse(p, varargin{:});
    directory = p.Results.dir;
    undesired_subject_numbers = p.Results.undesired_subject_numbers;
    map = p.Results.map_function;
    attribute = p.Results.attribute_name_calculation;
    top_k = p.Results.top_k;
    
    %% Check if input is a directory
    if ~isfolder(directory)
        error('Input must be a directory name')
    end
    
    %%%%% Config end %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Although named edge, this script works for voxels as well
    meta_data_map = containers.Map();

    file_structs = dir(fullfile(directory, '*.mat'));
    files = cell(length(file_structs), 1);
    for i = 1:length(file_structs)
        files{i} = fullfile(directory, file_structs(i).name);
    end
    num_files = numel(files);
    
    % Get all meta data
    for i = 1:num_files
        file_data = load(files{i});
        meta_data_map(files{i}) = file_data.meta_data;
    end
    
    study_map = anp_map_attribute_to_index(values(meta_data_map), ...
        @(md) md.study_name);

    subject_map = anp_map_attribute_to_index(values(meta_data_map), ...
        @(x) get_sub_number_from_meta_data(x));
       
    
    file_data = load(files{1});
    edge_groups = get_edge_groups_from_meta_data(file_data.meta_data);
    mask = get_mask_from_meta_data(file_data.meta_data);
    variable_type = get_variable_type_from_meta_data(file_data.meta_data);
    flat_matrix_fun = create_flat_function(mask, 'variable_type', variable_type);
    flat_edge_groups = flat_matrix_fun(edge_groups);
    num_networks = max(flat_edge_groups);
 
     
    % Initialize 4D tensor: [study, subject, method, network]
    results_tensor = zeros(length(study_map), length(subject_map), ...
        length(map.display), num_networks);

    for i = 1:num_files
        file_data = load(files{i});
        study_idx = study_map(file_data.meta_data.study_name);
        subject_idx = subject_map(string( ...
            get_sub_number_from_meta_data(file_data.meta_data)));

         % For each method
        method_list = file_data.meta_data.method_list;
        for j = 1:length(method_list)
            method_name = method_list{j};
            method_display_name = map.display(method_list{j});
            method_idx = map.order(method_display_name);
            avg_power = anp_average_power_network(file_data, method_name, attribute, ...
                                                  flat_edge_groups, num_networks);
            
            % Assign to tensor - the : in 4th dimension stores the entire avg_power array
            results_tensor(study_idx, subject_idx, method_idx, :) = avg_power;
        end

    end

    results_top_k = anp_n_powered_tensor(results_tensor, top_k);

    anp_plot_results_histogram(results_top_k, subject_map, map, top_k);

end