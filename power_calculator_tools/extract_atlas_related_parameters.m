function [n_node_nets, trilmask_net, edge_groups] = extract_atlas_related_parameters(RP, Y)
%% extract_atlas_related_parameters
% **Description**
% Extracts atlas-related parameters used for network-based statistics 
% (e.g., constrained methods). Returns the number of atlas-based nodes, 
% a mask for upper-triangular edges, and the groupings of edges by network.
% If no atlas is defined (`RP.atlas_file = NaN`), outputs are also NaN.
%
% **Inputs**
% - `RP` (struct): Configuration structure containing:
%   * `atlas_file` – path to atlas file (or NaN).
%   * `mask` – logical matrix used for masking.
% - `Y` (matrix): Data matrix (features × subjects); only the first column is used.
%
% **Outputs**
% - `n_node_nets` (int): Number of nodes defined by the atlas (square matrix size).
% - `trilmask_net` (NaN): Placeholder, not computed in this function.
% - `edge_groups` (matrix): Upper-triangular matrix encoding group membership 
%   for edges, as defined by the atlas.
%
% **Workflow**
% 1. Check whether `RP.atlas_file` is defined.
% 2. If defined:
%    - Summarize one sample to get atlas shape.
%    - Load edge group assignments and extract upper-triangular entries.
% 3. Otherwise, return NaNs.
%
% **Dependencies**
% - `summarize_matrix_by_atlas.m`
% - `load_atlas_edge_groups.m`
%
% **Notes**
% - `trilmask_net` is currently unused and returned as NaN.
% - Assumes atlas-based constraints are only needed for specific methods.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025
    
    % Define parameters as NaN for cases where they are not necessary
    % These are only necessary in the - 'Constrained' and
    % 'Constrained_FWER'cases
    n_node_nets = NaN;
    trilmask_net = NaN;
    edge_groups = [];

    % Only apply atlas to the network-based stats
    if ~isnan(RP.atlas_file)
       
        template_net = summarize_matrix_by_atlas(Y(:, 1), RP.atlas_file, 'suppressimg', 1, 'mask', RP.mask);
    
        n_node_nets = size(template_net, 1); % square
        % trilmask_net = tril(true(n_node_nets));
    
        edge_groups = load_atlas_edge_groups(RP.atlas_file);
        % edge_groups = tril(edge_groups,-1);
        edge_groups = triu(edge_groups, 1);
        
    end

end