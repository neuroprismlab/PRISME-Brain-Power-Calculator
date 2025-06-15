function [mask, n_var, n_nodes] = setup_experiment_data(Dataset)
%% setup_experiment_data
% **Description**
% Initializes experiment parameters from the dataset by extracting the 
% brain region mask, counting active regions, and determining the number of 
% brain nodes.
%
% **Inputs**
% - `Params` (struct): Experiment settings.
% - `Dataset` (struct): Contains study information with the field `study_info.mask`.
%
% **Outputs**
% - `Params` (struct): Updated structure with:
%   * `mask` (logical matrix) – Extracted brain region mask.
%   * `n_var` (int) – Number of active variables (masked regions).
%   * `n_nodes` (int) – Total number of brain nodes.
%
% **Dependencies**
% - `Dataset.study_info.mask` must be present in the dataset structure.
%
% **Example Usage**
% ```matlab
% Params = setup_experiment_data(Params, load('experiment_data.mat'));
% ```
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025
    
    % If the mask is not at the study info, it is study specific
    if ~isfield(Dataset.study_info, 'mask')
        mask = NaN;
        n_var = NaN;
        n_nodes = NaN;
        return
    end
    
    % For now, let us assume the mask is always a logical 
    % This will likely change in future updates
    mask = logical(Dataset.study_info.mask);

    % Extract number of variables 
    n_var = sum(mask(:));

    % Extract number of nodes 
    n_nodes = size(mask, 1);

end