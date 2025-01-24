function RepData = add_gt_location_to_rep_data(path_cell, RepData, gt_origin)
    
    %% To finish
    % This function must add the query cell to the Rep_Data 
    %
    % The query contains the location of the ground truth in its respective
    % struct 

    switch gt_origin

        case 'effect_size'

            meta_data = getfield(RepData, path_cell{:});
            query_cell = gt_query_cell_generator(meta_data);
            query_cell = add_gt_info_to_query(query_cell, meta_data);
        
            gt_meta_data_cell_query = [query_cell(1:end-3), {'study_info'}];
            
            % add gt_name to ground truth
            final_path_cell = [path_cell, {'gt_location'}];
            meta_data_path_cell = [path_cell, {'gt_meta_data_location'}];
                
            RepData = setfield(RepData, final_path_cell{:}, query_cell);
            RepData = setfield(RepData, meta_data_path_cell{:}, gt_meta_data_cell_query);
        
        case 'power_calculator'

            meta_data = getfield(RepData, path_cell{:});
            base_query = gt_query_cell_generator(meta_data);
            
            [brain_data_query, meta_data_query, ~] = ...
                    power_calculator_query_constructor(base_query, meta_data);              
            
            % Add location to gt
            final_path_cell = [path_cell, {'gt_location'}];
            meta_data_path_cell = [path_cell, {'gt_meta_data_location'}];

            RepData = setfield(RepData, final_path_cell{:}, brain_data_query);
            RepData = setfield(RepData, meta_data_path_cell{:}, meta_data_query);

        otherwise 

            error('Origin of ground truth data was not specified')
            
    end

end
