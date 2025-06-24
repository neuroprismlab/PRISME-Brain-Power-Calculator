function weighted_sparse = unflat_matrix_from_log_sparse(flat_matrix, logical_sparse)
    %% unflat_matrix_from_log_sparse
    % Converts logical sparse adjacency matrix to weighted sparse matrix
    % using values from the flattened matrix and applying min-rule
    %
    % **Inputs**
    % - flat_matrix: 1D array with node values
    % - logical_sparse: Sparse logical adjacency matrix (topology only)
    %
    % **Outputs**
    % - weighted_sparse: Sparse matrix with min(value_i, value_j) weights
    %
    % **Author**
    % Fabricio Cravo
    %
    % **Date**
    % March 2025

    % Find all non-zero (active) edges in the logical sparse matrix
    [row_indices, col_indices] = find(logical_sparse);
    
    % Apply min-rule: edge weight = min(value_i, value_j)
    edge_weights = double(min(flat_matrix(row_indices), flat_matrix(col_indices)));
    
    % Build weighted sparse matrix
    weighted_sparse = sparse(row_indices, col_indices, edge_weights, ...
                            length(flat_matrix), length(flat_matrix));

    
end