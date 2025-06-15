function logical_sparse = generate_sparse_from_spatial_matrix(mask, flat_to_spatial, ...
    spatial_to_flat, neighbor_offsets, I, J, V)
%% generate_sparse_from_spatial_matrix
% Converts spatial matrix (2D/3D/nD) to sparse adjacency matrix using min-rule
% Edge weight = min(value_i, value_j) for spatially adjacent elements
%
% **Inputs**
% - spatial_matrix: n-dimensional matrix with node values
%
% **Outputs** 
% - sparse_matrix: Symmetric sparse adjacency matrix
%
% **Author**
% Fabricio Cravo
%
% **Date**
% March 2025

% Get matrix dimensions and total elements
matrix_size = size(mask);
n_dims = length(matrix_size);
n_elements = sum(mask(:));

% Generate neighbor offsets for n-dimensional connectivity
% For 2D: [-1,0], [1,0], [0,-1], [0,1] 
% For 3D: [-1,0,0], [1,0,0], [0,-1,0], [0,1,0], [0,0,-1], [0,0,1]

% Generate all combinations of -1, 0, 1 for each dimension
% This creates the full 3^n neighborhood
for i = 0:(3^n_dims - 1)
    coords = zeros(1, n_dims);
    temp = i;
    
    % Convert index to n-dimensional coordinates in {-1,0,1}^n
    for dim = 1:n_dims
        coords(dim) = mod(temp, 3) - 1;
        temp = floor(temp / 3);
    end

    neighbor_offsets(i+1, :) = coords;  
end

%% Prealocate space for 
% Estimate maximum possible edges (each node has ~26 neighbors in 3D)
max_neighbors = 3^n_dims;  % 27 for 3D (including self)
estimated_edges = n_elements * max_neighbors;

% Loop through all elements in flattened matrix
edge_count = 0; % Start counting edges
for current_node = 1:n_elements

    spatial_node_cord = flat_to_spatial(current_node);

    % Check all neighbors
    for neighbor_idx = 1:size(neighbor_offsets, 1)
        current_offset = neighbor_offsets(neighbor_idx, :);
        
        coords_array = [spatial_node_cord{:}];
        coords_array = cell2mat(coords_array);  % Force to row vector
        neighbor_array_cord = coords_array + current_offset;

        % Check bounds before calling spatial_to_flat
        if all(neighbor_array_cord >= 1) && all(neighbor_array_cord <= matrix_size)
            adjacent_node = spatial_to_flat(num2cell(neighbor_array_cord));  % Get the flat index
        else
            continue;
        end
        
        if adjacent_node == 0
            continue;
        else
            edge_count = edge_count + 1;
            I(edge_count) = current_node;
            J(edge_count) = adjacent_node; 
            V(edge_count) = 1;
        end
      
    end
end

% Build sparse matrix from filled arrays
logical_sparse = sparse(I(1:edge_count), J(1:edge_count), V(1:edge_count), ...
                        n_elements, n_elements);

end