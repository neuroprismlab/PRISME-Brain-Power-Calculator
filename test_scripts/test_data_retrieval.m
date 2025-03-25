function test_data_retrieval(TestData, BrainData, RP)
%% test_data_retrieval
% Validates the correctness of the data extraction logic used in the contrast-based test setup.
%
% This function uses synthetic brain data and test metadata to ensure that
% the function subs_data_from_contrast returns a design matrix (X) and 
% functional connectivity data (Y) with the expected size, values, and subject mappings.
%
% Inputs:
%   - TestData: Struct containing contrast-based test configuration, with a 'contrast' field.
%   - BrainData: Struct containing synthetic functional connectivity data for TASK and REST.
%   - RP: Struct of experiment parameters, modified in-place to store the correct sub_ids and test_type.
%
% Outputs:
%   - None (throws assertion errors if validation fails).
%
% Workflow:
%   1. Creates synthetic TASK and REST data with values between -1 and 1.
%   2. Runs subs_data_from_contrast to extract the design matrix (X), data matrix (Y), and update RP.
%   3. Validates:
%       - The structure and values of X for both 't' and 't2' test types.
%       - The dimensions of Y and consistency with X.
%       - Subject ID mappings in RP against the expected subsets.
%       - That the actual values in Y match the expected brain data subtraction or grouping.
%
% Throws an error if any check fails.

    % Ensures that subs_data_from_contrast correctly processes TestData & BrainData

    % Create mock brain data (assuming 100 features per subject)
    num_features = 10;
    num_subs_rest = length(BrainData.REST.sub_ids);
    num_subs_task = length(BrainData.TASK.sub_ids);

    % Assigning random fc brain data for testing
    BrainData.REST.data = 2 * rand(num_features, num_subs_rest) - 1; 
    BrainData.TASK.data = 2 * rand(num_features, num_subs_task) - 1; 

    % Call function with test data
    [X, Y, RP] = subs_data_from_contrast(RP, TestData.contrast, BrainData);
    
    % ** Check X (Design Matrix)**
    if strcmp(RP.test_type, 't')
        assert(isequal(size(X), [length(RP.sub_ids), 1]), 'Mismatch in X size for t-test');
        assert(all(X == 1), 'X should be all ones for t-test');
    elseif strcmp(RP.test_type, 't2')
        assert(isequal(size(X), [length(RP.sub_ids_task) + length(RP.sub_ids_rest), 2]), ...
            'Mismatch in X size for t2-test');
        assert(all(X(1:length(RP.sub_ids_task), 1) == 1), 'First column of X should indicate first group');
        assert(all(X(length(RP.sub_ids_task)+1:end, 2) == 1), 'Second column of X should indicate second group');
    end

    % **3. Check Y Shape**
    assert(size(Y, 2) == size(X, 1), 'Mismatch between Y columns and X rows');

    % **4. Check Subject ID Matching in RP**
    if strcmp(RP.test_type, 't')
        assert(isequal(sort(RP.sub_ids), sort(intersect(BrainData.REST.sub_ids, BrainData.TASK.sub_ids))), ...
            'Mismatch in RP.sub_ids for t-test');
    elseif strcmp(RP.test_type, 't2')
        
        expected_task = intersect(BrainData.TASK.sub_ids, setxor(BrainData.TASK.sub_ids, BrainData.REST.sub_ids));
        expected_rest = intersect(BrainData.REST.sub_ids, setxor(BrainData.REST.sub_ids, BrainData.TASK.sub_ids));

        assert(isequal(sort(RP.sub_ids_task), sort(expected_task)), ...
            'Mismatch in RP.sub_ids_task for t2-test');
        assert(isequal(sort(RP.sub_ids_rest), sort(expected_rest)), ...
            'Mismatch in RP.sub_ids_rest for t2-test');
    end

    % ** Validate `Y` contains the expected extracted brain data**
    if strcmp(RP.test_type, 't')
        % **Y should be TASK - REST for overlapping subjects**
        [~, sub_index_task] = ismember(RP.sub_ids, BrainData.TASK.sub_ids);
        [~, sub_index_rest] = ismember(RP.sub_ids, BrainData.REST.sub_ids);

        expected_Y = BrainData.TASK.data(:, sub_index_task) - BrainData.REST.data(:, sub_index_rest);

        assert(isequal(size(Y), size(expected_Y)), 'Mismatch in Y size for t-test');
        assert(all(abs(Y(:) - expected_Y(:)) < 1e-10), 'Mismatch in Y values for t-test');

    elseif strcmp(RP.test_type, 't2')
        [~, sub_index_task] = ismember(RP.sub_ids_task, BrainData.TASK.sub_ids);
        [~, sub_index_rest] = ismember(RP.sub_ids_rest, BrainData.REST.sub_ids);

        expected_Y_task = BrainData.TASK.data(:, sub_index_task);
        expected_Y_rest = BrainData.REST.data(:, sub_index_rest);

        expected_Y = [expected_Y_task, expected_Y_rest];

        assert(isequal(size(Y), size(expected_Y)), 'Mismatch in Y size for t2-test');
        assert(all(abs(Y(:) - expected_Y(:)) < 1e-10), 'Mismatch in Y values for t2-test');
    end

end