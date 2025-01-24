% Maybe define it locally? Is only used by pfor_repetition_loop
function Y_rep = pf_paired_atlas_order(Y_rep, ... 
                                                 mapping_category, triumask, do_TPR, switch_task_order, ...
                                                 n_subs_subset)
    %
    % Description:
    %   This funtion extracts the necessary experiment data for a small
    %   repetition using only part of the dataset. It can also rearange
    %   tasks for null estimation in permutation testing
    %
    % Input Arguments:
    %   experiment_data - Data from data.brain_data in the dataset format
    %   task1 - First task being tested in the paired design
    %   task2 - Second task
    %   mapping_category - network statistics mapping categorary for atlas
    %   do_TPR - do true positive rate 
    %   n_subs_subset - number of subjects for this subset repetition
    %   m_test - prealocated m space with all zero
    %
    % Ouput Arguments:
    %   d - data
    %   m_test - output data
    %

    %Y_rep = zeros(RepParams.n_var, RepParams.n_subs_subset*2)

    for i = 1:n_subs_subset
                        
        %if FPR, use the predefined task order
        % how do I addapt this?
        if ~do_TPR && false
            if switch_task_order(i, this_repetition)
                this_task1=task1; 
                this_task2=task2;
            else
                this_task1=task2; 
                this_task2=task1;
            end
        else
            %this_task1=task1;
            %this_task2=task2;
        end
        
        %% ASK STEPH IF I SHOULD ONLY RUN THIS FOR NETWORK BASED METHODS
        temp_y = Y_rep(:, i);
        temp_y = util_unflatten_diagonal(temp_y);
        temp_y = reorder_matrix_by_atlas(temp_y, mapping_category);
        Y_rep(:, i) = temp_y(triumask);

    
    end
end