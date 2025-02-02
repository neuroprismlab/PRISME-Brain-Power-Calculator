function [X, Y, RP] = subs_data_from_contrast(RP, contrast, BrainData)
    
    %% TODO: To Optimize use create_design_matrix function for X
    
    % Get sub ids from contrast
    % Maybe this changes? I don't know if all contrasts have two elements

    % Rest contrast my not always be rest contrast lol 
    if strcmp(contrast{1}, 'REST')
        rest_contrast = contrast{1};
        task_contrast = contrast{2};
    elseif strcmp(contrast{2}, 'REST')
        rest_contrast = contrast{2};
        task_contrast = contrast{1};
    else
        rest_contrast = contrast{1};
        task_contrast = contrast{2};
    end
        
    sub_ids_task = BrainData.(task_contrast).sub_ids;
    sub_ids_rest = BrainData.(rest_contrast).sub_ids;
    RP.test_name = strcat(rest_contrast, '_', task_contrast);
    
    switch RP.test_type

        case 't'

            sub_ids = intersect(sub_ids_task, sub_ids_rest);
            % We change the sub_ids because some were discarted from the
            % intersection
            RP.sub_ids_task = sub_ids;
            RP.sub_ids_rest = sub_ids;
            RP.sub_ids = sub_ids;
            
            % Extract respective indeces according to subject ids
            [~, sub_index_task] = ismember(sub_ids, sub_ids_task);    
            [~, sub_index_rest] = ismember(sub_ids, sub_ids_rest);    
            
            % One matrix for the t-test
            X = ones(length(sub_ids), 1);
    
            % Normally the first one is rest, but it depends on input data
            Y_rest = BrainData.(rest_contrast).data(:, sub_index_rest);
            Y_task = BrainData.(task_contrast).data(:, sub_index_task);  
    
            Y = Y_task - Y_rest;

            RP.n_subs_1 = length(sub_ids);
            RP.n_subs_2 = length(sub_ids);
            RP.n_subs = length(sub_ids);

        case 't2'  
            
            % Use only subjects unique to each condition
            xor_sub_ids = setxor(sub_ids_task, sub_ids_rest);
            
            %% MINOR TODO: Don't discart repetead subjects add them to diff tasks 
            % Update the respective subject lists
            RP.sub_ids_task = intersect(sub_ids_task, xor_sub_ids); % Unique to cond1
            RP.sub_ids_rest = intersect(sub_ids_rest, xor_sub_ids); % Unique to cond2
            RP.sub_ids = xor_sub_ids;
    
            % Get the number of subjects for each condition
            n_subs_1 = length(RP.sub_ids_task);
            n_subs_2 = length(RP.sub_ids_rest);
    
            % Get indices for the unique subject IDs in each condition
            [~, sub_index_task] = ismember(RP.sub_ids_task, sub_ids_task);    
            [~, sub_index_rest] = ismember(RP.sub_ids_rest, sub_ids_rest);
    
            % Get respective brain data
            % Normally the first one is rest, but it depends on input data
            Y_rest = BrainData.(rest_contrast).data(:, sub_index_rest);
            Y_task = BrainData.(task_contrast).data(:, sub_index_task);  
    
            % Combine the data
            Y = [Y_task, Y_rest];
    
            % Create design matrix
            X = zeros(n_subs_1 + n_subs_2, 2);
            X(1:n_subs_1, 1) = 1;               % Condition 1
            X(n_subs_1+1:n_subs_1+n_subs_2, 2) = 1; % Condition 2

            RP.n_subs_1 = n_subs_1;
            RP.n_subs_2 = n_subs_2;
            RP.n_subs = length(xor_sub_ids);
        
        case 'pt'

            sub_ids = intersect(RP.sub_ids_task, RP.sub_ids_rest);
            % We change the sub_ids because some were discarted from the
            % intersection
            RP.sub_ids_task = sub_ids;
            RP.sub_ids_rest = sub_ids;
            RP.sub_ids = sub_ids;
    
            [~, sub_index_task] = ismember(sub_ids, sub_ids_task);    
            [~, sub_index_rest] = ismember(sub_ids, sub_ids_rest);    
    
            X = zeros(length(sub_ids) * 2, length(sub_ids) + 1);
            X(1:length(sub_ids), 1) = 1;
            X(length(sub_ids) + 1:end, 1) = -1;
    
            for i=1:length(sub_ids)
                X(i,i+1)=1;
                X(length(sub_ids) + i, i + 1) = 1;
            end

            % Get respective brain data 
            % Normally the first one is rest, but it depends on input data
            Y_rest = BrainData.(rest_contrast).data(:, sub_index_rest);
            Y_task = BrainData.(task_contrast).data(:, sub_index_task);  
    
            Y = [Y_task, Y_rest]; 

            % Update subject counts
            n_subs = length(sub_ids);
            RP.n_subs_1 = n_subs;
            RP.n_subs_2 = n_subs;
            RP.n_subs = n_subs;
        
    end

end