function plot_power_results(dataset_or_directory)

    % function calls for paper for easy usage:
    % plot_power_results('/Users/f.cravogomes/Desktop/Cloned Repos/Power_Calculator/power_calculator_results/power_calculation/abcd_100_reps')
    
    % Change this to remove some of the subjects
    undesired_subject_numbers = {20, 200};
    
    files = data_set_or_directory_mat_file_loading(dataset_or_directory, 'sub_directory', '/power_calculation/');

    % Initialize structure to store power results
    power_results = struct();
    unique_subject_numbers = []; 

    % Process each file
    for i = 1:numel(files)
        file_path = fullfile(files(i).folder, files(i).name);
        data = load(file_path);
          
        n_subjects = get_sub_number_from_meta_data(data.meta_data);

        % Keep track of unique subject numbers
        if ~ismember(n_subjects, unique_subject_numbers)
            unique_subject_numbers = [unique_subject_numbers, n_subjects]; %#ok<AGROW>
        end

        % Use method list from metadata
        method_list = data.meta_data.method_list;

        for m = 1:length(method_list)
            method_name = method_list{m};

            % Check if method exists in file
            if ~isfield(data, method_name)
                warning('Method "%s" missing in file %s. Skipping...', method_name, files(i).name);
                continue;
            end

            method_data = data.(method_name);

            % Skip if TPR field is missing
            if ~isfield(method_data, 'tpr')
                continue;
            end

            % Extract and flatten TPR values
            tpr_values = method_data.tpr(:);

            % Derive task component info
            test_components = get_test_components_from_meta_data(data.meta_data);

            % Define path: power_results.method.n_<subjects>.task_type = mean(tpr)
            field_path = {method_name, sprintf('n_%d', n_subjects), test_components};

            % Store result
            power_results = setfield(power_results, field_path{:}, mean(tpr_values));
        end
    
    end
    
    % Check if we have results
    if isempty(fieldnames(power_results))
        error('No valid power results found.');
    end

    % Sort subject numbers and methods
    unique_subject_numbers = sort(unique_subject_numbers);

    % Remove undesired subject number
    unique_subject_numbers = sort(unique_subject_numbers(~ismember(unique_subject_numbers, ...
        [undesired_subject_numbers{:}])));
    
    subject_labels = arrayfun(@(x) sprintf('nsub %d', x), unique_subject_numbers, 'UniformOutput', false);
    num_subjects = numel(unique_subject_numbers);
    method_names = fieldnames(power_results);
    plot_method_names = strrep(method_names, '_', ' ');
    num_methods = numel(method_names);

    % Collect power data
    for i = 1:num_subjects
        n_subjects = unique_subject_numbers(i);

        for j = 1:num_methods
            method_name = method_names{j};
            
            if isfield(power_results.(method_name), sprintf('n_%d', n_subjects))
                % Extract all task-specific power values
                task_values = struct2cell(power_results.(method_name).(sprintf('n_%d', n_subjects)));
    
                % Convert to array
                all_task_values = cell2mat(task_values);
                
                % Compute mean and standard error
                mean_power(i, j) = mean(all_task_values, 'omitnan');
                error_power(i, j) = std(all_task_values, 'omitnan') / sqrt(length(all_task_values));
            end
        end
    end
    
    % Create mapping from internal method names to display names
    method_to_display = containers.Map();
    method_to_display('Parametric_FWER') = 'edge';
    method_to_display('Parametric_FDR') = 'edge (fdr)';
    method_to_display('Size_cpp') = 'cluster';
    method_to_display('Size') = 'cluster';
    method_to_display('Fast_TFCE_cpp') = 'cluster tfce';
    method_to_display('Fast_TFCE') = 'cluster tfce';
    method_to_display('Constrained_cpp_FWER') = 'network';
    method_to_display('Constrained_FWER') = 'network';
    method_to_display('Constrained_cpp_FDR') = 'network (fdr)';
    method_to_display('Constrained_FDR') = 'networkm (fdr)';
    method_to_display('Omnibus_Multidimensional_cNBS') = 'whole brain';
    
    % Create mapping from internal method names to display order
    method_to_index = containers.Map();
    method_to_index('Parametric_FWER') = 1;
    method_to_index('Parametric_FDR') = 2;
    method_to_index('Size_cpp') = 3;
    method_to_index('Size') = 3;
    method_to_index('Fast_TFCE_cpp') = 4;
    method_to_index('Fast_TFCE') = 4;
    method_to_index('Constrained_cpp_FWER') = 5;
    method_to_index('Constrained_FWER') = 5;
    method_to_index('Constrained_cpp_FDR') = 6;
    method_to_index('Constrained_FDR') = 6;
    method_to_index('Omnibus_Multidimensional_cNBS') = 7;
    
    % Define the display order and names for the plot
    display_order = 1:7;
    display_names = {'edge', 'edge (fdr)', 'cluster', 'cluster rtce', 'network', 'network (fdr)', 'whole brain'};
    
    % Create arrays to hold the reordered data
    reordered_mean = zeros(num_subjects, 7);
    reordered_error = zeros(num_subjects, 7);
    
    % Map the data to the display order
    for i = 1:num_subjects
        for j = 1:num_methods
            method_name = method_names{j};
            if isKey(method_to_index, method_name)
                idx = method_to_index(method_name);
                reordered_mean(i, idx) = mean_power(i, j);
                reordered_error(i, idx) = error_power(i, j);
            end
        end
    end

    
        % Generate a figure with high resolution and appropriate dimensions
    figure_width = 2000;  % Width in pixels (increased for better quality)
    figure_height = 400;  % Height in pixels
    figure('Position', [100, 100, figure_width, figure_height], 'Color', 'white');
    
    % Custom colors to match the figure
    custom_colors = [
        254, 231, 1;    % Yellow (edge)
        248, 148, 6;    % Orange (edge fdr)
        86, 180, 233;   % Light Blue (cluster)
        0, 114, 98;     % Green (cluster tfce)
        240, 65, 85;    % Red (network)
        213, 94, 169;   % Purple (network fdr)
        0, 32, 91       % Navy Blue (whole brain)
    ] / 255;
    
    
    % Create a tight layout for the subplots
    padding = 0.04;
    margin = 0.2;
    width = (1 - 2*margin - (num_subjects-1)*padding) / num_subjects;
    heights = 1 - 2*margin;
    
    % Process data for each subject number
    for i = 1:num_subjects
        % Calculate position for this subplot
        left = margin + (i-1)*(width + padding);
        bottom = margin;
        
        % Create subplot with precise positioning
        ax = axes('Position', [left, bottom, width, heights]);
        
        % Create bar chart for this subject number
        h = bar(reordered_mean(i, :), 0.7);
        h.FaceColor = 'flat';
        
        % Apply custom colors
        for j = 1:7
            h.CData(j, :) = custom_colors(j, :);
        end
        
        % Add error bars
        hold on;
        errorbar(1:7, reordered_mean(i, :), reordered_error(i, :), '.k', 'LineWidth', 1.5);
        
        % Add subject number as title
        title(['n = ', num2str(unique_subject_numbers(i))], 'FontSize', 30, 'FontWeight', 'bold');
        
        % Add 80% reference line
        line([0, 8], [80, 80], 'Color', [0.7, 0.7, 0.7], 'LineStyle', '--', 'LineWidth', 1.5);
        
        % Format axes
        set(gca, 'XTick', 1:7, 'XTickLabel', display_names, 'XTickLabelRotation', 45);
        ylim([0, 100]);
        
        % Set y-label only for first subplot
        if i == 1
            ylabel('Average power (%)', 'FontSize', 18, 'FontWeight', 'bold');
        else
            set(ax, 'YTickLabel', []);
        end
        
        % Enhance grid and appearance
        grid off;
        set(ax, 'FontSize', 16, 'LineWidth', 1.5, 'Box', 'on');
        set(ax, 'GridAlpha', 0.15);
        
        % Add axis ticks at important percentages
        yticks([0 20 40 60 80 100]);
    end
    
    % Create separate legend
    legFig = figure('Position', [200, 200, 400, 300], 'Color', 'white');
    ax = axes('Position', [0.1, 0.1, 0.8, 0.8], 'Visible', 'off');
    
    % Create dummy bars for legend
    leg_handles = zeros(1, 7);
    for j = 1:7
        leg_handles(j) = bar(j, 0);
        set(leg_handles(j), 'FaceColor', custom_colors(j,:));
        hold on;
    end
    
    % Create legend
    leg = legend(leg_handles, display_names, 'FontSize', 18, 'Location', 'best');
    title(leg, 'Analysis Methods');
    
    % Set legend properties
    legend('boxoff');
    legend('Location', 'Best');
    
    % Main figure
    figure(1);
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPositionMode', 'auto');
    set(gcf, 'Renderer', 'painters'); % For vector quality
    saveas(gcf, './plot_scripts/power_results.png');
    print('-dpng', '-r300', 'power_results_figure.png');
end

