function Params = setup_experiment_data(Params, Dataset)
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

    
    % Extract study mask
    % Typeset to logical
    Params.mask = logical(Dataset.study_info.mask);
    
    % Extract number of variables - change for multivariable methods
    Params.n_var = sum(Params.mask(:));

    % Extract number of nodes 
    Params.n_nodes = size(Params.mask, 1);
end