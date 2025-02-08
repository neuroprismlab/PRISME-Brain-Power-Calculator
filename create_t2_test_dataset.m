function create_t2_test_dataset()
    
    %% Definition of the tast dataset description
    nodes = 5;
    variables = 10;
    subject_number = 50;

    study_info.dataset = 'test_t2';
    study_info.map = 'fc';
    study_info.test = 't';
    study_info.mask = logical(triu(ones(nodes), 1));

    outcome.test1.sub_ids = NaN;
    outcome.test1.score = NaN;
    outcome.test1.score_label = NaN;
    outcome.test1.contrast = {'TASK', 'REST'};
    outcome.test1.category = 'cognitive';
    
    brain_data.TASK.motion = NaN;
    brain_data.REST.motion = NaN;

    % Generate two unique, non-overlapping subject ID lists for t2 test
    offset = 100000; 
    brain_data.TASK.sub_ids = (1:subject_number)' + offset;               
    brain_data.REST.sub_ids = (subject_number+1:2*subject_number)' + offset; 

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

    file_name = './data/test_t2_fc.mat';

    save(file_name, 'brain_data', 'study_info', 'outcome');
       
    %% Remove this later
    edge_based_tests('test_t2_fc.mat')

end