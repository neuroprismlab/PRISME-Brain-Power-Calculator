function test_power_calculation_from_gt_and_data()

    if isfolder('./power_calculator_results/syn_power/')
        rmdir('./power_calculator_results/syn_power/', 's'); % 's' removes all subfolders and files
    end

    if isfolder('./power_calculator_results/ground_truth/syn_power/')
        rmdir('./power_calculator_results/ground_truth/syn_power/', 's'); % 's' removes all subfolders and files
    end

    if isfolder('./power_calculator_results/power_calculation/syn_power/')
        rmdir('./power_calculator_results/power_calculation/syn_power/', 's'); % 's' removes all subfolders and files
    end
    
    % Generate synthetic repetition (power) data
    generate_synthetic_power_data()

    % Generate synthetic ground truth (GT) data
    generate_synthetic_gt_data()

     % --- Define params ---
    Params = setparams(); % Get default parameters
    Params.save_directory = './power_calculator_results/';  % Directory for repetition data
    Params.gt_data_dir = './power_calculator_results/ground_truth/';  % GT data directory

    % Call function to load repetition and GT data
    [GtData, RepData] = load_rep_and_gt_results(Params, 'dataset', 'syn_power');
    
    Params.save_directory = [Params.save_directory, '/power_calculation/syn_power/'];

    power_calculation_tprs = @(x) summarize_tprs('calculate_tpr', x, GtData, ...
                                                 'save_directory', Params.save_directory);
    dfs_struct(power_calculation_tprs, RepData);

    test_final_power_results()

end