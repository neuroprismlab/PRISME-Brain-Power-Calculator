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

    %% Define an empty dataset 
    Dataset = struct();

    %% Define study info - this is the test dataset to mimic hcp
    Dataset.study_info.dataset = 'test_hcp';
    Dataset.study_info.map = 'fc';
    Dataset.study_info.test = 't';
    Dataset.study_info.mask = triu(nodes, 1);


end