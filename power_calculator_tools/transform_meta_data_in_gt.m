function meta_data_reduced = transform_meta_data_in_gt(meta_data)
    % Transform meta_data into the reduced version for ground truth
    %
    % Input:
    %   - meta_data: Original metadata structure
    %
    % Output:
    %   - meta_data_reduced: Reduced metadata structure
    
    % Select specific fields to retain
    meta_data_reduced = struct();
    meta_data_reduced.dataset = meta_data.dataset; % Retain dataset name
    meta_data_reduced.map = meta_data.map;         % Retain map type
    meta_data_reduced.test = meta_data.test;       % Retain test type
    meta_data_reduced.test_components = meta_data.test_components;  % Retain components
    meta_data_reduced.subject_number = meta_data.subject_number;  % Retain subject number
    meta_data_reduced.date = meta_data.date;
    meta_data_reduced.testing_code = meta_data.testing_code;

end