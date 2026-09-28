function  [edge_groups, n_node_nets] = csv_atlas_extraction(atlas_file)
   
    atlas = readtable(atlas_file);
    n_node_nets = size(atlas, 1);
    roi_number = height(atlas);
    edge_groups = zeros(roi_number, roi_number);
    
    %  group_id = i*(i-1)/2 + j;

    for i = 1:height(atlas)
        roi1 = atlas.newroi(i);
        l1 = atlas.category(i);

        for j = 1:height(atlas)
            roi2 = atlas.newroi(j);
            l2 = atlas.category(j);
            
            if roi2 >= roi1
                continue
            end

            group_id = l1*(l1 - 1)/2 + l2;
            edge_groups(roi1, roi2) = group_id;

        end

    end
  
    edge_groups = edge_groups + edge_groups';

end