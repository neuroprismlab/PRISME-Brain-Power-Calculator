function average_network_based_power(varargin)
    
    % For paper, the function call
    % plot_aggregated_power_curve('/Users/f.cravogomes/Desktop/Pc_Res_Updated/SHOCK Paper Results/power_calculation/abcd_100_sex')
    % plot_aggregated_power_curve('/Users/f.cravogomes/Desktop/Pc_Res_Updated/SHOCK Paper Results/power_calculation/s_hcp_act_noble_1')

    %% Parse varargin
    % Create input parser
    p = inputParser;
    
    default_dir = '/Users/f.cravogomes/Desktop/Cloned Repos/Power_Calculator/power_calculator_results/power_calculation/tfce_power_comp';
    default_undesired_sub_numbers = {};
    default_map = map_tfce_comp;
    default_attribute_name = 'tpr';
    
     % Add optional parameter
    addParameter(p, 'dir', default_dir);
    addParameter(p, 'undesired_subject_numbers', default_undesired_sub_numbers);
    addParameter(p, 'map_function', default_map);
    addParameter(p, 'attribute_name_calculation', default_attribute_name)
  
    % Parse input
    parse(p, varargin{:});
    
    directory = p.Results.dir;
    undesired_subject_numbers = p.Results.undesired_subject_numbers;
    map_function = p.Results.map_function;
    attribute = p.Results.attribute_name_calculation;
    
    %% Check if input is a directory
    if ~isfolder(directory)
        error('Input must be a directory name')
    end
    %%%%% Config end %%%%%%%%%%%%%%%%%%%%%%%%%%%

end