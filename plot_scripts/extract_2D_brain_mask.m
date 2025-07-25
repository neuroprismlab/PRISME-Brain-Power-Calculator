function extract_2D_brain_mask()
    
    % This is not meant to be a highly important function, it's used for
    % one of the paper's images and not the pipeline. 
    % So the file path is defined and changed here
    file = '/Users/f.cravogomes/Desktop/Cloned Repos/Power_Calculator/data/s_hcp_act_noble_1.mat';
    
    try
        dataset = load(file);
    catch
        error('Could not load file - the path is hard coded in the script')
    end
    
    % Get any of the masks, this is for ploting
    logical_mask = dataset.brain_data.EMOTION.mask;
    logical_mask = logical_mask(:, :, 50);
    
    % Extract coordinates where mask is true
    [y_coords, x_coords] = find(logical_mask);
    
    % Create scatterplot
    figure;
    scatter(x_coords, y_coords, 10, 'filled');
    axis equal;
    title('Scatterplot from Logical Mask');
    xlabel('X');
    ylabel('Y');

    writematrix(logical_mask, 'brain_coords_ex.csv');

end