function create_test_fc_atlas()
%% create_test_fc_atlas
% Generates a simple synthetic atlas for functional connectivity tests.
%
% This atlas is associated with the test dataset created by create_test_fc_data_set.
% It defines 5 ROIs, grouped into two network categories (e.g., 'Ef' and 'Nf').
% The atlas structure is saved as a MATLAB table and stored in the ./atlas_storage/ directory.
% As a result, it can generate an edge_group matrix, where edges can be
% assigned to networks.
%
% Notes:
%   - Category values (1 and 2) can be used to distinguish edges by network.
%   - This format is used for grouping edges in network-based tests (e.g., Constrained methods).
%   - Intended for internal use in validation and testing workflows.
    
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