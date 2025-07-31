function edge_based_tests(data_set_name, varargin)
%% edge_based_tests
% Runs automated tests for edge-level statistical methods on a given dataset.
%
% This function sets up the appropriate parameters, runs the power calculation
% workflow for edge-based methods, and verifies the output p-values and metadata
% to ensure expected behavior.
%
% Inputs:
%   - data_set_name: String containing the name of the test dataset (e.g., 'test_hcp_fc.mat')
%
% Dependencies:
%   - common_test_setup
%   - rep_cal_function
%   - unite_results_from_directory
%   - get_data_set_name
%   - get_task_name_for_test
%   - check_test_meta_data
%
% Notes:
%   - Designed for synthetic test datasets generated during testing workflows.
%   - Verifies that methods correctly detect simulated effects (rows 1-6) and ignore non-effects (rows 7-10).
%   - Validates metadata fields for consistency and correctness.
    
    % Default parameters are for legacy script reasons
    p = inputParser;
    addRequired(p, 'data_set_name');
    addParameter(p, 'stat_method_cell', {'Parametric', 'Size_cpp', 'Fast_TFCE_cpp'}, @iscell);
    addParameter(p, 'submethod_cell', {'FWER', 'FDR'}, @iscell);  % No validation
    addParameter(p, 'full_method_name_cell', {'Parametric_FWER', 'Parametric_FDR', 'Size_cpp', 'Fast_TFCE_cpp'}, ...
        @iscell);  % No validation
    addParameter(p, 'file_structure', 'full_file')

    parse(p, data_set_name, varargin{:});
    
    stat_method_cell = p.Results.stat_method_cell;
    submethod_cell = p.Results.submethod_cell;
    full_method_name_cell = p.Results.full_method_name_cell;
    file_structure = p.Results.file_structure;

    data_set = load(['./data/', data_set_name]);

    Params = common_test_setup(data_set_name);

    %% This test works with full_files only
    Params.subsample_file_type = file_structure;

    data_set_name = get_data_set_name(data_set, Params);

    Params.all_cluster_stat_types = stat_method_cell;
    Params.all_submethods = submethod_cell;

    rep_cal_function(Params)
    
    ResData = unite_results_from_directory('directory', ['./power_calculator_results/', data_set_name, '/']);
    
    if isempty(ResData) || (isstruct(ResData) && isempty(fieldnames(ResData)))
        error('No results found in the specified directory: %s', ['./power_calculator_results/', data_set_name, '/']);
    end
    
    task_name = get_task_name_for_test(data_set);
    for i = 1:length(full_method_name_cell)
        method = full_method_name_cell{i};

        % The query is based on how the dataset is created
        query = {'testing', data_set_name, task_name, method, 'subs_40'};
        
        %% Test regression results
        brain_data = getfield(ResData, query{:});
        

        % I think I need to add the power calculator scripts too - just to
        % make sure 

        % Ensure first row is all zeros
        error_effect = sprintf('Edge-level Test Failed in Dataset %s, Method %s: Effect not detected', ...
            data_set_name, method);
        error_non_effect = sprintf('Edge-Level Test Failed in Dataset %s, Method %s: Effect detected', ...
            data_set_name, method);

        % Check for significant p-values where an effect is expected (rows 1 to 6)
        switch file_structure
            
            case 'full_file'
                sig_vals = brain_data.sig_prob;

                for row = 1:6
                    assert(all(sig_vals(row, :) > 0.95), error_effect);
                end
        
                % Check for non-significant p-values where no effect is expected (rows 7 to 10)
                for row = 7:10
                    assert(all(sig_vals(row, :) <= 0.5), error_non_effect);
                end

            case 'compact_file'         
                sig_vals = brain_data.positives;

                % Check effect rows (1-6) have exactly 5 detections
                for row = 1:6
                    assert(sig_vals(row) == 5, error_effect);
                end
                
                % Check non-effect rows (7-10) have 0 detections
                for row = 7:10
                    assert(sig_vals(row) == 0, error_non_effect);
                end

            otherwise
                error('Not supported')
        end               

        %% Test meta-data results 
        query = {'testing', data_set_name, task_name, method, 'subs_40', 'meta_data'};

        meta_data = getfield(ResData, query{:});

        check_test_meta_data(meta_data)
    
    end

end
