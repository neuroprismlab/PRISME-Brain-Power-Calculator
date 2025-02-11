function atlas_file = atlas_data_set_map(Params)
% ATLAS_DATA_SET_MAP Returns the appropriate atlas file for a given dataset.
%
%   atlas_file = ATLAS_DATA_SET_MAP(Params) checks the dataset specified in
%   Params.data_set and assigns the corresponding atlas file. If an atlas 
%   file is already provided in Params.atlas_file, it returns that instead.
%
%   Parameters:
%   -----------
%   Params : struct
%       - Params.data_set (string) : The name of the dataset.
%       - Params.atlas_file (string, optional) : If provided, this file is used.
%
%   Returns:
%   --------
%   atlas_file : string
%       Path to the corresponding atlas file.
%
%   Raises:
%   -------
%   - An error if no matching atlas file is found.
%
%   Example Usage:
%   --------------
%   Params.data_set = 'hcp_fc';
%   Params.atlas_file = NaN;
%   atlas_file = atlas_data_set_map(Params);
%   disp(atlas_file); % './atlas_storage/map268_subnetwork.mat'
%
%   Notes:
%   ------
%   - If Params.atlas_file is provided (not NaN), it is returned directly.
%   - Any dataset starting with 'test_' will return the test atlas file.
%   - Additional datasets can be added easily by extending the switch statement.
%
    
    % Default output
    atlas_ok = ~isnan(Params.atlas_file);
    atlas_file = NaN;  

    % Display dataset name for debugging
    disp(Params.data_set)

    if atlas_ok
        % Use provided atlas file if available
        atlas_file = Params.atlas_file;
    else
        switch true
            case strcmp(Params.data_set, 'hcp_fc')
                atlas_file = './atlas_storage/map268_subnetwork.mat';

            case strcmp(Params.data_set, 'abcd_fc')
                disp('Currently WRONG atlas')
                atlas_file = './atlas_storage/map268_subnetwork.mat';

            case startsWith(Params.data_set, 'test_')
                atlas_file = './atlas_storage/test_hcp_fc_atlas.mat';

            otherwise
                error('No atlas file found for dataset: %s', Params.data_set);
        end
    end
end