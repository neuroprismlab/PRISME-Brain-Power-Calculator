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
    subject_number = 50; % 50 subs is enough - since the matrices are quite small there should be no issues

    %% Define study info - this is the test dataset to mimic hcp
    study_info.dataset = 'test_hcp';
    study_info.map = 'fc';
    study_info.test = 't';
    study_info.mask = logical(triu(ones(nodes), 1));
    
    outcome.test1.sub_ids = NaN;
    outcome.test1.score = NaN;
    outcome.test1.score_label = NaN;
    outcome.test1.reference_condition = NaN;
    outcome.test1.contrast = {'TASK', 'REST'};
    outcome.test1.category = 'cognitive';
    
    brain_data.TASK.motion = NaN;
    brain_data.REST.motion = NaN;

    brain_data.TASK.sub_ids = (1:subject_number)' + 100000;
    brain_data.REST.sub_ids = (1:subject_number)' + 100000;

    brain_data.TASK.data = zeros(variables, subject_number);
    for i = 1:subject_number
        brain_data.TASK.data(:, i) = [1, 1, 1, 1, 1, 1, 0.2, 0.8, 0.5, 0];
    end
    
    brain_data.REST.data = zeros(variables, subject_number);
    for i = 1:subject_number
        brain_data.REST.data(:, i) = [-1, -1, -1, -1, -1, -1, 0.2, 0.8, 0.5, 0];
    end

    data_dir = './data/';
    mkdir(data_dir);

    file_name = './data/test_hcp_fc.mat';

    save(file_name, 'brain_data', 'study_info', 'outcome');

end

