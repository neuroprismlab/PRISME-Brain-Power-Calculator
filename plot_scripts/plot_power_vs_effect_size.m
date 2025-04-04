function plot_power_vs_effect_size(dir_path)
    % PLOT_POWER_VS_EFFECT_SIZE Creates a plot of statistical power vs effect size
    % 
    % Input:
    %   dir_path - Path to a directory containing power analysis .mat files
    %
    % This function reads all .mat files in the given directory, extracts power data
    % and effect sizes, averages them by method, and creates a plot showing the
    % relationship between effect size and statistical power.
    
    % Get all .mat files in the directory
    files = dir(fullfile(dir_path, '*.mat'));
    
    % Initialize structure to store data by method
    methods_data = struct();
    
    % Process each file
    for i = 1:length(files)
        file_path = fullfile(dir_path, files(i).name);
        fprintf('Processing file: %s\n', files(i).name);
        
        % Load the data
        data = load(file_path);
        
        % Extract method name
        method = data.meta_data.significance_method;
        
        % Determine if method is edge-level or network-level
        is_network_level = strcmp(data.meta_data.statistic_level, 'network');
        
        % Extract power data (tpr field)
        power_values = data.power_data.tpr;
        
        % Extract effect size data based on method type
        if is_network_level
            % For network-level methods, use cluster_stats_summary
            effect_values = l_get_effect_size(data.power_data.cluster_stats_summary);
        else
            % For edge-level methods, use edge_stats_summary
            effect_values = l_get_effect_size(data.power_data.edge_stats_summary);
        end
        
        % Ensure vectors have the same length
        min_length = min(length(power_values), length(effect_values));
        power_values = power_values(1:min_length);
        effect_values = effect_values(1:min_length);
        
        % Initialize method data if first time seeing this method
        if ~isfield(methods_data, method)
            methods_data.(method) = struct('power', [], 'effect', []);
        end
        
        % Add data to the method's collection
        methods_data.(method).power = [methods_data.(method).power; power_values(:)];
        methods_data.(method).effect = [methods_data.(method).effect; effect_values(:)];
    end
    
    % Create the plot
    figure;
    hold on;
    
    % Get all methods
    methods = fieldnames(methods_data);
    
    % Define line styles and colors for different methods
    colors = lines(length(methods));
    line_styles = {'-', '--', ':', '-.'};
    
    legend_entries = {};
    
    % Plot each method's power curve
    for i = 1:length(methods)
        method = methods{i};
        data = methods_data.(method);
        
        % Sort data by effect size
        [sorted_effect, sort_idx] = sort(data.effect);
        sorted_power = data.power(sort_idx);
        
        % Create bins for effect sizes to generate smoother curves
        bin_edges = 0:0.01:1.2;
        bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;
        
        % Initialize arrays for binned data
        bin_power = zeros(size(bin_centers));
        bin_count = zeros(size(bin_centers));
        
        % Assign data to bins
        for j = 1:length(sorted_effect)
            % Find appropriate bin
            bin_idx = find(bin_edges <= sorted_effect(j), 1, 'last');
            if bin_idx < length(bin_edges)
                bin_power(bin_idx) = bin_power(bin_idx) + sorted_power(j);
                bin_count(bin_idx) = bin_count(bin_idx) + 1;
            end
        end
        
        % Calculate average power for each bin
        valid_bins = bin_count > 0;
        bin_power(valid_bins) = bin_power(valid_bins) ./ bin_count(valid_bins);
        
        % Plot the curve
        line_style_idx = mod(i-1, length(line_styles)) + 1;
        plot(bin_centers(valid_bins), bin_power(valid_bins) * 100, ...
             'LineWidth', 2, ...
             'Color', colors(i,:), ...
             'LineStyle', line_styles{line_style_idx});
        
        % Add to legend
        legend_entries{end+1} = strrep(method, '_', ' ');
    end
    
    % Add reference lines
    plot([0 1.2], [80 80], '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
    plot([0.5 0.5], [0 100], '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
    
    % Add labels and legend
    xlabel('Effect size (abs(d))');
    ylabel('Power (%)');
    legend(legend_entries, 'Location', 'southeast');
    title('Statistical Power vs Effect Size by Method');
    grid on;
    
    % Set axis limits
    xlim([0 1.1]);
    ylim([0 100]);
    
    hold off;
end

function effect_size = l_get_effect_size(stats_struct)
    % Helper function to extract effect size from stats structure
    
    % Look for common effect size field names
    if isfield(stats_struct, 'effect_size')
        effect_size = stats_struct.effect_size;
    elseif isfield(stats_struct, 'd')
        effect_size = abs(stats_struct.d);
    elseif isfield(stats_struct, 'cohen_d')
        effect_size = stats_struct.cohen_d;
    elseif isfield(stats_struct, 'effect')
        effect_size = stats_struct.effect;
    else
        % If not found, search all fields for one that might contain effect size
        fields = fieldnames(stats_struct);
        for i = 1:length(fields)
            field_name = fields{i};
            if contains(lower(field_name), 'effect') || ...
               contains(lower(field_name), 'size') || ...
               strcmp(field_name, 'd')
                effect_size = stats_struct.(field_name);
                if strcmp(field_name, 'd')
                    effect_size = abs(effect_size);
                end
                return;
            end
        end
        error('Could not find effect size field in stats structure');
    end
end