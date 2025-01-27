function [n_node_nets, trilmask_net, edge_groups] = extract_atlas_related_parameters(RP, Y)
    
    % Define parameters as NaN for cases where they are not necessary
    % These are only necessary in the - 'Constrained' and
    % 'Constrained_FWER'cases
    n_node_nets = NaN;
    trilmask_net = NaN;

    % Only apply atlas to the network-based stats
    if strcmp(RP.cluster_stat_type, 'Constrained') || strcmp(RP.cluster_stat_type, 'Omnibus') || ...
        strcmp(RP.cluster_stat_type, 'Constrained_FWER')
       
        template_net = summarize_matrix_by_atlas(Y(:, 1), RP.atlas_file, 'suppressimg', 1, 'mask', RP.mask);
    
        n_node_nets = size(template_net, 1); % square
        % trilmask_net = tril(true(n_node_nets));
  
        edge_groups = load_atlas_edge_groups(RP.n_nodes, RP.mapping_category, RP.atlas_file);
        % edge_groups = tril(edge_groups,-1);
        edge_groups = triu(edge_groups, 1);
        
    else
        % plus 1 because the script expects there to be a "0" (and will subsequently ignore..."
        %% TODO set edge groups to NaN if no atlas 
        edge_groups = sum(RP.mask(:));

    end


end