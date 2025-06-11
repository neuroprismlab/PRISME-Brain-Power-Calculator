function atlas_file = atlas_data_set_map(Params)
%% atlas_data_set_map
% **Description**
% Determines the appropriate atlas file based on `Params.data_set`. If 
% `Params.atlas_file` is already set, it is returned directly.
%
% **Inputs**
% - `Params` (struct): Contains fields:
%   * `data_set` (string) – Name of the dataset.
%   * `atlas_file` (string, optional) – Predefined atlas file (if available).
%
% **Outputs**
% - `atlas_file` (string) – Path to the corresponding atlas file.
%
% **Workflow**
% 1. If `Params.atlas_file` is defined, return it.
% 2. Otherwise, assign an atlas file based on `Params.data_set`.
% 3. If no match is found, throw an error.
%
% **Example Usage**
% ```matlab
% Params.data_set = 'hcp_fc';
% Params.atlas_file = NaN;
% atlas_file = atlas_data_set_map(Params);
% disp(atlas_file); % './atlas_storage/map268_subnetwork.mat'
% ```
%
% **Dependencies**
% - Dataset name must match a predefined case in the function.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025
    
    % Default output
    atlas_ok = ~isnan(Params.atlas_file);
    atlas_file = NaN;  

    if atlas_ok
        % Use provided atlas file if available
        atlas_file = Params.atlas_file;
    else
        switch true
            case strcmp(Params.data_set_base, 'hcp')
                atlas_file = './atlas_storage/map268_subnetwork.mat';

            case strcmp(Params.data_set_base, 'abcd')
                atlas_file = './atlas_storage/map268_subnetwork.mat';

            case startsWith(Params.data_set_base, 'test')
                atlas_file = './atlas_storage/test_hcp_fc_atlas.mat';

            otherwise
                error('No atlas file found for dataset: %s', Params.data_set_base);
        end
    end
end
