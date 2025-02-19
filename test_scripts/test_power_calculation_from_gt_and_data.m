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
     
    Study_Info.study_info.dataset = 'syn';
    Study_Info.study_info.map = 'power';

    % Call function to load repetition and GT data
    assignin('base', 'Study_Info', Study_Info);
    calculate_power;

    clear Study_Info
    
    test_final_power_results()

end