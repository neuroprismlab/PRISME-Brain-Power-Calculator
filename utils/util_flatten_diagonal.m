function flat_matrix = util_flatten_diagonal(square_matrix)
    % This function flattens a square matrix and returns only the elements
    % of the upper triangular part (excluding the diagonal).
    %
    % Inputs:
    %   square_matrix: The square matrix to be flattened.
    %
    % Outputs:
    %   flat_matrix: A vector of the upper diagonal elements.

    % Check if the matrix is square
    [n, m] = size(square_matrix);
    if n ~= m
        error('Input matrix must be square.');
    end
    
    % Extract the indices of the upper triangular part (excluding the diagonal)
    % 'triu' with 1 skips the diagonal
    upper_triangular_indices = triu(true(n), 1);
    
    % Flatten the matrix using the logical indices
    flat_matrix = square_matrix(upper_triangular_indices);
    
end