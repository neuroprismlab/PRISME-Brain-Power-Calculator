function test_power_calculation_from_gt_and_data()
%% test_power_calculation_from_gt_and_data
% Runs an integrated test of the power calculator by generating synthetic
% repetition data and synthetic ground-truth data, then executing the power
% calculation workflow and validating the final results.
%
% Outputs:
%   - None (the function uses internal assertions to validate outputs).
%
% Workflow:
%   1. Remove existing synthetic output directories to ensure a clean test environment.
%   2. Generate synthetic repetition data via generate_synthetic_power_data.
%   3. Generate synthetic ground-truth data via generate_synthetic_gt_data.
%   4. Define a minimal Study_Info structure with dataset and map identifiers.
%   5. Call calculate_power to run the power calculation workflow.
%   6. Execute test_final_power_results to validate the final power estimates.
%
% Dependencies:
%   - generate_synthetic_power_data
%   - generate_synthetic_gt_data
%   - calculate_power
%   - test_final_power_results
%
% Notes:
%   - Designed for internal testing of the integrated power calculation framework.
%   - Output directories are cleared at the start to prevent interference from previous runs.

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
    Params = setparams();
    Params.output = 'syn_power';
    calculate_power(Params);

    clear Study_Info
    
    test_final_power_results()

end