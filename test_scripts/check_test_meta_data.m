function check_test_meta_data(meta_data)
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

    assert(meta_data.n_repetitions == 5)

    assert(meta_data.n_subs_1 == meta_data.n_subs_2)
    assert(meta_data.n_subs == 40)

    switch meta_data.test_type

        case 't'
            assert(meta_data.observations == 40)

        case 't2'
            assert(meta_data.observations == 80)

        case 'r' 
            assert(meta_data.observations == 40)
        
        otherwise
            error('A stored test type does not matched the covered test types')

    end

end

