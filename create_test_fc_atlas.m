function create_test_fc_atlas()
    
    % Function to create an atlas file for testing
    % One network will have an effect, the other will not
    
    % Define number of ROIs for the two networks
    n_effect = 5; % Number of ROIs in the network with an effect
    n_no_effect = 5; % Number of ROIs in the network with no effect
    
    % Initialize data
    atlas_data = [];
    id = 1; % Starting ID
    
    % Network with effect
    for roi = 1:n_effect
        atlas_data = [atlas_data; id, roi, 1, 'Effect', 'R'];
        id = id + 1;
    end
    
    % Network without effect
    for roi = 1:n_no_effect
        atlas_data = [atlas_data; id, roi + n_effect, 2, 'NoEffect', 'L'];
        id = id + 1;
    end

end