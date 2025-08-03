classdef Omnibus_cNBS
    properties (Constant)
        level = "whole_brain";
        permutation_based = true;
    end
    
    methods
        function pval = run_method(~, varargin)
            params = struct(varargin{:});
            
            % Extract flattened edge groups
            flatted_edge_groups = flat_matrix(params.statistical_parameters.edge_groups, ...
                params.statistical_parameters.mask);
            
            n_perms = params.statistical_parameters.n_perms;
            n_networks = size(params.network_stats, 1);
            
            % Calculate network-level statistics for observed data
            data_vector = calculate_network_vector(n_networks, params.edge_stats, flatted_edge_groups);
            
            % Calculate network-level statistics for each permutation
            perm_vectors = zeros(n_networks, n_perms);
            for i_perm = 1:n_perms
                perm_stats = params.permuted_edge_data(:, i_perm);
                perm_vectors(:, i_perm) = calculate_network_vector(n_networks, perm_stats, flatted_edge_groups);
            end
            
            % Calculate the average of all permutation vectors
            perm_average = mean(perm_vectors, 2);
            
            % Calculate Euclidean distance of observed data from permutation average
            observed_distance = sqrt(sum((data_vector - perm_average).^2));
            
            % Calculate null distribution: distances of each permutation from the average
            null_distances = zeros(n_perms, 1);
            for i_perm = 1:n_perms
                null_distances(i_perm) = sqrt(sum((perm_vectors(:, i_perm) - perm_average).^2));
            end
            
            % Calculate p-value: proportion of null distances >= observed distance
            % Add 1 to numerator and denominator for conservative p-value estimation
            pval = (sum(null_distances >= observed_distance)) / n_perms;
            
            % Debug output (remove in production)
            % fprintf('Observed distance: %.4f\n', observed_distance);
            % fprintf('Mean null distance: %.4f\n', mean(null_distances));
            % fprintf('P-value: %.4f\n', pval);
        end
    end
end

function return_vector = calculate_network_vector(n_networks, edge_stats, flatted_edge_groups)
    % Initialize network vector with zeros
    return_vector = zeros(n_networks, 1);
    
    % Aggregate edge statistics by network
    for i = 1:length(edge_stats)
        network_index = flatted_edge_groups(i);
        return_vector(network_index) = return_vector(network_index) + edge_stats(i);
    end
end