% Maybe define it locally? Is only used by pfor_repetition_loop
function Y_rep = pf_single_atlas_order(Y_rep, i_rep, ...
                                               mapping_category, triumask, switch_task_order)

    % if FPR, use the predefined task order
    if ~do_TPR && false
        if switch_task_order(i_rep, this_repetition)
            task_flipper=-1;
        else
            task_flipper=1;
        end
    else
        task_flipper=1;
    end
    task_flipper=1;
    
    %if use_preaveraged_constrained % no reordering TODO: add above as well
    %    for i = 1:n_subs_subset
    %        m_test(:,i) = task_flipper * util_extract_subject_data(Brain_Data, task_1, rep_sub_ids);
    %    end
    %else
    
    %% TODO: Move this
    for i = 1:n_subs_subset
        temp_y = Y_rep(:, i);
        temp_y = util_unflatten_diagonal(temp_y);
        temp_y = reorder_matrix_by_atlas(temp_y, mapping_category);
        Y_rep(:, i) = temp_y(triumask);
    end
  

end