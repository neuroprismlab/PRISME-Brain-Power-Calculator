function query_cell = add_gt_info_to_query(query_cell, meta_data)
    
    switch true

        case (strcmp(meta_data.test_type, 'Constrained') || strcmp(meta_data.test_type, 'Constrained_FWER'))
            query_cell = [query_cell, {'data', 'pooling_net_motion_none_mv_none', 'stat'}];
        otherwise 
            query_cell = [query_cell, {'data', 'pooling_none_motion_none_mv_none', 'stat'}];
            
    end 

end 