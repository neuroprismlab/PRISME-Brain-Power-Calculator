function [cluster_stat] = get_constrained_stats(test_stat, edge_groups)
%GET_CONSTRAINED_STATS
% Summarize stats by network defined by atlas
% TODO: add option to do scaled by weight
% TODO: consider also calculating variance across edges within group
% TODO: consider whether we should make inputs/mask be symmetric or force
% them to be upper/lower triangular (if inputs and mask are symmetric, run
% risk of double counting. Maybe best is symmetric input / lower tril mask)

n_networks = numel(unique(nonzeros(edge_groups)));
cluster_stat = zeros(1, n_networks);
n_edge_net = zeros(1, n_networks);

for i = 1:numel(edge_groups)
    i_net = edge_groups(i);
    n_edge_net(i_net) = n_edge_net(i_net) + 1;
    cluster_stat(i_net) = cluster_stat(i_net) + test_stat(i);
end

cluster_stat = cluster_stat ./ n_edge_net;