function save_directory = create_output_directory(Params)
%% create_output_directory
% **Description**
% Ensures the existence of the output directory for saving results. If the 
% directory does not exist, it is created.
%
% **Inputs**
% - `Params` (struct): Contains fields:
%   * `save_directory` (string) – Base directory for saving results.
%   * `data_set` (string) – Dataset name to append to the directory path.
%
% **Outputs**
% - `Params` (struct): Updated structure with `save_directory` field set to 
%   the full output path.
%
% **Workflow**
% 1. Check if `Params.save_directory` exists. If not, create it.
% 2. Append `Params.data_set` to `save_directory`.
% 3. Check again if the updated directory exists. If not, create it.
%
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025

    save_directory = [Params.save_directory, Params.output];

    if ~exist(save_directory, 'dir') % Check if the directory does not exist
        mkdir(save_directory);       % Create the directory
    end

    if ~Params.ground_truth
    
        save_directory = [save_directory, '/repetitions/'];
    
        if ~exist(save_directory, 'dir') % Check if the directory does not exist
            mkdir(save_directory);       % Create the directory
        end

    else
    
        save_directory = [save_directory, '/ground_truth/'];
    
        if ~exist(save_directory, 'dir') % Check if the directory does not exist
            mkdir(save_directory);       % Create the directory
        end
        
    end

end