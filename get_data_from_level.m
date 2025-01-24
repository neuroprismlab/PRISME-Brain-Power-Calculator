function gt_data = get_data_from_level(gt_data, stat_level)

    switch stat_level

        case 'edge'
            gt_data = gt_data.edge_stats_all;
         
        case 'network'
            gt_data = gt_data.cluster_stats_all;

        case 'whole_brain'
            gt_data = gt_data.cluster_stats_all;

        otherwise
            error('Stat level not supported')

    end

end