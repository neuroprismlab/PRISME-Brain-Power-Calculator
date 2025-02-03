function test_final_power_results()
    % Directory containing the power result files
    power_results_dir = './test_power_calculator/power_calculation/';

    % List all power result files
    files = dir(fullfile(power_results_dir, '*.mat'));

    % Expected power percentage
    expected_power = 25; % 25% detection rate for true positives

    % Loop through each power result file
    for i = 1:numel(files)
        file_path = fullfile(files(i).folder, files(i).name);
        loaded_data = load(file_path); % Load power data
        
        % Extract power_data and meta_data
        power_data = loaded_data.power_data; 

        % Determine whether it's an edge-level or network-level test
        if length(power_data.tpr) == 10

            gt_file = './test_power_calculator/ground_truth/gt_synthetic_edge.mat';
            load(gt_file, 'brain_data');
            gt_data = brain_data.edge_stats_all; 
     
        elseif length(power_data.tpr) == 4

            gt_file = './test_power_calculator/ground_truth/gt_synthetic_network.mat';
            load(gt_file, 'brain_data');
            gt_data = brain_data.cluster_stats_all;
    
        else
            error('Unexpected tpr length in power_data. Check ground truth dimensions.');
        end

        % Identify ground truth indices for positive and negative effects
        gt_pos_indices = find(gt_data > 0);
        gt_neg_indices = find(gt_data < 0);

        % Retrieve computed power values
        computed_tpr = power_data.tpr;

        % **Assertion 1: Power values at true positive locations should be 25%**
        assert(all(abs(computed_tpr(gt_pos_indices) - expected_power) < 1e-5), ...
            sprintf('Mismatch in power values for positive indices in test: %s', files(i).name));

        assert(all(abs(computed_tpr(gt_neg_indices) - expected_power) < 1e-5), ...
            sprintf('Mismatch in power values for negative indices in test: %s', files(i).name));

        % **Assertion 2: No power detected outside of expected true positive locations**
        false_positive_indices = setdiff(1:length(computed_tpr), [gt_pos_indices; gt_neg_indices]);
        assert(all(computed_tpr(false_positive_indices) == 0), ...
            sprintf('False positives detected in test: %s', files(i).name));

    end
    
end

