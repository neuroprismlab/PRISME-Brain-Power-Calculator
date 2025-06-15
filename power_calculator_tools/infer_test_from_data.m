function [RP, test_type_origin] = infer_test_from_data(RP, TestData, BrainData)
%% infer_test_from_data
% **Description**
% Infers the type of statistical test to be used (e.g., correlation, paired t-test, 
% unpaired t-test) based on the structure and content of `TestData` and `BrainData`. 
% It also sets the appropriate fields in the `RP` structure accordingly.
%
% **Inputs**
% - `RP` (struct): Experiment configuration structure, updated with test type info.
% - `TestData` (struct): Contains test score or contrast information for the sample.
% - `BrainData` (struct): Contains subject IDs under each condition.
%
% **Outputs**
% - `RP` (struct): Updated structure with:
%   * `test_type` – Inferred test type ('t', 't2', 'r').
%   * `nbs_test_stat` – Corresponding test name for use with NBS tools.
%   * `sub_ids_cond1`, `sub_ids_cond2` – Subject IDs for condition grouping.
% - `test_type_origin` (string): Indicates the origin of the inference 
%   ('score_cond' or 'contrast').
%
% **Workflow**
% 1. Check the nature of `TestData.score` or `TestData.contrast`:
%    - If numeric and continuous → correlation test (`r`)
%    - If two categorical values → paired (`t`) or unpaired (`t2`) test
%    - If contrast field is provided → paired or unpaired depending on group overlap
% 2. Count overlapping and unique subjects between conditions to decide between `t` and `t2`.
% 3. Assign appropriate `nbs_test_stat` and store test metadata in `RP`.
%
% **Dependencies**
% - `get_test_score_set.m`
%
% **Notes**
% - This function will error out if the contrast is invalid or inference fails.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025

    % initialize with default values in case there 
    test_type = 'unknown';
    sub_ids_cond1 = [];
    sub_ids_cond2 = [];
    
    test_score_set = get_test_score_set(TestData);

    if length(test_score_set) == 1 && ~isnan(test_score_set)
        % if all scores are equal to the same number - t test
        test_type = 't';
    
    elseif all(cellfun(@isnumeric, test_score_set)) && length(test_score_set) > 2
        % if score is continuous -> r
        test_type_origin = 'score_cond';
        test_type = 'r';
    
    elseif length(test_score_set) == 2

        test_type_origin = 'score_cond';
        % if two unique entries in score -> t (paired) or t2

        % Are the subids always in outcomes? For the hpc one, we have
        % NaN and it is likely a t2 test
        index_cond_1 = strcmp(TestData.score, test_score_set{1});
        index_cond_2 = strcmp(TestData.score, test_score_set{2});

        sub_ids_cond1 = BrainData.(TestData.reference_condition).sub_ids(index_cond_1);
        sub_ids_cond2 = BrainData.(TestData.reference_condition).sub_ids(index_cond_2);
        
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
                test_type_origin = 'contrast';
                test_type = 't';

            elseif length(TestData.contrast) == 2
                % if two conditions -> t (paired) or t2
                
                sub_ids_cond1 = BrainData.(TestData.contrast{1}).sub_ids;
                sub_ids_cond2 = BrainData.(TestData.contrast{2}).sub_ids;
                
                %% TODO: Divided by the two - focus on group sizes
                n_equal = numel(intersect(sort(sub_ids_cond1), sort(sub_ids_cond2)));
                n_unique = numel(setxor(sub_ids_cond1, sub_ids_cond2));  
                
                if n_equal >= n_unique 
                    test_type_origin = 'contrast';
                    test_type = 't';        
                else
                    test_type_origin = 'contrast';
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
            RP.nbs_test_stat = 'onesample'; 

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