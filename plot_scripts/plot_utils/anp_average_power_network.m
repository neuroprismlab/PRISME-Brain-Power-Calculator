function avg_power_per_network = anp_average_power_network(file_data, method_name, ...
    attribute, flat_edge_groups, num_networks)
    % Calculates average power per network for a single file/method
    %
    % Inputs:
    %   file_data: loaded .mat file data
    %   method_name: string, name of method (e.g., 'tfce')
    %   attribute: string, attribute to extract (e.g., 'tpr')
    %   flat_edge_groups: flattened array of network assignments
    %   flat_matrix_fun: function to flatten matrices
    %   num_networks: number of networks
    %
    % Output:
    %   avg_power_per_network: array of size [num_networks, 1] with average power per network
    
    % Extract power values for this method
    power_values = file_data.(method_name).(attribute);
    
    % Initialize accumulators
    network_sums = zeros(num_networks, 1);
    network_counts = zeros(num_networks, 1);
    
    % Loop over variables once - O(n)
    for var_idx = 1:length(flat_edge_groups)
        network_idx = flat_edge_groups(var_idx);
        if network_idx > 0  % Skip variables not in any network

            try
                network_sums(network_idx) = network_sums(network_idx) + power_values(var_idx);
                network_counts(network_idx) = network_counts(network_idx) + 1;
            catch ME
                continue
            end

        end
    end
    
    % Calculate averages
    avg_power_per_network = network_sums ./ network_counts;
end