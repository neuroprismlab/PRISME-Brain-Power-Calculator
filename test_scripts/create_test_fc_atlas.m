function create_test_fc_atlas()
    
    % Define ROI mappings
    % newroi, oldroi, category, label, hemisphere
    newroi = [1; 2; 3; 4; 5];
    oldroi = [1; 2; 3; 4; 5];
    category = [1; 1; 1; 1; 2];
    label = ['Ef'; 'Ef'; 'Ef'; 'Ef'; 'Nf'];
    hemiphere = ['L'; 'L'; 'L'; 'L'; 'R'];

    %% Convert to table
    % For now only map is available as an attribute
    map = table(newroi, oldroi, category, label, hemiphere);

    % Save to file (optional)
    save('./atlas_storage/test_hcp_fc_atlas.mat', 'map');

end