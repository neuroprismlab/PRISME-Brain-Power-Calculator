function test_score_set = get_test_score_set(TestData)

    %% Extract unique scores (called set because of uniqueness) 
    if iscell(TestData.score)
        test_score_set = unique(TestData.score); 
        test_score_set(cellfun('isempty', test_data_score_set)) = [];
    else
        test_score_set = unique(TestData.score);
        test_score_set = num2cell(test_score_set);
    end

end
