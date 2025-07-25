function study_heat_map_gen(method, file, varargin)   
%
% For the paper: Shitf - down to select for paste
% - study_heat_map_gen('Parametric_FDR','/Users/f.cravogomes/Desktop/Cloned Repos/Power_Calculator/power_calculator_results/power_calculation/hcp_fc/pr-hcp_fc-REST_SOCIAL-t-subs_40.mat', 'title', 'HCP FC 40 Subject Social Task')

%
    
    % Create parser object
    p = inputParser;
    
    % Add required parameters
    addOptional(p, 'title', 'Heatmap');
    addOptional(p, 'xaxis_label', '');
    addOptional(p, 'yaxis_label', '');

    % Parse the inputs
    parse(p, varargin{:});
    
    % Access parsed values
    heatmap_title = p.Results.title;
    x_label = p.Results.xaxis_label;
    y_label = p.Results.yaxis_label;


    try
        data = load(file);
    catch
        % Lazy error handling
        error('Error opening file')
    end

    % Until now, mask can either be logical or a function. For
    % compatibility, we handle both
    
    % Old unflat matrix
    unflat_matrix_fun = unflatten_matrix(data.meta_data.rep_parameters.mask);
    
    if ~isfield(data, method)
        error('File type lacking requested method')
    end
    
    try
        power_data = unflat_matrix_fun(data.(method).tpr);
    catch
        error('File type lacking TPR - please check if it is truly a power results file')
    end

    if ndims(power_data) ~= 2
        error('This script is for two dimensional heatmaps. The data was flattened to a non-2D array')
    end

    n_networks = unique(data.meta_data.edge_grops(1, :));

    keyboard;

    % Assuming your 2D matrix is called 'data'
    figure;
    imagesc(power_data);
    colorbar;
    title(heatmap_title);
    xlabel(x_label);
    ylabel(y_label);
    
    % Custom RGB colormap
    %my_colormap = [
    %    0.0 0.0 0.8;  % Dark blue for strong negative correlation
    %    0.4 0.4 1.0;  % Medium blue
    %    0.8 0.8 1.0;  % Light blue
    %    1.0 1.0 1.0;  % White for zero correlation
    %    1.0 0.8 0.8;  % Light red
    %    1.0 0.4 0.4;  % Medium red
    %    0.8 0.0 0.0   % Dark red for strong positive correlation
    %];
    
    % Convert to 0-1 range
    colormap(sky);

    keyboard;

end


