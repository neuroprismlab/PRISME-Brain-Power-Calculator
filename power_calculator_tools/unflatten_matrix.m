function unflat_matrix = unflatten_matrix(mask, varargin)
%% unflatten_matrix
% Reconstructs a full symmetric matrix from a flattened vector using a mask.
% Standard function for flattening and unflattening that should be used
% troughout all script
%
% **Inputs**
%   - flat_matrix: Vector of matrix elements.
%   - mask: Logical matrix specifying positions.
%
% **Outputs**
%   - unflat_matrix: Reconstructed symmetric matrix.
%
% **Author** 
% Fabricio Cravo
%
% **Date**
% March 2025
    
    p = inputParser;
    addRequired(p, 'mask');
    addParameter(p, 'variable_type', 'edge', @ischar);
    addParameter(p, 'flat_to_spatial', []);  % No validation
    addParameter(p, 'spatial_to_flat', []);  % No validation

    parse(p, mask, varargin{:});
    
    variable_type = p.Results.variable_type;
    flat_to_spatial = p.Results.flat_to_spatial;
    spatial_to_flat = p.Results.spatial_to_flat;
    
    % Ok, this needs to be fixed, it needs to always return a function for
    % future updates
    switch variable_type
        
        % Nodes can risk to much variables
        % So here a sparse is returned
        case 'node'
            % Get matrix dimensions and total elements
            matrix_size = size(mask);
            n_dims = length(matrix_size);
            n_elements = sum(mask(:));  % or nnz(mask)

            max_neighbors = 3^n_dims;  % 27 for 3D (including self)
            estimated_edges = n_elements * max_neighbors;

            neighbor_offsets = zeros(max_neighbors, n_dims);

            I = zeros(estimated_edges, 1);
            J = zeros(estimated_edges, 1);
            V = zeros(estimated_edges, 1);
            
            logical_sparse = generate_sparse_from_spatial_matrix(mask, ...
                flat_to_spatial, spatial_to_flat, neighbor_offsets, I, J, V);

            unflat_matrix = @(x) unflat_matrix_from_log_sparse(x, logical_sparse);
            
        % Standard legacy unflatten stategy
        otherwise

            unflat_matrix = @(x) roi_roi_unflat(x, mask);

    end

end

function unflat_matrix = roi_roi_unflat(flat_matrix, mask)
    temp_y = zeros(size(mask));
    temp_y(mask) = flat_matrix;
    % make full matrix, not upper or lower tri, before reordering
    % if all(mask(triu_mask)==0) | all(mask(tril_mask_without_diag)==0) % lower triangular
    unflat_matrix = temp_y + temp_y';
end
