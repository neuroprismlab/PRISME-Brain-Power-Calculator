function create_test_fc_data_set()
    %%%
    %   - Creates dumy data to test the hpc related code
    %   It is a 20 subject dataset with only 10 ROIs - 5 with fc during
    %   task and 5 with equal fcs to rest - (no effect)
    %   Whatever method executed must find the 5 ROIs as effects 
    %
    %%%
    
    %% Definition of the tast dataset description
    nodes = 5;
    variables = 10; % 5*(5 - 1)/2
    subject_number = 20; % 20 subs is enough

    %% Define study info - this is the test dataset to mimic hcp
    study_info.dataset = 'test_hcp';
    study_info.map = 'fc';
    study_info.test = 't';
    study_info.mask = triu(ones(nodes), 1);
    
    outcome.test1.sub_ids = NaN;
    outcome.test1.score = NaN;
    outcome.test1.score_label = NaN;
    outcome.test1.contrast = {'TASK', 'REST'};
    outcome.test1.category = 'cognitive';
    
    brain_data.TASK = zeros(variables, subject_number);
    for i = 1:subject_number
        brain_data.TASK(:, i) = [1, 1, 1, 1, 1, 0.5, 0.2, 0.8, 0, 0];
    end

    for i = 1:subject_number
        brain_data.REST(:, i) = [-1, -1, -1, -1, -1, 0.5, 0.2, 0.8, 0, 0];
    end
    
    data_dir = './data/';
    mkdir(data_dir);

    file_name = './data/test_hpc_fc.mat';

    save(file_name, 'brain_data', 'study_info', 'outcome');

end