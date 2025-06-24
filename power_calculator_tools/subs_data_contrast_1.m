function [X, Y, RP] = subs_data_contrast_1(RP, contrast, BrainData)
    
    % Name task is generic. It can be rest
    task_contrast = contrast{1};
    
    % Get test name
    RP.test_name = task_contrast;

    % I only added the t test for now. If there are other dataset example,
    % I will add them later
     switch RP.test_type

        case 't'
            RP.n_subs_1 = numel(BrainData.(task_contrast).sub_ids);
            RP.n_subs_2 = numel(BrainData.(task_contrast).sub_ids);
            RP.n_subs = numel(BrainData.(task_contrast).sub_ids);

            X = ones(RP.n_subs, 1);
            Y = BrainData.(task_contrast).data;

        otherwise
            error('Test case current not support for 1 contrast cases')

     end
        

  
end