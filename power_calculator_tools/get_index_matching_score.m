function [index_cond_1, index_cond_2] = get_index_matching_score(TestData_score, test_score_set)
    
    % Type cast to str to handle weird datatypes
    score_str = string(TestData_score);
    set_str = string(test_score_set);
        
    % Find indexes matching the condition
    index_cond_1 = score_str == set_str(1);
    index_cond_2 = score_str == set_str(2);

end