function Params = create_gt_output_directory(Params)
%% create_gt_output_directory
% Creates the output directory for ground-truth results.
%
% Inputs:
%   - Params: Structure containing:
%       * save_directory: Base output directory.
%       * data_set: Name of the dataset.
%
% Outputs:
%   - Params: Updated structure with save_directory set to the ground-truth 
%             subdirectory (i.e., [base_directory, 'ground_truth/', data_set, '/']).
%
% Author: Fabricio Cravo | Date: March 2025
    
    Params.save_directory = [Params.save_directory, 'ground_truth/'];

    if ~exist(Params.save_directory, 'dir') % Check if the directory does not exist
        mkdir(Params.save_directory);       % Create the directory
    end

    Params.save_directory = [Params.save_directory, Params.output, '/'];

    if ~exist(Params.save_directory, 'dir') % Check if the directory does not exist
        mkdir(Params.save_directory);       % Create the directory
    end

end