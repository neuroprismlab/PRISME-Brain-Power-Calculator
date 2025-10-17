function fig_tfce_comparison(data)
    % PLOT_TFCE_COMPARISON Creates a comparison figure for TFCE parameters
    %
    % Inputs:
    % From data - must have
    %   avg_heat_maps     - Averaged heatmap data [n_methods x ROI x ROI]
    %   method_list       - Cell array of method names
    %   map_method_index  - Map container linking method names to indices
    %   base_method_name  - String name of the base/reference method
    try
        avg_heat_maps = data.avg_heat_maps;
        method_list = data.method_list;
        map_method_index = data.map_method_index;
        base_method_name = data.base_method_name;
    catch
        error('The data field has a missing required parameter')
    end

    % Separate base from difference methods
    diff_methods = method_list(~strcmp(method_list, base_method_name));
    n_diff = numel(diff_methods);
    
    % Calculate actual difference range for better color scaling
    all_diffs = [];
    for i_m = 1:n_diff
        method = diff_methods{i_m};
        heatmap_data = squeeze(avg_heat_maps(map_method_index(method), :, :));
        all_diffs = [all_diffs; heatmap_data(:)];
    end
    diff_lim = max(abs(prctile(all_diffs, [2 98])));
    if diff_lim < 0.05
        diff_lim = 0.05;  % minimum scale
    end
    
    % === Figure setup ===
    fig = figure('Position', [100, 100, 1800, 600], ...
                 'Color', 'w', ...
                 'Renderer', 'painters', ...
                 'InvertHardcopy', 'off');
    
    % === Visual settings (lighter fonts) ===
    fontName = 'Helvetica';
    fontSizeTitle = 16;
    fontSizeAxis = 14;
    fontSizeColorbar = 13;
    fontSizeMain = 20;
    fontSizeStats = 13;
    fontWeight = 'normal';  % Lighter font weight
    titleColor = [0.2 0.2 0.2];  % Lighter text color
    
    % === BASE METHOD (Left panel, larger) ===
    subplot(1, 4, 1);
    base_data = squeeze(avg_heat_maps(map_method_index(base_method_name), :, :));
    
    imagesc(base_data);
    axis square;
    set(gca, 'XTick', [], 'YTick', [], ...
        'FontName', fontName, ...
        'FontSize', fontSizeAxis, ...
        'LineWidth', 0.8, ...
        'Box', 'on', ...
        'TickDir', 'out', ...
        'Layer', 'top', ...
        'Color', 'w');
    
    colormap(gca, hot);
    base_lim = max(abs(base_data(:)));
    clim([0 base_lim]);
    
    % Extract dh value from method name
    base_label = extractAfter(base_method_name, 'dh');
    if ~isempty(base_label)
        base_label = sprintf('dh = %s (Base)', strrep(base_label, '_', '.'));
    else
        base_label = sprintf('%s (Base)', strrep(base_method_name, '_', ' '));
    end
    
    title(base_label, ...
          'FontWeight', fontWeight, 'FontName', fontName, ...
          'FontSize', fontSizeTitle, 'Color', titleColor);
    ylabel('ROI', 'FontName', fontName, 'FontSize', fontSizeAxis, 'FontWeight', fontWeight);
    xlabel('ROI', 'FontName', fontName, 'FontSize', fontSizeAxis, 'FontWeight', fontWeight);
    
    cb = colorbar;
    cb.Label.String = 'Power';
    cb.Label.FontSize = fontSizeColorbar;
    cb.Box = 'off';
    cb.FontName = fontName;
    cb.FontSize = fontSizeColorbar;
    cb.Color = titleColor;
    cb.LineWidth = 0.8;
    
    % Format colorbar ticks with percentage symbol
    cb.TickLabels = arrayfun(@(x) sprintf('%.1f%%', x), cb.Ticks, 'UniformOutput', false);
    
    % Calculate statistics using upper triangle only (no diagonal, no double counting)
    upper_tri_mask = triu(true(size(base_data)), 1);
    mean_power = mean(base_data(upper_tri_mask));
    max_power = max(base_data(upper_tri_mask));
    
    % Add statistics text below the plot (two lines: mean and max)
    stats_str = sprintf('Mean = %.1f%%\nMax = %.1f%%', mean_power, max_power);
    text(0.5, -0.20, stats_str, ...
         'Units', 'normalized', ...
         'HorizontalAlignment', 'center', ...
         'FontSize', fontSizeStats, ...
         'FontName', fontName, ...
         'Color', titleColor);
    
    set(gca, 'DataAspectRatio', [1 1 1]);
    
    % === DIFFERENCE METHODS (Right panels) ===
    for i_m = 1:n_diff
        subplot(1, 4, i_m + 1);
        method = diff_methods{i_m};
        heatmap_data = squeeze(avg_heat_maps(map_method_index(method), :, :));
        
        imagesc(heatmap_data);
        axis square;
        set(gca, 'XTick', [], 'YTick', [], ...
            'FontName', fontName, ...
            'FontSize', fontSizeAxis, ...
            'LineWidth', 0.8, ...
            'Box', 'on', ...
            'TickDir', 'out', ...
            'Layer', 'top', ...
            'Color', 'w');
        
        % Use diverging colormap for differences
        colormap(gca, bluewhitered);
        clim([-diff_lim diff_lim]);
        
        % Extract dh value from method name
        method_label = extractAfter(method, 'dh');
        if ~isempty(method_label)
            method_label = sprintf('Δ dh = %s', strrep(method_label, '_', '.'));
        else
            method_label = sprintf('Δ %s', strrep(method, '_', ' '));
        end
        
        title(method_label, ...
              'FontWeight', fontWeight, 'FontName', fontName, ...
              'FontSize', fontSizeTitle, 'Color', titleColor);
        ylabel('ROI', 'FontName', fontName, 'FontSize', fontSizeAxis, 'FontWeight', fontWeight);
        xlabel('ROI', 'FontName', fontName, 'FontSize', fontSizeAxis, 'FontWeight', fontWeight);
        
        cb = colorbar;
        cb.Label.String = 'Δ Power';
        cb.Label.FontSize = fontSizeColorbar;
        cb.Box = 'off';
        cb.FontName = fontName;
        cb.FontSize = fontSizeColorbar;
        cb.Color = titleColor;
        cb.LineWidth = 0.8;
        
        % Format colorbar ticks with percentage symbol
        cb.TickLabels = arrayfun(@(x) sprintf('%.2f%%', x), cb.Ticks, 'UniformOutput', false);
        
        % Calculate statistics using upper triangle only (no diagonal, no double counting)
        upper_tri_mask = triu(true(size(heatmap_data)), 1);
        mean_diff = mean(abs(heatmap_data(upper_tri_mask)));
        max_diff = max(abs(heatmap_data(upper_tri_mask)));
        
        % Add statistics text below the plot (two lines: mean and max)
        stats_str = sprintf('Mean |Δ| = %.2f%%\nMax |Δ| = %.2f%%', mean_diff, max_diff);
        text(0.5, -0.20, stats_str, ...
             'Units', 'normalized', ...
             'HorizontalAlignment', 'center', ...
             'FontSize', fontSizeStats, ...
             'FontName', fontName, ...
             'Color', titleColor);
        
        set(gca, 'DataAspectRatio', [1 1 1]);
    end
    
    % === Global title ===
    sgtitle('TFCE Parameter Comparison', ...
        'FontName', fontName, ...
        'FontWeight', fontWeight, ...
        'FontSize', fontSizeMain, ...
        'Color', titleColor);

end


% Helper function for blue-white-red colormap
function cmap = bluewhitered(m)
    if nargin < 1
        m = 256;
    end
    
    bottom = [0 0 0.5];
    middle = [1 1 1];
    top = [0.5 0 0];
    
    n = floor(m/2);
    r = [linspace(bottom(1), middle(1), n), linspace(middle(1), top(1), m-n)]';
    g = [linspace(bottom(2), middle(2), n), linspace(middle(2), top(2), m-n)]';
    b = [linspace(bottom(3), middle(3), n), linspace(middle(3), top(3), m-n)]';
    
    cmap = [r g b];
end