function anp_plot_results_histogram(result_top_k, subject_map, method_map, n_top)
    % Plots comparison of methods for top n networks, averaged across studies
    % One histogram per subject size
    %
    % Inputs:
    %   result_top_k: 3D tensor [study, subject, method] with top-k power values
    %   subject_map: map from subject number to index
    %   method_map: struct with .display, .order, .color maps (from map_tfce_comp)
    %   n_top: number of top-powered networks analyzed
    
    % Extract maps from struct
    display_map = method_map.display;
    order_map = method_map.order;
    color_map = method_map.color;
    
    % Extract and sort subject labels by actual subject number
    subject_keys = keys(subject_map);
    subject_numbers = cellfun(@(x) str2double(x), subject_keys);
    [sorted_subject_numbers, sort_idx] = sort(subject_numbers);
    
    % Get the index mapping for sorted subjects
    sorted_subject_indices = zeros(length(subject_keys), 1);
    for i = 1:length(subject_keys)
        sorted_subject_indices(i) = subject_map(subject_keys{sort_idx(i)});
    end
    
    % Get display names in order (the tensor is already ordered by map.order)
    display_names = keys(order_map);
    num_methods = length(display_names);
    
    % Sort display names by their order value
    order_values = cell2mat(values(order_map));
    [~, order_sort_idx] = sort(order_values);
    sorted_display_names = display_names(order_sort_idx);
    
    num_subjects = length(subject_map);
    
    % Create figure with horizontal subplots (left to right)
    figure('Position', [100, 100, 250*num_subjects, 400]);
    set(gcf, 'Color', 'white');  % Figure background white
    
    for subj_idx = 1:num_subjects
        subplot(1, num_subjects, subj_idx);
        
        % Get the actual tensor index for this sorted subject
        tensor_subject_idx = sorted_subject_indices(subj_idx);
        
        % For each method (already in correct order in tensor)
        method_powers = zeros(num_methods, 1);
        colors = zeros(num_methods, 3);
        
        for method_idx = 1:num_methods
            display_name = sorted_display_names{method_idx};
            
            % Average across studies - tensor is already in display order
            method_powers(method_idx) = mean(result_top_k(:, tensor_subject_idx, method_idx), 'omitnan');
            
            % Get color for this method
            colors(method_idx, :) = color_map(display_name);
        end
        
        % Plot bar chart with individual colors
        b = bar(method_powers);
        b.FaceColor = 'flat';
        b.CData = colors;
        b.EdgeColor = 'none';  % Remove black outline
        
        set(gca, 'XTick', 1:num_methods, 'XTickLabel', sorted_display_names);
        xlabel('Method', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Average Power (%)', 'FontSize', 11, 'FontWeight', 'bold');
        title(sprintf('N = %d', sorted_subject_numbers(subj_idx)), 'FontSize', 12, 'FontWeight', 'bold');
        xtickangle(45);
        ylim([0 100]);
        set(gca, 'FontSize', 10);
    end
    
    sgtitle(sprintf('Top %d Network - Method Comparison', n_top), 'FontSize', 14, 'FontWeight', 'bold');
end