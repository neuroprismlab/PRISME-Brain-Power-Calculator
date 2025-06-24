function generate_synthetic_gt_data()
%% generate_synthetic_gt_data
% Generates synthetic ground truth data for power calculation testing.
%
% This function creates and saves synthetic data representing ground-truth
% outcomes for both edge-level and network-level tests in the new format.
% 
% New Format:
% The file contains four top-level variables:
% - Ground_Truth: A simple method struct to maintain file structure
% - edge_level_stats: Array with values indicating positive/negative effects for edges
% - network_level_stats: Array with values indicating positive/negative effects for networks
% - meta_data: File-level metadata
%
% Outputs:
%   - No direct output; the synthetic ground truth data is saved as a MATLAB file
%     in the './power_calculator_results/ground_truth/syn_power/' directory.
%
% Dependencies:
%   - name_file_from_meta_data.m

    % Directory where synthetic ground truth files will be saved
    output_dir = './power_calculator_results/ground_truth/syn_power/';
    
    % Ensure directory exists
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    % Set fixed number of edges and networks (same as the test data)
    num_edges = 10;   % Example: 10 edges for edge-level tests
    num_networks = 4; % Example: 4 networks for network-level tests

    % Hard-code split points instead of rounding
    split_25_edges = 2;  % First 2 edges (20% of 10)
    split_50_edges = 4;  % First 4 edges (40% of 10)

    split_25_networks = 1;  % First 1 network (25% of 4)
    split_50_networks = 2;  % First 2 networks (50% of 4)

    % Create file-level meta_data
    meta_data = struct();
    meta_data.dataset = 'syn';
    meta_data.map = 'power';
    meta_data.test = 'synthetic';  % Placeholder test type
    meta_data.test_components = {'REST', 'TASK'};
    meta_data.subject_number = 40; % Fixed subject number for testing
    meta_data.testing_code = 1; % Indicator for test mode
    meta_data.run_time = rand() * 10; % Fake runtime
    meta_data.date = '1990-04-27';
    meta_data.method_list = {'Ground_Truth'}; % Only one method
    meta_data.rep_parameters.data_dir = './syn_data.mat';

    % Generate filename
    filename = name_file_from_meta_data(meta_data, true);
    full_file = fullfile(output_dir, filename);
    
    % Create edge and network level stats arrays
    % ----- Edge-Level Statistics -----
    edge_level_stats = zeros(num_edges, 1);

    % Assign 25% of edges as positive true positives
    edge_level_stats(1:split_25_edges) = abs(randn(split_25_edges, 1)) + 1e-5;
    
    % Assign next 25% of edges as negative true positives
    edge_level_stats(split_25_edges+1:split_50_edges) = ...
        -abs(randn(split_50_edges - split_25_edges, 1)) - 1e-5;

    % ----- Network-Level Statistics -----
    network_level_stats = zeros(num_networks, 1);

    % Assign 25% of networks as positive true positives
    network_level_stats(1:split_25_networks) = abs(randn(split_25_networks, 1)) + 1e-5;
    
    % Assign next 25% of networks as negative true positives
    network_level_stats(split_25_networks+1:split_50_networks) = ...
        -abs(randn(split_50_networks - split_25_networks, 1)) - 1e-5;
        
    % Create a simple Ground_Truth method struct 
    % (just for structure consistency, no significance data needed)
    Ground_Truth = struct();
    
    % Create method-specific meta_data
    method_meta_data = struct();
    method_meta_data.level = 'edge'; % Default to edge level
    method_meta_data.parent_method = 'Ground_Truth';
    method_meta_data.is_permutation_based = true;
    
    % Assign to the Ground_Truth structure
    Ground_Truth.meta_data = method_meta_data;
    
    % Save all variables to the file
    save(full_file, 'meta_data', 'edge_level_stats', 'network_level_stats', 'Ground_Truth');
    
    fprintf('Synthetic ground truth data file created: %s\n', full_file);

end