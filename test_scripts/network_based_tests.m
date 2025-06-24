function network_based_tests(data_set_name)
%% network_based_tests
% Runs automated tests for network-level statistical methods on a given dataset.
%
% This function executes the power calculation workflow for constrained (network-based)
% methods and verifies both the resulting p-values and metadata to ensure correctness.
%
% Inputs:
%   - data_set_name: String specifying the dataset to test (e.g., 'test_hcp_fc.mat')
%
% Notes:
%   - Applies only to constrained network-based methods such as Constrained_FWER and Constrained_FDR.
%   - Assumes the input dataset was constructed with two networks:
%       * First row (network 1) contains simulated effects (p < 0.05 expected).
%       * Second row (network 2) contains no effects (p > 0.5 expected).
%   - Also verifies metadata consistency using check_test_meta_data.
    
    data_set = load(['./data/', data_set_name]);

    Params = common_test_setup(data_set_name);
    
    data_set_name = get_data_set_name(data_set, Params);

    stat_method_cell = {'Constrained_cpp'};
    submethod_cell = {'FWER', 'FDR'};
    full_method_name_cell = {'Constrained_cpp_FWER', 'Constrained_cpp_FDR'};

    Params.all_cluster_stat_types = stat_method_cell;
    Params.all_submethods = submethod_cell;

    rep_cal_function(Params)
    
    ResData = unite_results_from_directory('directory', ['./power_calculator_results/', data_set_name, '/']);
    
    task_name = get_task_name_for_test(data_set);
    for i = 1:length(full_method_name_cell)
        method = full_method_name_cell{i};

        % The query is based on how the dataset is created
        query = {'testing', data_set_name, task_name, method, 'subs_40'};
    
        brain_data = getfield(ResData, query{:});
    
        sig_vals = brain_data.sig_prob;

        % I think I need to add the power calculator scripts too - just to
        % make sure 

        % Ensure first row is all zeros
        assert(all(sig_vals(1, :) > 0.95), 'Network-Level Test Failed: Effect not detected in first row');

        % Ensure second row is all ones
        assert(all(sig_vals(2, :) <= 0.5), 'Network-Level Test Failed: Effect detected in second row');


        %% Test meta-data results 
        query = {'testing', data_set_name, task_name, method, 'subs_40', 'meta_data'};

        meta_data = getfield(ResData, query{:});

        check_test_meta_data(meta_data)
        
    end

end