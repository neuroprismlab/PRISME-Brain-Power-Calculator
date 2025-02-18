function [X, Y, RP] = subs_data_from_score_condition(RP,  TestData, BrainData)

    switch RP.test_type

        case 't2'
            
            ref_cond = TestData.reference_condition;
    
            index_cond_1 = strcmp(TestData.score, test_data_score_set{1});
            index_cond_2 = strcmp(TestData.score, test_data_score_set{2});
    
            sub_ids_cond1 = BrainData.(ref_cond).sub_ids(index_cond_1);
            sub_ids_cond2 = BrainData.(ref_cond).sub_ids(index_cond_2);
            
            data_index_cond1 = ismember(BrainData.(ref_cond).sub_ids, sub_ids_cond1);
            data_index_cond2 = ismember(BrainData.(ref_cond).sub_ids, sub_ids_cond2);
    
            Yc1 = BrainData.(ref_cond).data(:, data_index_cond1);
            Yc2 = BrainData.(ref_cond).data(:, data_index_cond2);
        
            Y = [Yc1, Yc2];

    end 


end