function check_test_meta_data(meta_data, method)
%% check_test_meta_data
% Validates the metadata produced by the power calculator test pipeline.
%
% This function ensures that the metadata fields match expected values for
% a standard test configuration, including subject count, repetition count,
% and test type-specific settings.
%
% Inputs:
%   - meta_data: Struct containing metadata saved during the power calculator run.
%   - method: Name of the statistical method used (e.g., 'TFCE').
%
% Notes:
%   - Designed for internal testing consistency checks.
%   - Assumes a fixed test configuration of 20 repetitions with 40 subjects.
%   - Verifies both the main test configuration and nested parameters under
%     'rep_parameters'.

    assert(meta_data.rep_parameters.n_repetitions == 20)

    assert(meta_data.rep_parameters.n_subs_subset_c1 == meta_data.rep_parameters.n_subs_subset_c2)
    assert(meta_data.rep_parameters.n_subs_subset_c1 == meta_data.rep_parameters.n_subs_subset)
    assert(meta_data.rep_parameters.n_subs_subset_c1 == 40)
    assert(strcmp(meta_data.significance_method, method))

    switch meta_data.rep_parameters.test_type

        case 't'
            assert(strcmp(meta_data.rep_parameters.nbs_test_stat,'onesample'))
            assert(meta_data.rep_parameters.observations == 40)

        case 't2'
            assert(strcmp(meta_data.rep_parameters.nbs_test_stat,'ttest'))
            assert(meta_data.rep_parameters.observations == 80)

        case 'r' 
            assert(strcmp(meta_data.rep_parameters.nbs_test_stat,'onesample'))
            assert(meta_data.rep_parameters.observations == 40)
        
        otherwise
            error('A stored test type does not matched the covered test types')

    end

end

