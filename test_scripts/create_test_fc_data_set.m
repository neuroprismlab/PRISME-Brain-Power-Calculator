function create_test_fc_data_set()
%% create_test_fc_data_set
% Generates a synthetic functional connectivity dataset for testing edge-based 
% statistical methods in the power calculator pipeline.
%
% The simulated dataset mimics a task vs. rest contrast, with predefined effects in
% the upper half of the connectivity matrix.
%
% Dataset Structure:
%   - 50 subjects
%   - 10 FC edges (from 5 ROIs)
%   - 6 edges are assigned a task-based effect (fixed increase during TASK)
%   - 4 edges show no effect (identical in TASK and REST)
%
% Notes:
%   - Methods under test should reliably identify the first 6 edges as significant.
%   - Saved to: ./data/test_hcp_fc.mat
    
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

