function util_placeholder_1()
%if FPR, use the predefined task order
    if ~do_TPR
        if switch_task_order(i,this_repetition)
            this_task1=task2; 
            this_task2=task1;
        else
            this_task1=task1; 
            this_task2=task2;
        end
    else
        this_task1=task1;
        this_task2=task2;
    end
    
    for i = 1:n_subs_subset
        this_file_task1 = [data_dir,this_task1,'/',subIDs{ids_thisrep(i)},'_',this_task1,data_type_suffix];
        d=importdata(this_file_task1);
        d=reorder_matrix_by_atlas(d,mapping_category); % reorder bc proximity matters for SEA and cNBS
        m_test(:,i) = d(triumask);
    end

    for i = n_subs_subset+1:n_subs_subset*2
        this_file_task2 = [data_dir,this_task2,'/',subIDs{ids_thisrep(i)},'_',this_task2,data_type_suffix];
        d=importdata(this_file_task2);
        d=reorder_matrix_by_atlas(d,mapping_category); % reorder bc proximity matters for SEA and cNBS
        m_test(:,i) = d(triumask);
    end
end