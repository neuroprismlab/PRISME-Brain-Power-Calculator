% Maybe define it locally? Is only used by pfor_repetition_loop
function Y_rep = apply_atlas_order(Y_rep, ... 
                                   mapping_category, mask, ...
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
                        
        % - reorder_matrix_by_atlas only applies to shen atlas
        % - full information before reordering
        temp_y = unflatten_matrix(Y_rep(:, i), mask);
        temp_y = reorder_matrix_by_atlas(temp_y, mapping_category);
        Y_rep(:, i) = flat_matrix(temp_y, mask);

    end

end
