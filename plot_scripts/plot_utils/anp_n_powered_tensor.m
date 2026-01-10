function top_power_tensor = anp_n_powered_tensor(results_tensor, n_top)
    % Extracts the n highest powered networks for each (study, subject, method)
    %
    % Inputs:
    %   results_tensor: 4D tensor [study, subject, method, network]
    %   n_top: number of top networks to keep
    %
    % Output:
    %   top_power_tensor: 4D tensor [study, subject, method, n_top]
    %                     (contains only the top n power values)
    
    [num_studies, num_subjects, num_methods, ~] = size(results_tensor);
    top_power_tensor = zeros(num_studies, num_subjects, num_methods);
    
    for i = 1:num_studies
        for j = 1:num_subjects
            for k = 1:num_methods
                % Get network power array for this combination
                network_powers = squeeze(results_tensor(i, j, k, :));
                
                % Find top n values and take the n-th one (the smallest of the top n)
                top_values = maxk(network_powers, n_top);
                top_power_tensor(i, j, k) = top_values(end);  % The n-th highest value
            end
        end
    end
end