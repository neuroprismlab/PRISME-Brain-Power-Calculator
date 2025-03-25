function data_inference_from_contrast_test()
%% data_inference_from_contrast_test
% Runs a suite of tests to validate automatic test type inference logic.
%
% This function evaluates whether test types (`t` vs. `t2`) are correctly inferred
% from subject ID overlap between two conditions (e.g., TASK and REST).
%
% It uses various configurations of overlapping and non-overlapping subject sets,
% then confirms that the `subs_data_from_contrast` function correctly prepares
% the design matrix (X), data matrix (Y), and subject IDs.
%
% Outputs:
%   - None (assertion errors are thrown if validation fails).
%
% Workflow:
%   1. Creates multiple contrast scenarios with different overlap levels between TASK and REST subjects.
%   2. Calls `test_test_type_inference` to simulate experimental metadata and extract brain data.
%   3. Uses `test_data_retrieval` to confirm that design matrices and brain data are correctly constructed.
%
% Notes:
%   - Full subject overlap → inferred as one-sample t-test (`t`)
%   - Partial overlap → should still be classified as (`t`)
%   - No subject overlap → classified as two-sample t-test (`t2`)

    % Run tests for different subject configurations
    % total overlap - t test case
    [TestData, BrainData, RP] = test_test_type_inference(...
        [1, 2, 3, 4, 5, 6, 7, 8], [5, 6, 7, 8, 1, 2, 3, 4]); % High overlap
    test_data_retrieval(TestData, BrainData, RP);

    % High Overlap - `t` test case (should classify as `t`)
    % High overlap, but not identical
    [TestData, BrainData, RP] = test_test_type_inference(...
        [1, 2, 3, 4, 5, 6, 7, 8], [4, 5, 6, 7, 8, 9, 10, 11]); 
    test_data_retrieval(TestData, BrainData, RP);
    
    % No overlap t2 test case
    [TestData, BrainData, RP] = test_test_type_inference(...
        [1, 2, 3, 4, 5, 6, 7, 8], [9, 10, 11, 12, 13, 14, 15, 16]); % No overlap
    test_data_retrieval(TestData, BrainData, RP);

    % `t` vs `t2` (Partial Overlap)
    [TestData, BrainData, RP] = test_test_type_inference(...
        [1, 2, 3, 4, 5, 6, 7, 8], [5, 6, 7, 8, 9, 10, 11, 12]);
    test_data_retrieval(TestData, BrainData, RP);

end