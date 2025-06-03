function generate_edge_map_vector_file(output_file)

    % /Users/f.cravogomes/Desktop/Cloned Repos/Learn_FC_Feture_Selection/network_edge_groups.mat
    % Change atlas file name for other atlases
    atlas_file = './atlas_storage/map268_subnetwork.mat';
    edge_groups = load_atlas_edge_groups(atlas_file);
    
    data_set_file = './data/s_hcp_fc_noble_tasks.mat';
    data = load(data_set_file);

    edge_groups = flat_matrix(edge_groups, data.study_info.mask);
    
    % Save the edge groups mapping
    save(output_file, 'edge_groups');

    fprintf('Edge mapping saved to: %s\n', output_file);

end