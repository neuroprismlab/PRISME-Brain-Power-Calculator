function test_subs_score_retrieval()

    fprintf('Running tests for subs_data_from_score_condition...\n\n');

    test_r_basic_alignment();
    test_r_shuffled_brain_order();
    test_r_nan_removal();
    test_r_subject_not_in_brain_data();
    test_t2_basic();
    test_duplicate_sub_ids_error();

    fprintf('All tests passed.\n');

end

% -------------------------------------------------------------------------
function test_r_basic_alignment()
%% r case: same order in TestData and BrainData - sanity check

    [RP, TestData, BrainData] = build_r_structs( ...
        [1, 2, 3], ...      % test_sub_ids
        [10, 20, 30], ...   % scores
        [1, 2, 3], ...      % brain_sub_ids
        [100, 200, 300] ... % brain_values
        );

    [X, Y, RP_out] = subs_data_from_score_condition(RP, TestData, BrainData, 'test');

    assert(isequal(size(X), [3, 2]), 'test_r_basic_alignment: X shape wrong');
    assert(isequal(size(Y), [1, 3]), 'test_r_basic_alignment: Y shape wrong');
    assert(RP_out.n_subs == 3, 'test_r_basic_alignment: n_subs wrong');

    % Each subject's score * 10 should equal their brain value
    assert(all(X(:, 1) .* 10 == Y(1, :)'),     'test_r_basic_alignment: X/Y misaligned');

    fprintf('PASS: test_r_basic_alignment\n');

end

% -------------------------------------------------------------------------
function test_r_shuffled_brain_order()
%% r case: BrainData subjects are in a different order than TestData
%  This is the key alignment bug - X must follow BrainData order after fix

    % TestData: subjects [1, 2, 3] with scores [10, 20, 30]
    % BrainData: subjects [3, 1, 2] (shuffled) with brain values [300, 100, 200]
    [RP, TestData, BrainData] = build_r_structs( ...
        [1, 2, 3], ...      % test_sub_ids
        [10, 20, 30], ...   % scores
        [3, 1, 2], ...      % brain_sub_ids
        [300, 100, 200] ... % brain_values
        );

    [X, Y, ~] = subs_data_from_score_condition(RP, TestData, BrainData, 'test');

    % After alignment, for every column i: X(i,1) * 10 == Y(1,i)
    assert(all(X(:, 1) .* 10 == Y(1, :)'), 'test_r_shuffled_brain_order: X/Y misaligned after shuffle');

    fprintf('PASS: test_r_shuffled_brain_order\n');

end

% -------------------------------------------------------------------------
function test_r_nan_removal()
%% r case: NaN scores should be dropped and remaining subjects aligned correctly

    [RP, TestData, BrainData] = build_r_structs( ...
        [1, 2, 3, 4], ...       % test_sub_ids
        [10, NaN, 30, 40], ...  % scores
        [1, 2, 3, 4], ...       % brain_sub_ids
        [100, 200, 300, 400] ... % brain_values
        );

    [X, Y, RP_out] = subs_data_from_score_condition(RP, TestData, BrainData, 'test');

    assert(RP_out.n_subs == 3, 'test_r_nan_removal: n_subs wrong, NaN not dropped');
    assert(isequal(size(X), [3, 2]), 'test_r_nan_removal: X shape wrong');
    assert(~any(isnan(X(:, 1))), 'test_r_nan_removal: NaN still present in X');
    assert(all(X(:, 1) .* 10 == Y(1, :)'), 'test_r_nan_removal: X/Y misaligned after NaN drop');

    fprintf('PASS: test_r_nan_removal\n');

end

% -------------------------------------------------------------------------
function test_r_subject_not_in_brain_data()
%% r case: a subject in TestData has no match in BrainData - should be dropped

    [RP, TestData, BrainData] = build_r_structs( ...
        [1, 2, 99], ...  % test_sub_ids - subject 99 not in BrainData
        [10, 20, 30], ... % scores
        [1, 2], ...      % brain_sub_ids
        [100, 200] ...   % brain_values
        );

    [X, Y, RP_out] = subs_data_from_score_condition(RP, TestData, BrainData, 'test');

    assert(RP_out.n_subs == 2, 'test_r_subject_not_in_brain_data: subject 99 not dropped');
    assert(all(X(:, 1) .* 10 == Y(1, :)'), 'test_r_subject_not_in_brain_data: X/Y misaligned');

    fprintf('PASS: test_r_subject_not_in_brain_data\n');

end

% -------------------------------------------------------------------------
function test_t2_basic()
%% t2 case: two groups should produce correct block design matrix X and Y

    RP = struct('test_type', 't2');

    TestData.reference_condition = 'cond_a';
    TestData.sub_ids = [1, 2, 3, 4];
    TestData.score   = [1, 1, 2, 2];  % two groups

    % BrainData in same order as TestData
    BrainData.cond_a.sub_ids = [1, 2, 3, 4];
    BrainData.cond_a.data    = [10, 20, 30, 40];  % 1 edge x 4 subjects

    [X, Y, RP_out] = subs_data_from_score_condition(RP, TestData, BrainData, 'test');

    assert(isequal(size(X), [4, 2]), 'test_t2_basic: X shape wrong');
    assert(isequal(X(:, 1), [1;1;0;0]), 'test_t2_basic: X condition 1 wrong');
    assert(isequal(X(:, 2), [0;0;1;1]), 'test_t2_basic: X condition 2 wrong');
    assert(isequal(Y, [10, 20, 30, 40]), 'test_t2_basic: Y wrong');
    assert(RP_out.n_subs == 4, 'test_t2_basic: n_subs wrong');

    fprintf('PASS: test_t2_basic\n');

end

% -------------------------------------------------------------------------
function test_duplicate_sub_ids_error()
%% r case: duplicate subject IDs should throw an assert error

    [RP, TestData, BrainData] = build_r_structs( ...
        [1, 1, 3], ...           % subject 1 duplicated
        [10, 20, 30], ...
        [1, 1, 3], ...
        [100, 100, 300]);

    try
        subs_data_from_score_condition(RP, TestData, BrainData, 'test');
        error('test_duplicate_sub_ids_error: expected assert error, but none thrown');
    catch e
        assert(contains(e.message, 'duplicate'), ...
            'test_duplicate_sub_ids_error: wrong error message: %s', e.message);
    end

    fprintf('PASS: test_duplicate_sub_ids_error\n');

end

% -------------------------------------------------------------------------
function [RP, TestData, BrainData] = build_r_structs( ...
    test_sub_ids, ...
    scores, ...
    brain_sub_ids, ...
    brain_values ...
    )
%% Helper: builds minimal structs for the r case
%  brain_values: 1 x n vector, one value per subject (1 edge for simplicity)

    RP = struct('test_type', 'r');
    
    TestData = struct();
    TestData.reference_condition = 'cond_a';
    TestData.sub_ids             = test_sub_ids;
    TestData.score               = scores;
    
    BrainData = struct();
    BrainData.cond_a.sub_ids = brain_sub_ids;
    BrainData.cond_a.data    = brain_values;  % 1 edge x n subjects

end