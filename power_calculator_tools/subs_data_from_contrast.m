function [X, Y, RP] = subs_data_from_contrast(RP, contrast, BrainData)
    
    %% TODO: To Optimize use create_design_matrix function for X
    
    % Get sub ids from contrast
    % Maybe this changes? I don't know if all contrasts have two elements
    sub_ids_cond1 = BrainData.(contrast{1}).sub_ids;
    sub_ids_cond2 = BrainData.(contrast{2}).sub_ids;
    RP.test_name = strcat(contrast{1}, '_', contrast{2});
    
    switch RP.test_type

        case 't'

            sub_ids = intersect(RP.sub_ids_cond1, RP.sub_ids_cond2);
            % We change the sub_ids because some were discarted from the
            % intersection
            RP.sub_ids_cond1 = sub_ids;
            RP.sub_ids_cond2 = sub_ids;
            RP.sub_ids = sub_ids;
            
            % Extract respective indeces according to subject ids
            [~, sub_index_t1] = ismember(sub_ids, sub_ids_cond1);    
            [~, sub_index_t2] = ismember(sub_ids, sub_ids_cond2);    
            
            % One matrix for the t-test
            X = ones(length(sub_ids), 1);
    
            % Normally the first one is rest, but it depends on input data
            Y_rest = BrainData.(contrast{1}).data(:, sub_index_t1);
            Y_task = BrainData.(contrast{2}).data(:, sub_index_t2);  
    
            Y = Y_task - Y_rest;

            RP.n_subs_1 = length(sub_ids);
            RP.n_subs_2 = length(sub_ids);
            RP.n_subs = length(sub_ids);

        case 't2'  
            
            % Use only subjects unique to each condition
            xor_sub_ids = setxor(sub_ids_cond1, sub_ids_cond2);
            
            %% MINOR TODO: Don't discart repetead subjects add them to diff tasks 
            % Update the respective subject lists
            RP.sub_ids_cond1 = intersect(sub_ids_cond1, xor_sub_ids); % Unique to cond1
            RP.sub_ids_cond2 = intersect(sub_ids_cond2, xor_sub_ids); % Unique to cond2
            RP.sub_ids = xor_sub_ids;
    
            % Get the number of subjects for each condition
            n_subs_1 = length(RP.sub_ids_cond1);
            n_subs_2 = length(RP.sub_ids_cond2);
    
            % Get indices for the unique subject IDs in each condition
            [~, sub_index_t1] = ismember(RP.sub_ids_cond1, sub_ids_cond1);    
            [~, sub_index_t2] = ismember(RP.sub_ids_cond2, sub_ids_cond2);
    
            % Get respective brain data
            % Normally the first one is rest, but it depends on input data
            Y_rest = BrainData.(contrast{1}).data(:, sub_index_t1);
            Y_task = BrainData.(contrast{2}).data(:, sub_index_t2);  
    
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

            sub_ids = intersect(RP.sub_ids_cond1, RP.sub_ids_cond2);
            % We change the sub_ids because some were discarted from the
            % intersection
            RP.sub_ids_cond1 = sub_ids;
            RP.sub_ids_cond2 = sub_ids;
            RP.sub_ids = sub_ids;
    
            [~, sub_index_t1] = ismember(sub_ids, sub_ids_cond1);    
            [~, sub_index_t2] = ismember(sub_ids, sub_ids_cond2);    
    
            X = zeros(length(sub_ids) * 2, length(sub_ids) + 1);
            X(1:length(sub_ids), 1) = 1;
            X(length(sub_ids) + 1:end, 1) = -1;
    
            for i=1:length(sub_ids)
                X(i,i+1)=1;
                X(length(sub_ids) + i, i + 1) = 1;
            end

            % Get respective brain data 
            % Normally the first one is rest, but it depends on input data
            Y_rest = BrainData.(contrast{1}).data(:, sub_index_t1);
            Y_task = BrainData.(contrast{2}).data(:, sub_index_t2);  
    
            Y = [Y_task, Y_rest]; 

            % Update subject counts
            RP.n_subs_1 = n_subs;
            RP.n_subs_2 = n_subs;
            RP.n_subs = n_subs;
        
    end

end