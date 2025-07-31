function gt_filename = construct_gt_filename(meta_data, output_name)
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
    [test_components, test_type, ~, testing_code] = get_data_for_file_naming(meta_data);

    % Construct the GT filename
    gt_filename = sprintf('%s-%s-%s-%s', ...
                          output_name, test_components, ...
                          test_type, 'Ground_Truth');

    if testing_code 
        gt_filename = strcat(gt_filename, '-test.mat');
    else
        gt_filename = strcat(gt_filename, '.mat');
    end

end