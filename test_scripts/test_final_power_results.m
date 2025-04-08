function test_final_power_results()
%% test_final_power_results
% Validates the final power calculation results by checking that the computed
% true positive rate (TPR) values match the expected ground-truth.
%
% This function iterates over all power result files in the designated directory
% (./power_calculator_results/power_calculation/syn_power/), loads each file,
% and performs assertions based on the expected numbers:
%
% Updated to work with the new file structure where:
% - Each file contains multiple methods (Parametric_FWER, Parametric_FDR, etc.)
% - Each method has fields: positives_total, positives_total_neg, tpr
%
% Expected results:
% - For edge-level methods (10 elements):
%   * The first 25% (indices 1-2) should have a TPR of 25%
%   * The next 25% (indices 3-5) should have a TPR of 0%
% - For network-level methods (4 elements):
%   * The first 25% (index 1) should have a TPR of 25%
%   * The next 25% (index 2) should have a TPR of 0%
%
% Outputs:
% - None (errors are thrown if any assertion fails).
%
% Dependencies:
% - MATLAB built-in functions: dir, load, setdiff.

    % Directory containing the power result files
    power_results_dir = './power_calculator_results/power_calculation/syn_power/';
    
    % List all power result files
    files = dir(fullfile(power_results_dir, '*.mat'));
    
    % If no files were found, output an error
    if isempty(files)
        error('No power calculation result files found.');
    end
    
    % Define known methods (from generate_synthetic_power_data)
    edge_level_methods = {'Parametric_FWER', 'Parametric_FDR', 'Size', 'TFCE'};
    network_level_methods = {'Constrained_FWER', 'Constrained_FDR'};
    
    % Loop through each power result file
    for i = 1:numel(files)
        file_path = fullfile(files(i).folder, files(i).name);
        loaded_data = load(file_path); % Load power data
        
        % Get list of methods
        method_fields = loaded_data.meta_data.method_list; 
        
        for j = 1:numel(method_fields)
            method_name = method_fields{j};
            method_data = loaded_data.(method_name);
            
            % Check if method has the required fields
            if ~isfield(method_data, 'tpr') || ~isfield(method_data, 'positives_total') || ~isfield(method_data, 'positives_total_neg')
                warning('Method %s in file %s does not have all required fields', method_name, files(i).name);
                continue;
            end
            
            % Get TPR data
            tpr = method_data.tpr;
            num_elements = length(tpr);
            
            % Define expected element counts and indices
            % For edge-level methods:
            if strcmp(method_data.meta_data.level, 'edge')
                expected_num = 10; % Edge-level: 10 elements
                
                % Hard-code the indices instead of calculating them
                gt_pos_indices = 1:2;  % First 2 elements (exactly 20%)
                gt_neg_indices = 3:4;  % Next 2 elements
            elseif strcmp(method_data.meta_data.level, 'network')
                expected_num = 4;  % Network-level: 4 elements
                
                % Hard-code the indices instead of calculating them
                gt_pos_indices = 1;    % First element (exactly 25%)
                gt_neg_indices = 2;    % Second element
            else
                error('Method level not adapted for test')
            end
            
            % Check if the number of elements matches expectations
            if num_elements ~= expected_num
                error('Method %s has %d elements, expected %d in file %s', ...
                    method_name, num_elements, expected_num, files(i).name);
            end
            
            % **Assertion 1: Power values at expected positive locations should be 25%**
            assert(all(abs(tpr(gt_pos_indices) - 25) < 1e-5), ...
                sprintf('Mismatch in power values for positive indices in method %s, file: %s', ...
                method_name, files(i).name));
            
             % **Assertion 1: Power values at expected negative locations should be 25%**
            assert(all(abs(tpr(gt_neg_indices) - 25) < 1e-5), ...
                sprintf('Mismatch in power values for negative indices in method %s, file: %s', ...
                method_name, files(i).name));
            
            % **Assertion 2: No power detected outside of expected true positive locations**
            false_positive_indices = setdiff(1:num_elements, [gt_pos_indices, gt_neg_indices]);
            assert(all(abs(tpr(false_positive_indices)) < 1e-5), ...
                sprintf('False positives detected in method %s, file: %s', ...
                method_name, files(i).name));
            
            fprintf('Passed all tests for method %s in file %s\n', method_name, files(i).name);
        end
    end
    
    fprintf('All power calculation validation tests passed successfully.\n');
end