function network_effect_size_from_gt(gt_file)

    gt_data = load(gt_file);


    [sorted_effects, sorted_indices] = sort(gt_data.network_level_stats, 'descend');

    for i = 1:numel(sorted_indices)
        fprintf('Network %d has effect %d\n', sorted_indices(i), sorted_effects(i))
    end
    
    %edge_groups = load_atlas_edge_groups(atlas_file);

end