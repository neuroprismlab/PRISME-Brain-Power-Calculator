function [edge_level_stats_mean, network_level_stats_mean, edge_level_stats_std, network_level_stats_std] = ...
    calculate_edge_stats(file_type, rep_data)
    
    switch file_type

        case 'full_file'
            % Calculate means and standard deviations from full data
            edge_level_stats_mean = mean(rep_data.edge_level_stats, 2);
            network_level_stats_mean = mean(rep_data.network_level_stats, 2);
            edge_level_stats_std = std(rep_data.edge_level_stats, 0, 2);
            network_level_stats_std = std(rep_data.network_level_stats, 0, 2);
            
        case 'compact_file'

            % For compact files: stats are sums, need to divide by n_repetitions
            n_reps = rep_data.meta_data.n_repetitions;  % Assuming this is stored
            
            % Calculate means from sums
            edge_level_stats_mean = rep_data.edge_level_stats / n_reps;
            network_level_stats_mean = rep_data.network_level_stats / n_reps;
            
            % Avoid division by zero
            if n_reps == 1
                n_reps = 2;
            end
            
            % Calculate std from Welford's algorithm results
            edge_level_stats_std = sqrt(rep_data.edge_mean_squared_error / (n_reps - 1));
            network_level_stats_std = sqrt(rep_data.network_mean_squared_error / (n_reps - 1));
            
        otherwise
            error('Unknown file type: %s', file_type);
    end

end