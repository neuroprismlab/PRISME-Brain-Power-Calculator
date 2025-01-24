function RP = infer_test_from_data(RP, TestData, BrainData)
    %
    % - Test type issues - load HPC 
    % Should more tests be added?
    % 

    % initialize with default values in case there 
    test_type = 'unknown';
    sub_ids_cond1 = [];
    sub_ids_cond2 = [];

    if length(unique(TestData.score)) == 1 && ~isnan(TestData.score)
        % if all scores are equal to the same number - t test
        test_type = 't';
    
    elseif isa(TestData.score, 'double') && length(unique(TestData.score)) > 2
        % if score is continuous -> r
   
        test_type = 'r';
    
    elseif length(unique(TestData.score)) == 2
        % if two unique entries in score -> t (paired) or t2
        
        % if both "conditions" of the score have the same sub ids -> t; otherwise t2
        unique_conditions = unique(test_data.score);

        % Are the subids always in outcomes? For the hpc one, we have
        % NaN and it is likely a t2 test
        sub_ids_cond1 = test.sub_ids(test_type.score == unique_conditions(1));
        sub_ids_cond2 = test.sub_ids(test_type.score == unique_conditions(2));
        
        %% TODO: Divided by the two - focus on group sizes
        n_equal = numel(intersect(sort(sub_ids_cond1), sort(sub_ids_cond2)));
        n_unique = numel(setxor(sub_ids_cond1, sub_ids_cond2));
 
        if n_equal >= n_unique
            test_type = 't';
        else
            test_type = 't2';
        end
            
    elseif iscell(TestData.contrast)
        % if contrast provided -> t or t2
        
        if ~isnan(TestData.contrast{1})

            if length(TestData.contrast) == 1
                % single condition in contrast -> t
       
                test_type = 't';

            elseif length(TestData.contrast) == 2
                % if two conditions -> t (paired) or t2
                
                sub_ids_cond1 = BrainData.(TestData.contrast{1}).sub_ids;
                sub_ids_cond2 = BrainData.(TestData.contrast{2}).sub_ids;
                
                %% TODO: Divided by the two - focus on group sizes
                n_equal = numel(intersect(sort(sub_ids_cond1), sort(sub_ids_cond2)));
                n_unique = numel(setxor(sub_ids_cond1, sub_ids_cond2));  
                
                if n_equal >= n_unique       
                    test_type = 't';        
                else
                    test_type = 't2';             
                end

            else 
                error('Contrast provided, but more than two conditions given. Provide one or two conditions.') 
            end

        else
            error('Contrast provided but is NaN. Rename contrast to match relevant brain condition.')
        end

    else
        error('Could not infer test type. May be categorical.')
    end

    %% TODO add the test for r 
    switch test_type
        
        case 't'
            RP.nbs_test_stat = 'onesample';

        case 't2'
             RP.nbs_test_stat = 't-test';

        case 'pt'
            RP.nbs_test_stat = 't-test';
        
        case 'r'
            error('Not implemented yet')

    end
    
    % this error might not be rechable, but it's here to avoid
    % assigning unknow to test_type_list
    if strcmp(test_type, 'unknown')
        error('The code was unable to infer the test %s', t);
    end
    
    RP.test_type = test_type;
    RP.sub_ids_cond1 = sub_ids_cond1;
    RP.sub_ids_cond2 = sub_ids_cond2;


end 