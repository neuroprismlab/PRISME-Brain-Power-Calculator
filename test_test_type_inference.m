function [TestData, BrainData, RP] = test_test_type_inference(subs_id_rest, subs_id_emotion)

% Test infer_test_from_data when score, score_label, reference_condition are NaN
    % and two tasks (contrast) are provided.

    % Create a minimal RP struct
    RP = struct();

    % Create test data struct (outcome)
    TestData = struct();
    TestData.score = NaN;
    TestData.score_label = NaN;
    TestData.reference_condition = NaN;
    TestData.contrast = {'REST', 'TASK'};  % Two tasks provided

    % Define mock sub_id sets for two conditions
    sub_ids_rest = subs_id_rest;
    sub_ids_emotion = subs_id_emotion;

    % Create BrainData struct with task-specific subject IDs
    BrainData = struct();
    BrainData.REST.sub_ids = sub_ids_rest;
    BrainData.TASK.sub_ids = sub_ids_emotion;

    % Expected values for test type inference
    expected_n_equal = numel(intersect(sub_ids_rest, sub_ids_emotion));
    expected_n_unique = numel(setxor(sub_ids_rest, sub_ids_emotion));

    if expected_n_equal >= expected_n_unique
        expected_test_type = 't';
    else
        expected_test_type = 't2';
    end

    % Run the function
    RP = infer_test_from_data(RP, TestData, BrainData);

    % Assertions
    assert(strcmp(RP.test_type, expected_test_type), ...
        sprintf('Test type inferred incorrectly. Expected: %s, Got: %s', expected_test_type, RP.test_type));
    
    assert(isequal(sort(RP.sub_ids_cond1), sort(sub_ids_rest)), ...
        'Sub_ids_cond1 does not match REST sub_ids');
    
    assert(isequal(sort(RP.sub_ids_cond2), sort(sub_ids_emotion)), ...
        'Sub_ids_cond2 does not match EMOTION sub_ids');

end


