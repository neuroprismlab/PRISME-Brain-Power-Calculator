function gt_filename = construct_gt_filename(meta_data)
%% construct_gt_filename
% Constructs a ground-truth filename from metadata. 
% The function concatenates meta_data.dataset and meta_data.map with an underscore,
% joins the test_components with underscores, and uses sprintf to include the test type 
% and the tag 'Ground_Truth'. It appends '-test.mat' if testing_code is true, otherwise '.mat'.
%
% Inputs:
%   - meta_data: Struct with the following fields:
%       * dataset: Name of the dataset.
%       * map: Atlas or mapping identifier.
%       * test_components: Cell array of test component strings.
%       * test: Test type.
%       * testing_code: Logical flag indicating testing mode.
%
% Outputs:
%   - gt_filename: A string containing the constructed filename.
%

    % Extract information from metadata
    data_set_name = strcat(meta_data.dataset, '_', meta_data.map);
    test_components = strjoin(meta_data.test_components, '_');
    test_type = meta_data.test;   

    % Construct the GT filename
    gt_filename = sprintf('%s-%s-%s-%s', ...
                          data_set_name, test_components, ...
                          test_type, 'Ground_Truth');

    if meta_data.testing_code 
        gt_filename = strcat(gt_filename, '-test.mat');
    else
        gt_filename = strcat(gt_filename, '.mat');
    end

end