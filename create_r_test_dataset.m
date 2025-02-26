function create_r_test_dataset()
    
    %% Definition of the tast dataset description
    nodes = 5;
    variables = 10;
    subject_number = 50;

    study_info.dataset = 'test_r';
    study_info.map = 'fc';
    study_info.test = 'r';
    study_info.mask = logical(triu(ones(nodes), 1));

    outcome.test1.sub_ids = 500 + (1:subject_number)';
    outcome.test1.score = (1:subject_number)';
    outcome.test1.score_label = 'INT';
    outcome.test1.reference_condition = 'rest';
    outcome.test1.contrast = NaN;
    outcome.test1.category = NaN;
    

    brain_data.rest.sub_ids = 500 + (1:subject_number)';

    brain_data.rest.data = zeros(variables, subject_number);
    for i = 1:6
        brain_data.rest.data(i, :) = 2*(1:subject_number);
    end
    
    data_dir = './data/';
    mkdir(data_dir);

    file_name = './data/test_r_fc.mat';

    save(file_name, 'brain_data', 'study_info', 'outcome');

end
