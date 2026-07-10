function [X, Y, RP] = subs_data_from_score_condition(RP,  TestData, BrainData, test_name)
%% subs_data_from_score_condition
% **Description**
% Extracts and formats subject-level data (`X`, `Y`) for statistical analysis 
% based on score-based conditions. Supports both unpaired t-tests (`t2`) and 
% correlation analyses (`r`), and updates the experiment configuration structure (`RP`).
%
% **Inputs**
% - `RP` (struct): Configuration structure containing test metadata, including `test_type`.
% - `TestData` (struct): Includes subject scores, IDs, and the reference condition name.
% - `BrainData` (struct): Brain data and subject IDs organized by condition.
% - `test_name` (string): Label to identify the test in outputs.
%
% **Outputs**
% - `X` (matrix): Design matrix for statistical testing.
% - `Y` (matrix): Data matrix with subjects as columns.
% - `RP` (struct): Updated configuration structure with subject information and test size.
%
% **Workflow**
% - For `t2` (two-sample t-test):
%   1. Identify subjects belonging to each score group.
%   2. Retrieve brain data for both groups.
%   3. Build design matrix `X` with group indicators.
% - For `r` (correlation):
%   1. Remove NaNs from scores.
%   2. Extract brain data corresponding to valid subjects.
%   3. Use scores directly as `X`.
%
% **Dependencies**
% - `get_test_score_set.m`
%
% **Notes**
% - The terms "rest" and "task" are used generically for the two groups.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025
    
    test_score_set = get_test_score_set(TestData);
    RP.test_name = test_name;

    switch RP.test_type

        case 't2'
           
            ref_cond = TestData.reference_condition;
            
            [index_cond_1, index_cond_2] = get_index_matching_score(TestData.score, ...
                test_score_set);

            % I call c1 one rest and c2 task for consitency - even though
            % they might not be task and rest
            RP.sub_ids_rest = TestData.sub_ids(index_cond_1);
            RP.sub_ids_task = TestData.sub_ids(index_cond_2);
    
            index_b_data_c1 = ismember(BrainData.(ref_cond).sub_ids, RP.sub_ids_rest);
            index_b_data_c2 = ismember(BrainData.(ref_cond).sub_ids, RP.sub_ids_task);
    
            Yc1 = BrainData.(ref_cond).data(:, index_b_data_c1);
            Yc2 = BrainData.(ref_cond).data(:, index_b_data_c2);
        
            Y = [Yc1, Yc2];
    
            % Get the number of subjects for each condition
            n_subs_1 = nnz(index_b_data_c1);   % = size(Yc1, 2)
            n_subs_2 = nnz(index_b_data_c2);   % = size(Yc2, 2)

            X = zeros(n_subs_1 + n_subs_2, 2);
            X(1:n_subs_1, 1) = 1;                   % Condition 1
            X(n_subs_1+1:n_subs_1+n_subs_2, 2) = 1; % Condition 2

            RP.n_subs_1 = n_subs_1;
            RP.n_subs_2 = n_subs_2;
            RP.n_subs = n_subs_1 + n_subs_2;

        case 'r'
            
            ref_cond = TestData.reference_condition;
            
            scores = r_test_categorical_to_numeric(TestData.score);

            % Remove nan values
            valid_idx = ~isnan(scores);
            sub_ids = TestData.sub_ids(valid_idx);
            scores = scores(valid_idx);

            % Check for duplicate IDs before alignment
            assert(numel(unique(sub_ids)) == numel(sub_ids), ...
                'Dataset bug: duplicate subject IDs found in TestData.');
            assert(numel(unique(BrainData.(ref_cond).sub_ids)) == numel(BrainData.(ref_cond).sub_ids), ...
                'Dataset bug: duplicate subject IDs found in BrainData.%s.', ref_cond);

            % Align to BrainData order
            [~, brain_pos] = ismember(sub_ids, BrainData.(ref_cond).sub_ids);
            valid_brain = brain_pos > 0;
            sub_ids = sub_ids(valid_brain);
            scores = scores(valid_brain);
            Y = BrainData.(ref_cond).data(:, brain_pos(valid_brain));

            % Build design matrix with intercept
            n_subjects = numel(scores);
            X = [scores(:), ones(n_subjects, 1)];

            RP.sub_ids_task = sub_ids;
            RP.sub_ids_rest = sub_ids;

            % Get sub numbers
            RP.n_subs_1 = length(sub_ids);
            RP.n_subs_2 = length(sub_ids);
            RP.n_subs = length(sub_ids);


    end 

    n_available = size(BrainData.(ref_cond).data,2);

    assert(RP.n_subs <= n_available, ...
        ['Dataset bug: t2 groups sum to %d subjects but BrainData.%s ' ...
        'only has %d unique subjects. ' ...
        'Groups likely overlap (a subject matched both conditions) ' ...
        'or IDs are duplicated.'], ...
        RP.n_subs, ref_cond, n_available);

end
