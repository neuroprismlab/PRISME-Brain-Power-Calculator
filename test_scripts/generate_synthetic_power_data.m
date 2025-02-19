function generate_synthetic_power_data()
    % Directory where synthetic test files will be saved
    output_dir = './power_calculator_results/syn_power/';
    
    % Ensure directory exists
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    % Define test types based on whether they are edge-level or network-level
    edge_level_tests = {'Parametric_Bonferroni', 'Parametric_FDR', 'Size', 'TFCE'};
    network_level_tests = {'Constrained', 'Constrained_FWER'};

    % Set fixed number of edges and networks (arbitrary for synthetic testing)
    num_edges = 10;   % Example: 100 edges for edge-level tests
    num_networks = 4; % Example: 10 networks for network-level tests
    n_repetitions = 100; % Number of repetitions for power calculation

    % Compute split for 25% of elements
    split_25_edges = floor(num_edges * 0.25);
    split_25_networks = floor(num_networks * 0.25);

    % Loop through each test type
    for test_type = [edge_level_tests, network_level_tests]
        tt = test_type{1};  % Extract string

        % Generate mock brain_data structure
        brain_data = struct();

        if ismember(tt, edge_level_tests)
            % Edge-level test: p-values should match number of edges
            brain_data.edge_stats_all = randn(num_edges, n_repetitions);  
            brain_data.edge_stats_all_neg = randn(num_edges, n_repetitions);
            brain_data.cluster_stats_all = []; % Not used for edge tests
            brain_data.cluster_stats_all_neg = [];

            % Initialize arrays with non-significant values (>0.5)
            brain_data.pvals_all = 0.6 * ones(num_edges, n_repetitions);
            brain_data.pvals_all_neg = 0.6 * ones(num_edges, n_repetitions);

            % Ensure 25% power: In 25% of repetitions, p-value is set to zero (significant)
            for rep = 1:n_repetitions
                if mod(rep, 4) == 0 % Every 4th repetition should have significant results
                    brain_data.pvals_all([1, 2, 3], rep) = 0;  % Positive detections
                    brain_data.pvals_all_neg([4, 5], rep) = 0; % Negative detections
                end
            end

        elseif ismember(tt, network_level_tests)
            % Network-level test: p-values should match number of networks
            brain_data.edge_stats_all = []; % Not used for network tests
            brain_data.edge_stats_all_neg = [];
            brain_data.cluster_stats_all = randn(num_networks, n_repetitions);
            brain_data.cluster_stats_all_neg = randn(num_networks, n_repetitions);
            
            % Initialize arrays with non-significant values (>0.5)
            brain_data.pvals_all = 0.6 * ones(num_networks, n_repetitions);
            brain_data.pvals_all_neg = 0.6 * ones(num_networks, n_repetitions);

            % Ensure 25% power: In 25% of repetitions, p-value is set to zero (significant)
            for rep = 1:n_repetitions
                if mod(rep, 4) == 0 % Every 4th repetition should have significant results
                    brain_data.pvals_all(1:split_25_networks, rep) = 0;  
                    brain_data.pvals_all_neg(split_25_networks+1:2*split_25_networks, rep) = 0;
                end
            end
        end

        % Ensure mutual exclusivity: no index should be zero in both p-values
        invalid_indices = (brain_data.pvals_all == 0 & brain_data.pvals_all_neg == 0);
        brain_data.pvals_all(invalid_indices) = rand(sum(invalid_indices, 'all'), 1);
        
        % Generate mock meta_data
        meta_data = struct();
        meta_data.dataset = 'syn';
        meta_data.map = 'power';
        meta_data.test = 'synthetic';  % Placeholder test type
        meta_data.test_components = {'REST', 'TASK'};
        meta_data.omnibus = NaN;
        meta_data.subject_number = 40; % Single fixed subject number
        meta_data.testing_code = 1; % Indicator for test mode
        meta_data.test_type = tt;  % Critical test type distinction
        meta_data.run_time = rand() * 10; % Fake runtime
        
        % Add critical power calculation parameters
        meta_data.rep_parameters.pthresh_second_level = 0.05;  % FWER/FDR threshold
        meta_data.rep_parameters.n_repetitions = n_repetitions; % Number of repetitions

        % Generate filename
        filename = name_file_from_meta_data(meta_data, false);
        full_file = ['./power_calculator_results/syn_power/', filename];

        % Save synthetic data
        save(full_file, 'brain_data', 'meta_data');

    end

end