function plot_power_proportion(directory_path)
    % Plot proportion of effects having power above a threshold vs power threshold
    % Input: directory_path - path to the directory containing power calculation files
    
    % Load files from the specified directory
    files = dir(fullfile(directory_path, '*.mat'));
    
    if isempty(files)
        error('No power calculation files found in %s', directory_path);
    end
    
    % Initialize structures to store results
    method_data = struct();
    unique_subject_numbers = [];
    tpr_x_axis = 0:0.5:100;
    
    % Process each file
    for i = 1:numel(files)
        file_path = fullfile(files(i).folder, files(i).name);
        data = load(file_path);
      
        % Extract subject number
        n_subjects = data.meta_data.subject_number;
        
        % Track unique subject numbers
        if ~ismember(n_subjects, unique_subject_numbers)
            unique_subject_numbers = [unique_subject_numbers, n_subjects];
        end
        n_subjects_str = ['n_', num2str(n_subjects)];

        % Process each method
        if ~isfield(method_data, n_subjects_str)
            method_data.(n_subjects_str) = struct();
        end
        
        method_list = data.meta_data.method_list;
        for m = 1:length(method_list)
            method_name = method_list{m};   

            % Skip whole_brain method as requested
            if strcmpi(method_name, 'Omnibus_Multidimensional_cNBS')
                continue;
            end
           
            method_result = data.(method_name);
          
            level = method_result.meta_data.level;
           
            % Skip Omnibus method
            if strcmpi(level, 'whole_brain')
                continue;
            end

            if ~isfield(method_data.(n_subjects_str), method_name)
                method_data.(n_subjects_str).(method_name) = ...
                    zeros(size(tpr_x_axis));                
            end 

            sorted_tpr = sort(method_result.tpr); 
            
            t_i = 1;
            t = tpr_x_axis(t_i);
            for j = 1:numel(sorted_tpr)
                s = sorted_tpr(j);

                while s > t
                    t_i = t_i + 1;
                    t = tpr_x_axis(t_i);
                end
                
                method_data.(n_subjects_str).(method_name)(t_i) = ...
                    method_data.(n_subjects_str).(method_name)(t_i) + 1;  
            end      

        end
    end

    % After your accumulation loop, add this normalization step
    for subject_index = 1:numel(unique_subject_numbers)
        n_subjects = unique_subject_numbers(subject_index);
        n_subjects_str = ['n_', num2str(n_subjects)];

        for m = 1:length(method_list)
            method_name = method_list{m};   
           
            method_result = data.(method_name);
          
            level = method_result.meta_data.level;
           
            % Skip Omnibus method
            if strcmpi(level, 'whole_brain')
                continue;
            end
            
            % Normalize counts to get proportions
            total_count = sum(method_data.(n_subjects_str).(method_name));
    
            for j = numel(tpr_x_axis)-1:-1:1
                method_data.(n_subjects_str).(method_name)(j) = ...
                        method_data.(n_subjects_str).(method_name)(j) + ...
                        method_data.(n_subjects_str).(method_name)(j + 1) ; 
            end
             
            method_data.(n_subjects_str).(method_name) = ...
                method_data.(n_subjects_str).(method_name) / total_count;
        end
    end
    
    % Create figure with high resolution and appropriate dimensions
    figure_width = 2000;  % Width in pixels (increased for better quality)
    figure_height = 400; % Height in pixels
    figure('Position', [100, 100, figure_width, figure_height], 'Color', 'white');
    
    % Sort subject numbers
    unique_subject_numbers = sort(unique_subject_numbers);
    num_subjects = numel(unique_subject_numbers);
    
    % Define method display names and mapping
    method_to_display = containers.Map();
    method_to_display('Parametric_FWER') = 'edge';
    method_to_display('Parametric_FDR') = 'edge (fdr)';
    method_to_display('Size') = 'cluster';
    method_to_display('Fast_TFCE') = 'cluster tfce';
    method_to_display('Constrained_FWER') = 'network';
    method_to_display('Constrained_FDR') = 'network (fdr)';
    
    % Custom colors to match the figure
    custom_colors = [
        254, 231, 1;    % Yellow (edge)
        248, 148, 6;    % Orange (edge fdr)
        86, 180, 233;   % Light Blue (cluster)
        0, 114, 98;     % Green (cluster tfce)
        240, 65, 85;    % Red (network)
        213, 94, 169;   % Purple (network fdr)
    ] / 255;
    
    % Create a tight layout for the subplots
    padding = 0.04;
    margin = 0.1;
    width = (1 - 2*margin - (num_subjects-1)*padding) / num_subjects;
    heights = 1 - 2*margin;
    
    % Define line handles for the legend
    line_handles = cell(6, 1);
    display_names = {'edge', 'edge (fdr)', 'cluster', 'cluster tfce', 'network', 'network (fdr)'};
    
    % Process data for each subject number
    for i = 1:num_subjects
        n_subjects = unique_subject_numbers(i);
        n_subjects_str = ['n_', num2str(n_subjects)];
        
        % Calculate position for this subplot
        left = margin + (i-1)*(width + padding);
        bottom = margin;
        
        % Create subplot with precise positioning
        ax = axes('Position', [left, bottom, width, heights]);
        hold on;
        
        % Skip if no data
        if ~isfield(method_data, n_subjects_str)
            warning('No data for subject number %d', n_subjects);
            continue;
        end
        
        % Get available methods
        methods = fieldnames(method_data.(n_subjects_str));
        
        % Process each method
        for j = 1:length(methods)
            method_name = methods{j};
            
            % Skip if not in our display mapping
            if ~isKey(method_to_display, method_name)
                continue;
            end
            
            % Find corresponding method in our mapping
            method_idx = find(strcmp({
                'Parametric_FWER', 
                'Parametric_FDR', 
                'Size', 
                'Fast_TFCE', 
                'Constrained_FWER', 
                'Constrained_FDR'
            }, method_name));
            
            if isempty(method_idx)
                continue; % Skip if no matching method found
            end
            
            % Get display name
            display_name = method_to_display(method_name);
            
            % Get the already normalized proportions
            proportion_above = method_data.(n_subjects_str).(method_name);
            
            % Plot power curve
            line_style = '-';
            if contains(display_name, 'fdr')
                line_style = '--';
            end
            
            h = plot(tpr_x_axis, proportion_above, line_style, 'LineWidth', 2.5, 'Color', custom_colors(method_idx,:));
            
            % Store handle for legend
            line_handles{method_idx} = h;
            
            % Add annotations at specific power levels (e.g., at 80% power)
            power_annotation = 80; % 80% power threshold
            idx = find(tpr_x_axis >= power_annotation, 1, 'first');
            if ~isempty(idx) && idx <= length(proportion_above)
                proportion = proportion_above(idx);
                % Mark the point on the curve
                plot(power_annotation, proportion, 'o', 'MarkerSize', 8, 'MarkerFaceColor', custom_colors(method_idx,:), 'MarkerEdgeColor', 'none');
                
                % Add text annotation for percentage
                text(power_annotation + 2, proportion, [num2str(round(proportion*100)), '%'], ...
                    'FontSize', 9, 'Color', custom_colors(method_idx,:), 'FontWeight', 'bold');
            end
        end
        
        % Add reference line at 80% power
        line([80, 80], [0, 1], 'Color', [0.7, 0.7, 0.7], 'LineStyle', '--', 'LineWidth', 1.5);
        
        % Format axes
        xlim([0, 100]);
        ylim([0, 1]);
        if i == 1 % Only first subplot needs y-axis label
            ylabel('Proportion effects with >λ% power', 'FontSize', 14, 'FontWeight', 'bold');
        else
            set(ax, 'YTickLabel', []);
        end
        xlabel('Power threshold (%)', 'FontSize', 14, 'FontWeight', 'bold');
        title(['n = ', num2str(n_subjects)], 'FontSize', 16, 'FontWeight', 'bold');
        
        % Enhance grid and appearance
        grid on;
        set(ax, 'FontSize', 12, 'LineWidth', 1.5, 'Box', 'on');
        set(ax, 'GridAlpha', 0.15);
        
        % Add axis breaks at important percentages
        xticks([0 20 40 60 80 100]);
        yticks([0 0.2 0.4 0.6 0.8 1.0]);
    end
    
    % Create separate legend
    legFig = figure('Position', [200, 200, 400, 300], 'Color', 'white');
    ax = axes('Position', [0.1, 0.1, 0.8, 0.8], 'Visible', 'off');
    
    % Filter out empty handles
    valid_handles = [];
    valid_names = {};
    for i = 1:length(line_handles)
        if ~isempty(line_handles{i})
            valid_handles = [valid_handles, line_handles{i}];
            valid_names{end+1} = display_names{i};
        end
    end
    
    % Create legend
    leg = legend(valid_handles, valid_names, 'FontSize', 14, 'Location', 'best');
    title(leg, 'Analysis Methods');
    
    % Set legend properties
    legend('boxoff');
    legend('Location', 'Best');

    % Main figure
    figure(1);
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPositionMode', 'auto');
    set(gcf, 'Renderer', 'painters'); % For vector quality
    saveas(gcf, './plot_scripts/power_proportion.png');
    print('-dpng', '-r300', 'power_proportion_figure.png');  
 
end