function generate_synthetic_power_data()
%% generate_synthetic_power_data
% Generates synthetic power calculation data for testing the power calculator.
%
% This function creates synthetic brain data for the repetition files in the proper format.
% Each method contains:
%   - sig_prob: Sparse matrix with significance probabilities (1 - p-value)
%   - sig_prob_neg: Sparse matrix with negative significance probabilities
%   - meta_data: Contains level, parent_method, and is_permutation_based
%
% The function simulates a 25% power scenario by making every 4th repetition significant.
% The synthetic data is saved to a single file in the directory './power_calculator_results/syn_power/'.
%
% Dependencies:
%   - get_statistic_level_from_test_type: Determines the statistic level from the test type.
%   - name_file_from_meta_data: Constructs a filename based on meta_data.
%
% Notes:
%   - For edge-level tests, data is generated for a fixed number of edges.
%   - For network-level tests, data is generated for a fixed number of networks.

    % Directory where synthetic test file will be saved
    output_dir = './power_calculator_results/syn_power/';
    
    % Ensure directory exists
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    % Define test types and their parent methods
    test_types = {
        'Parametric_FWER', 'edge', 'Parametric', true;
        'Parametric_FDR', 'edge', 'Parametric', true;
        'Size', 'edge', 'Size', true;
        'TFCE', 'edge', 'TFCE', true;
        'Constrained_FWER', 'network', 'Constrained', true;
        'Constrained_FDR', 'network', 'Constrained', true;
    };
    % Format: {method_name, level, parent_method, is_permutation_based}
    
    % Extract just the method names for convenience
    method_names = test_types(:,1);
    
    % Set fixed number of elements and repetitions
    num_edges = 10;     % Number of edges for edge-level tests
    num_networks = 4;   % Number of networks for network-level tests
    n_repetitions = 20; % Number of repetitions for power calculation

    % Generate main meta_data for the file
    meta_data = struct();
    meta_data.dataset = 'syn';
    meta_data.map = 'power';
    meta_data.test = 'synthetic';
    meta_data.test_components = {'REST', 'TASK'};
    meta_data.subject_number = 40;
    meta_data.testing_code = 1;
    meta_data.method_list = method_names;
    meta_data.rep_parameters.data_dir = './syn_data.mat';
    meta_data.run_time = rand() * 10;
    
    % Add critical power calculation parameters
    meta_data.rep_parameters.pthresh_second_level = 0.05;
    meta_data.rep_parameters.n_repetitions = n_repetitions;

    % Generate filename based on meta_data
    filename = name_file_from_meta_data(meta_data, false);
    full_file = fullfile(output_dir, filename);
    
    % First save just the meta_data to create the file
    save(full_file, 'meta_data');

    % Loop through each test type and append to the file
    for i = 1:size(test_types, 1)
        method_name = test_types{i, 1};
        level = test_types{i, 2};
        parent_method = test_types{i, 3};
        is_permutation_based = test_types{i, 4};
        
        % Number of elements based on test level
        if strcmp(level, 'edge')
            num_elements = num_edges;
        else
            num_elements = num_networks;
        end
        
        % Create sparse matrices for p-values (stored as 1-p)
        % Initialize with non-significant values (p = 0.6, so 1-p = 0.4)
        sig_prob_data = sparse(num_elements, n_repetitions);
        sig_prob_neg_data = sparse(num_elements, n_repetitions);
        
        % Compute number of elements for 25% power
        significant_count = floor(num_elements * 0.25);
        
        % Set significant p-values for every 4th repetition
        for rep = 1:n_repetitions
            if mod(rep, 4) == 0  % Every 4th repetition has significant results
                % For positive effects, first set of elements are significant
                for idx = 1:significant_count
                    sig_prob_data(idx, rep) = 1.0;  % p-value of 0, so 1-p = 1.0
                end
                
                % For negative effects, second set of elements are significant
                for idx = (significant_count+1):(2*significant_count)
                    sig_prob_neg_data(idx, rep) = 1.0;  % p-value of 0, so 1-p = 1.0
                end
            else
                % For non-significant repetitions, set a few non-zero values for sparsity pattern
                % but still non-significant (e.g., p = 0.6 means 1-p = 0.4)
                if rand() > 0.5  % Randomly set some values for variety
                    random_indices = randperm(num_elements, floor(num_elements/3));
                    for idx = random_indices
                        sig_prob_data(idx, rep) = 0.4;  % p-value of 0.6, so 1-p = 0.4
                    end
                    
                    random_indices = randperm(num_elements, floor(num_elements/3));
                    for idx = random_indices
                        sig_prob_neg_data(idx, rep) = 0.4;  % p-value of 0.6, so 1-p = 0.4
                    end
                end
            end
        end
        
        % Create meta_data structure for this method
        method_meta_data = struct();
        method_meta_data.level = level;
        method_meta_data.parent_method = parent_method;
        method_meta_data.is_permutation_based = is_permutation_based;
        
        % Create a temporary variable with the method name
        sig_prob = sig_prob_data;
        sig_prob_neg = sig_prob_neg_data;
        
        % Use eval to save each method to the file
        save(full_file, 'method_meta_data', '-append');
        
        % Need to handle variable creation and saving differently to not overwrite
        eval([method_name ' = struct();']);
        eval([method_name '.sig_prob = sig_prob;']);
        eval([method_name '.sig_prob_neg = sig_prob_neg;']);
        eval([method_name '.meta_data = method_meta_data;']);
        
        % Save the method to the file
        eval(['save(full_file, ''' method_name ''', ''-append'');']);
    end

    fprintf('Synthetic power data file created: %s\n', full_file);
end