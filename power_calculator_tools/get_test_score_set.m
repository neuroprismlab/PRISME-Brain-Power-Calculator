function test_score_set = get_test_score_set(TestData)

    %% Extract unique scores (called set because of uniqueness) 
    if iscell(TestData.score)
        test_score_set = unique(TestData.score); 
        test_score_set(cellfun('isempty', test_score_set)) = []; % Remove empty cells
    else
        test_score_set = unique(TestData.score);
        test_score_set(isnan(test_score_set)) = []; % Remove NaNs from numeric data
        test_score_set = num2cell(test_score_set); % Convert numeric to cell for uniformity
    end

end
