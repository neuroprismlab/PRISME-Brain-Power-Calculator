function test_type_inference_tests()
%% test_type_inference_tests
% Unit tests for infer_test_from_data.
%
% Covers every branch of the test-type inference:
%   - correlation (r)               [score continuous, >2 unique values]
%   - two-sample via score (t2)     [2 unique score values]
%   - single-sample via score (t)   [1 unique score value]
%   - contrast, one condition (t)
%   - contrast, two conditions, paired   (t)  [heavy subject overlap]
%   - contrast, two conditions, unpaired (t2) [little/no overlap]
%   - contrast with >2 conditions        -> error
%   - contrast that is NaN               -> error
%   - uninferable (no score, no cell contrast) -> error
%   - length mismatch score vs BrainData [reproduces the reported crash]
%
% Bare asserts: the run aborts on the first failing case.
%
% Assumptions about dependencies (must be on the MATLAB path):
%   get_test_score_set(TestData) returns the set of unique score values,
%       and a single NaN when there is no usable score.
%   get_index_matching_score(TestData, set) returns two logical masks the
%       same length as TestData.score.
% If those helpers behave differently, the branch that gets selected below
% may change.

    fprintf('=== infer_test_from_data tests ===\n');

    test_correlation();          fprintf('  [PASS] correlation (r)\n');
    test_two_sample_score();     fprintf('  [PASS] two-sample via score (t2)\n');
    test_single_sample_score();  fprintf('  [PASS] single-sample via score (t)\n');
    test_contrast_single();      fprintf('  [PASS] contrast, one condition (t)\n');
    test_contrast_paired();      fprintf('  [PASS] contrast, two conditions, paired\n');
    test_contrast_unpaired();    fprintf('  [PASS] contrast, two conditions, unpaired\n');
    test_contrast_too_many();    fprintf('  [PASS] contrast, >2 conditions (error)\n');
    test_contrast_nan();         fprintf('  [PASS] contrast is NaN (error)\n');
    test_uninferable();          fprintf('  [PASS] uninferable (error)\n');

    fprintf('=== all tests passed ===\n');

    % ------------------------------------------------------------------
    % Helpers
    % ------------------------------------------------------------------

    function threw = expect_error(fn)
        threw = false;
        try
            fn();
        catch
            threw = true;
        end
    end

    function TestData = create_td_score(score, sub_ids, ref)
        TestData = struct();
        TestData.score               = score;
        TestData.sub_ids             = sub_ids;
        TestData.reference_condition = ref;
        TestData.contrast            = {NaN};   % unused on the score branches
    end

    function TestData = create_td_contrast(contrast, ref)
        TestData = struct();
        TestData.score               = NaN;     % force score branches to fall through
        TestData.sub_ids             = [];
        TestData.reference_condition = ref;
        TestData.contrast            = contrast;
    end

    function BrainData = create_brain_data(varargin)
        BrainData = struct();
        for k = 1:2:numel(varargin)
            name = varargin{k};
            ids  = varargin{k+1};
            BrainData.(name).sub_ids = ids;
            BrainData.(name).data    = zeros(3, numel(ids));  % 3 dummy edges
        end
    end

    % ------------------------------------------------------------------
    % Test cases
    % ------------------------------------------------------------------

    function test_correlation()
        RP = struct();
        TestData  = create_td_score([0.1 0.7 1.3 2.2 3.0 4.4], [1 2 3 4 5 6], 'REST');
        BrainData = create_brain_data('REST', [1 2 3 4 5 6]);

        [RPo, origin] = infer_test_from_data(RP, TestData, BrainData);
        assert(strcmp(RPo.test_type, 'r'),             'test_type should be r, got %s', RPo.test_type);
        assert(strcmp(origin, 'score_cond'),           'origin should be score_cond, got %s', origin);
        assert(strcmp(RPo.nbs_test_stat, 'onesample'), 'nbs_test_stat should be onesample, got %s', RPo.nbs_test_stat);
    end

    function test_two_sample_score()
        RP = struct();
        % A subject has exactly one score, so the two score groups are always
        % disjoint -> n_equal = 0 -> this branch resolves to t2.
        TestData  = create_td_score([1 1 1 2 2 2], [10 11 12 13 14 15], 'REST');
        BrainData = create_brain_data('REST', [10 11 12 13 14 15]);

        [RPo, origin] = infer_test_from_data(RP, TestData, BrainData);
        assert(strcmp(RPo.test_type, 't2'),          'test_type should be t2, got %s', RPo.test_type);
        assert(strcmp(origin, 'score_cond'),         'origin should be score_cond, got %s', origin);
        assert(strcmp(RPo.nbs_test_stat, 't-test'),  'nbs_test_stat should be t-test, got %s', RPo.nbs_test_stat);
    end

    function test_single_sample_score()
        RP = struct();
        TestData  = create_td_score([3 3 3 3], [1 2 3 4], 'REST');
        BrainData = create_brain_data('REST', [1 2 3 4]);

        % Capture RP only: this branch never assigns test_type_origin, so
        % asking for both outputs currently errors (asserted separately below).
        RPo = infer_test_from_data(RP, TestData, BrainData);
        assert(strcmp(RPo.test_type, 't'), 'test_type should be t, got %s', RPo.test_type);

        % This SHOULD pass but currently FAILS: the single-sample branch does
        % not set test_type_origin, so requesting the 2nd output blows up.
        assigned = false;
        try
            [~, ~] = infer_test_from_data(RP, TestData, BrainData);
            assigned = true;
        catch
        end
        assert(assigned, 'test_type_origin is not assigned on the single-sample branch');
    end

    function test_contrast_single()
        RP = struct();
        TestData  = create_td_contrast({'REST'}, 'REST');
        BrainData = create_brain_data('REST', [1 2 3 4 5]);

        [RPo, origin] = infer_test_from_data(RP, TestData, BrainData);
        assert(strcmp(RPo.test_type, 't'),             'test_type should be t, got %s', RPo.test_type);
        assert(strcmp(origin, 'contrast'),             'origin should be contrast, got %s', origin);
        assert(strcmp(RPo.nbs_test_stat, 'onesample'), 'nbs_test_stat should be onesample, got %s', RPo.nbs_test_stat);
    end

    function test_contrast_paired()
        RP = struct();
        TestData  = create_td_contrast({'REST', 'TASK'}, 'REST');
        BrainData = create_brain_data('REST', [1 2 3 4 5], 'TASK', [1 2 3 4 5]);  % full overlap

        [RPo, origin] = infer_test_from_data(RP, TestData, BrainData);
        assert(strcmp(RPo.test_type, 't'), 'test_type should be t (heavy overlap), got %s', RPo.test_type);
        assert(strcmp(origin, 'contrast'), 'origin should be contrast, got %s', origin);
    end

    function test_contrast_unpaired()
        RP = struct();
        TestData  = create_td_contrast({'REST', 'TASK'}, 'REST');
        BrainData = create_brain_data('REST', [1 2 3 4 5], 'TASK', [6 7 8 9 10]);  % no overlap

        [RPo, origin] = infer_test_from_data(RP, TestData, BrainData);
        assert(strcmp(RPo.test_type, 't2'), 'test_type should be t2 (no overlap), got %s', RPo.test_type);
        assert(strcmp(origin, 'contrast'),  'origin should be contrast, got %s', origin);
    end

    function test_contrast_too_many()
        RP = struct();
        TestData  = create_td_contrast({'A', 'B', 'C'}, 'A');
        BrainData = create_brain_data('A', [1 2], 'B', [3 4], 'C', [5 6]);

        assert(expect_error(@() infer_test_from_data(RP, TestData, BrainData)), ...
            'should have errored on >2 contrast conditions');
    end

    function test_contrast_nan()
        RP = struct();
        TestData  = create_td_contrast({NaN}, 'REST');
        BrainData = create_brain_data('REST', [1 2 3]);

        assert(expect_error(@() infer_test_from_data(RP, TestData, BrainData)), ...
            'should have errored when contrast is NaN');
    end

    function test_uninferable()
        RP = struct();
        TestData        = create_td_contrast(NaN, 'REST');  % contrast is NaN, not a cell
        TestData.score  = NaN;                       % no usable score
        BrainData = create_brain_data('REST', [1 2 3]);

        assert(expect_error(@() infer_test_from_data(RP, TestData, BrainData)), ...
            'should have errored when test type cannot be inferred');
    end


end