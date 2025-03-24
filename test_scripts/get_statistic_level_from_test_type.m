function level = get_statistic_level_from_test_type(test_type, edge_level_tests, network_level_tests)
% Returns the statistic level ('edge' or 'network') for a given test type

    if ismember(test_type, edge_level_tests)
        level = 'edge';
    elseif ismember(test_type, network_level_tests)
        level = 'network';
    else
        error('Unrecognized test type: %s', test_type);
    end

end