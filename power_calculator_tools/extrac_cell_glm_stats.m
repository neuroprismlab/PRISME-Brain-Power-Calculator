function [edge_stats_all, edge_stats_all_neg, cluster_stats_all, cluster_stats_all_neg] = ...
            extrac_cell_glm_stats(GLM_stats)

    % Extract all repetitions and concatenate them correctly
    edge_stats_all = cellfun(@(x) x.edge_stats, GLM_stats, 'UniformOutput', false);
    edge_stats_all = horzcat(edge_stats_all{:}); % Concatenate across repetitions

    edge_stats_all_neg = cellfun(@(x) x.edge_stats_neg, GLM_stats, 'UniformOutput', false);
    edge_stats_all_neg = horzcat(edge_stats_all_neg{:});

    cluster_stats_all = cellfun(@(x) x.cluster_stats, GLM_stats, 'UniformOutput', false);
    cluster_stats_all = horzcat(cluster_stats_all{:});

    cluster_stats_all_neg = cellfun(@(x) x.cluster_stats_neg, GLM_stats, 'UniformOutput', false);
    cluster_stats_all_neg = horzcat(cluster_stats_all_neg{:});

end