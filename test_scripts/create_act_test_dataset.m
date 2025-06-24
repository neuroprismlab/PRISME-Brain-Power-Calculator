function create_act_test_dataset()
    %% Definition of the test activation dataset
    
    % Create a 2D mask with 10 variables (true values)
    % Make a larger mask with buffer of zeros around the true values
    mask = false(8, 8);
    mask(2:4, 2:4) = true;  % 3x3 block = 9 ones, surrounded by zeros
    mask(5, 2) = true;      % Add one more to get 10 total
    
    % Verify we have exactly 10 variables
    n_variables = sum(mask(:));
    assert(n_variables == 10, 'Mask should have exactly 10 true values');
    
    % Dataset parameters
    subject_number = 50;
    
    %% Study info
    study_info.dataset = 'test_act';
    study_info.map = 'act';
    study_info.test = 't';
    
    %% Outcome structure
    outcome.test1.sub_ids = 500 + (1:subject_number)';
    outcome.test1.score = NaN;
    outcome.test1.score_label = NaN;
    outcome.test1.reference_condition = '';
    outcome.test1.contrast = {'TASK'};
    outcome.test1.category = 'cognitive';
    
    %% Brain data structure
    brain_data.TASK.sub_ids = 500 + (1:subject_number)';
    brain_data.TASK.mask = mask;
    
    % Initialize data with very low variance normal distribution
    brain_data.TASK.data = min(0, randn(n_variables, subject_number) * 0.001);
    
    % Add effect to first 6 variables (adjacent in the mask)
    % These correspond to the first 6 true positions in the mask
    for i = 1:6
        brain_data.TASK.data(i, :) = brain_data.TASK.data(i, :) + 3;
    end
    
    % Variables 7-10 remain with only the low-variance noise (no effect)
    
    %% Save the dataset
    data_dir = './data/';
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    file_name = './data/test_act_act.mat';
    save(file_name, 'brain_data', 'study_info', 'outcome');
    

end