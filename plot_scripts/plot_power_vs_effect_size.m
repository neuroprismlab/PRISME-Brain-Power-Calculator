function plot_power_vs_effect_size(directory_path)
    % Plot power vs effect size from power calculation files
    % Input: directory_path - path to the directory containing power calculation files
    
    % Load files from the specified directory
    files = dir(fullfile(directory_path, '*.mat'));
    
    if isempty(files)
        error('No power calculation files found in %s', directory_path);
    end
    
    % Initialize structures to store results
    method_data = struct();
    effect_data = struct();
    unique_subject_numbers = []; 
    
    % Process each file
    for i = 1:numel(files)
        file_path = fullfile(files(i).folder, files(i).name);
        data = load(file_path);
        
        % Check if file has required metadata
        if ~isfield(data, 'meta_data') || ~isfield(data.meta_data, 'subject_number')
            warning('Skipping file (missing meta_data): %s', files(i).name);
            continue;
        end
        
        % Extract subject number
        n_subjects = data.meta_data.subject_number;
        
        % Track unique subject numbers
        if ~ismember(n_subjects, unique_subject_numbers)
            unique_subject_numbers = [unique_subject_numbers, n_subjects];
        end
        n_subjects_str = ['n_', num2str(n_subjects)];

        if ~isfield(effect_data, n_subjects_str)
            effect_data.(n_subjects_str) = struct();
        end
        
        % Use method list from metadata
        if ~isfield(data.meta_data, 'method_list')
            error('Method list missing in file %s', files(i).name);
        end
        
        % Extract edge and network level statistics       
        [sorted_edge_stats, edge_stats_index]  = ...
            sort(abs(data.edge_level_stats_mean) / max(abs(data.edge_level_stats_mean)));
        [sorted_network_stats, network_stats_index] = ...
            sort(abs(data.network_level_stats_mean) / max(abs(data.network_level_stats_mean)));
        
        if ~isfield(effect_data.(n_subjects_str), 'current_rep')
            effect_data.(n_subjects_str).current_rep = 1;
        else
            effect_data.(n_subjects_str).current_rep = ...
                effect_data.(n_subjects_str).current_rep + 1;
        end
        % For averaging tprs
        n = effect_data.(n_subjects_str).current_rep;

        % Average effect sizes using repetition count
        if n == 1
            effect_data.(n_subjects_str).edge = sorted_edge_stats;
            effect_data.(n_subjects_str).network = sorted_network_stats;
        else
            effect_data.(n_subjects_str).edge = ...
                ((n-1) * effect_data.(n_subjects_str).edge + sorted_edge_stats) / n;
            effect_data.(n_subjects_str).network = ...
                ((n-1) * effect_data.(n_subjects_str).network + sorted_network_stats) / n;
        end
        
        % Process each method
        method_data.(n_subjects_str) = struct();
        method_list = data.meta_data.method_list;
        for m = 1:length(method_list)
            method_name = method_list{m};   

            % Check if method exists in file
            if ~isfield(data, method_name)
                error('Method "%s" missing in file %s.', method_name, files(i).name);
            end
            
            method_result = data.(method_name);
            level = method_result.meta_data.level;

            % Skip Omnibus method
            if strcmpi(level, 'whole_brain')
                continue;
            end
            
            % Skip if necessary fields are missing
            if ~isfield(method_result, 'tpr')
                error('Method without tpr %s', [file_path, ' ', method_name]);
            end
            
            % Create method data structure if it doesn't exist

            % Extract TPR values
            if strcmpi(level, 'edge')
                sorted_tpr_values = method_result.tpr(edge_stats_index);
            elseif strcmpi(level, 'network')
                sorted_tpr_values = method_result.tpr(network_stats_index);
            else
                error('Level not supported')
            end
            
            % Store TPR and effect sizes
            if ~isfield(method_data.(n_subjects_str), method_name)
                method_data.(n_subjects_str).(method_name) = sorted_tpr_values;
            else
                method_data.(n_subjects_str).(method_name) = ... 
                    ((n - 1)*method_data.(n_subjects_str).(method_name) + sorted_tpr_values) / n;
            end
         
        end
    end
    
    % Check if we have results
    if isempty(fieldnames(method_data))
        error('No valid method data found.');
    end
    
    % Create figure for power vs effect size plots
    figure('Position', [100, 100, 1500, 400]);
    
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
    method_to_display('Omnibus_Multidimensional_cNBS') = 'whole brain';
    
    % Custom colors to match the figure
    custom_colors = [
        254, 231, 1;    % Yellow
        248, 148, 6;    % Orange
        86, 180, 233;   % Light Blue
        0, 114, 98;     % Green
        240, 65, 85;    % Red
        213, 94, 169;   % Purple
        0, 32, 91       % Navy Blue
    ] / 255;
    
    % Process data for power vs effect size plots
    for i = 1:num_subjects
        n_subjects = unique_subject_numbers(i);
        n_subjects_str = ['n_', num2str(n_subjects)];
        
        % Create subplot
        subplot(1, num_subjects, i);
        hold on;
        
        % Get available methods for this subject number
        if ~isfield(method_data, n_subjects_str)
            warning('No data for subject number %d', n_subjects);
            continue;
        end
        
        methods = fieldnames(method_data.(n_subjects_str));
        
        % Plot each method
        for j = 1:length(methods)
            method_name = methods{j};
            
            % Get color index based on method type
            method_index = 1; % Default to first color
            if isKey(method_to_display, method_name)
                display_name = method_to_display(method_name);
                if strcmp(display_name, 'edge')
                    method_index = 1;
                elseif strcmp(display_name, 'edge (fdr)')
                    method_index = 2;
                elseif strcmp(display_name, 'cluster')
                    method_index = 3;
                elseif strcmp(display_name, 'cluster tfce')
                    method_index = 4;
                elseif strcmp(display_name, 'network')
                    method_index = 5;
                elseif strcmp(display_name, 'network (fdr)')
                    method_index = 6;
                elseif strcmp(display_name, 'whole brain')
                    method_index = 7;
                end
            end
            
            % Get TPR data
            tpr = method_data.(n_subjects_str).(method_name);
            
            % Get matching effect sizes based on method level
            % (This assumes you've stored the method level in effect_data)
            if isfield(method_data.(n_subjects_str), [method_name '_level'])
                level = method_data.(n_subjects_str).([method_name '_level']);
                if strcmpi(level, 'edge')
                    effect_sizes = effect_data.(n_subjects_str).edge;
                elseif strcmpi(level, 'network')
                    effect_sizes = effect_data.(n_subjects_str).network;
                else
                    warning('Unsupported level "%s" for method "%s"', level, method_name);
                    continue;
                end
            else
                % Default to edge level if level not stored
                effect_sizes = effect_data.(n_subjects_str).edge;
            end
            
            % Make sure lengths match (take the shorter one)
            min_length = min(length(tpr), length(effect_sizes));
            tpr = tpr(1:min_length);
            effect_sizes = effect_sizes(1:min_length);
            
            % Create effect size bins
            bin_edges = 0:0.1:1;
            bin_centers = bin_edges(1:end-1) + 0.05;
            power_means = zeros(size(bin_centers));
            
            % Calculate average power for each bin
            for b = 1:length(bin_centers)
                bin_indices = effect_sizes >= bin_edges(b) & effect_sizes < bin_edges(b+1);
                if any(bin_indices)
                    power_means(b) = mean(tpr(bin_indices)) * 100; % Convert to percentage
                end
            end
            
            % Plot power vs effect size curve
            line_style = '-';
            if isKey(method_to_display, method_name) && contains(method_to_display(method_name), 'fdr')
                line_style = '--';
            end
            
            plot(bin_centers, power_means, line_style, 'LineWidth', 2, 'Color', custom_colors(method_index,:));
        end
        
        % Add reference lines
        line([0.5, 0.5], [0, 100], 'Color', [0.7, 0.7, 0.7], 'LineStyle', '--', 'LineWidth', 1.5); % d=0.5 line
        line([0, 1], [80, 80], 'Color', [0.7, 0.7, 0.7], 'LineStyle', '--', 'LineWidth', 1.5); % 80% power line
        
        % Format axes
        xlim([0, 1]);
        ylim([0, 100]);
        xlabel('Effect size (abs(d))', 'FontSize', 14);
        if i == 1
            ylabel('Power (%)', 'FontSize', 14);
        end
        title(['n = ', num2str(n_subjects)], 'FontSize', 16);
        set(gca, 'FontSize', 12);
        box off;
    end
    
    % Add legend to the last subplot
    subplot(1, num_subjects, num_subjects);
    display_names = {'edge', 'edge (fdr)', 'cluster', 'cluster tfce', 'network', 'network (fdr)', 'whole brain'};
    h = zeros(length(display_names), 1);
    
    for j = 1:length(display_names)
        line_style = '-';
        if contains(display_names{j}, 'fdr')
            line_style = '--';
        end
        h(j) = plot(NaN, NaN, line_style, 'LineWidth', 2, 'Color', custom_colors(j,:));
    end
    
    legend(h, display_names, 'Location', 'Southeast', 'FontSize', 10);
    
    % Print out subject numbers used
    fprintf('Subject numbers used in this analysis: %s\n', ...
        strjoin(arrayfun(@(x) num2str(x), unique_subject_numbers, 'UniformOutput', false), ', '));
end