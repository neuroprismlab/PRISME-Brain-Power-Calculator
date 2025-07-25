function add_network_lines_from_starts(network_boundaries, varargin)

    % Create parser object
    p = inputParser;
    
    % Add required parameters
    addOptional(p, 'network_names', {});

    % Parse the inputs
    parse(p, varargin{:});


    % Convert cell array to regular array if needed
    if iscell(network_boundaries)
        boundaries = cell2mat(network_boundaries);
    else
        boundaries = network_boundaries;
    end

    if isempty(p.Results.network_names)
        % Generate default network names
        num_networks = length(boundaries) + 1; % +1 for the last network
        network_names = cell(num_networks, 1);
        for i = 1:num_networks
           network_names{i} = ['Net', num2str(i)];
        end
    else
        network_names = p.Results.network_names;
    end
    
    % Subtract 0.5 because your boundaries are START indices, 
    % but we want lines BETWEEN the previous and current network
    plot_boundaries = boundaries - 0.5;
    
    hold on;
    for i = 1:length(plot_boundaries)
        % Vertical lines 
        line([plot_boundaries(i), plot_boundaries(i)], ...
             ylim, 'Color', 'black', 'LineWidth', 2);
        % Horizontal lines 
        line(xlim, [plot_boundaries(i), plot_boundaries(i)], ...
             'Color', 'black', 'LineWidth', 2);
    end
    hold off;

    % Calculate center positions for each network
    full_boundaries = [0, boundaries, max(xlim())];
    
    % Get current axis limits
    xlims = xlim();
    ylims = ylim();
    
    for i = 1:length(network_names)
        % Calculate center position of each network
        start_pos = full_boundaries(i);
        end_pos = full_boundaries(i + 1);
        center_pos = (start_pos + end_pos) / 2;
        
        % Add label on X-axis (bottom)
        text(center_pos, ylims(2) + (ylims(2) - ylims(1)) * 0.05, network_names{i}, ...
             'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', ...
             'FontSize', 10, 'FontWeight', 'bold', ...
             'Rotation', 0);
        
        % Add label on Y-axis (left)
        text(xlims(1) - (xlims(2) - xlims(1)) * 0.04, center_pos, network_names{i}, ...
             'HorizontalAlignment', 'right', ...
             'VerticalAlignment', 'middle', ...
             'FontSize', 10, 'FontWeight', 'bold', ...
             'Rotation', 0);
    end

end