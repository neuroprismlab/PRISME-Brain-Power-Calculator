function brain_data = extract_gt_brain_data(gt_data, stat_level)

    switch stat_level

        case 'edge'
            brain_data = gt_data.brain_data.edge_stats_all;
        
        case 'network'
            brain_data = gt_data.brain_data.cluster_stats_all;

        case 'whole_brain'
            brain_data = gt_data.brain_data.cluster_stats_all;
        
        otherwise
            error('Stat level type not supported')

    end


end
