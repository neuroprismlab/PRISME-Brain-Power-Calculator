function flat_edge_groups = flatten_edge_groups(edge_groups, mask)
    
     % Extract the elements from the matrix where mask is true
    flat_edge_groups = edge_groups(mask);

end