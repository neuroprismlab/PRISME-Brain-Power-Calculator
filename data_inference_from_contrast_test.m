function data_inference_from_contrast_test()

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