function create_edge_level_stats_in_file(file_path, file_type, n_var, n_repetitions, edge_groups, n_networks)


    switch file_type
        
        case 'full_file'

            edge_level_stats = NaN(n_var, n_repetitions);
            network_level_stats = NaN(n_networks, 1);

            save(file_path, 'edge_level_stats', 'network_level_stats', '-append');

        case 'compact_file'
            
            edge_level_stats = zeros(n_var, 1);
            network_level_stats = zeros(n_networks, 1);

            edge_mean_squared_error = zeros(n_var, 1);
            network_mean_squared_error = zeros(n_networks, 1);

            save(file_path, 'edge_level_stats', 'network_level_stats', ...
                'edge_mean_squared_error', 'network_mean_squared_error', '-append');

        otherwise
            error('File type not supported')

    end

end
