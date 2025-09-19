function edge_groups = get_edge_groups_from_meta_data(meta_data)

    if isfield(meta_data, 'edge_groups')
        edge_groups = meta_data.edge_groups;
        return;
    end

    if isfield(meta_data, 'rep_parameters')
        edge_groups = meta_data.rep_parameters.edge_groups;
        return;
    end

end