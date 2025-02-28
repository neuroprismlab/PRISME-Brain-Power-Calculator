function [n_node_nets, trilmask_net, edge_groups] = extract_atlas_related_parameters(RP, Y)
    
    % Define parameters as NaN for cases where they are not necessary
    % These are only necessary in the - 'Constrained' and
    % 'Constrained_FWER'cases
    n_node_nets = NaN;
    trilmask_net = NaN;
    edge_groups = NaN;

    % Only apply atlas to the network-based stats
    if ~isnan(RP.atlas_file)
       
        template_net = summarize_matrix_by_atlas(Y(:, 1), RP.atlas_file, 'suppressimg', 1, 'mask', RP.mask);
    
        n_node_nets = size(template_net, 1); % square
        % trilmask_net = tril(true(n_node_nets));
    
        edge_groups = load_atlas_edge_groups(RP.atlas_file);
        % edge_groups = tril(edge_groups,-1);
        edge_groups = triu(edge_groups, 1);
        
    end

end