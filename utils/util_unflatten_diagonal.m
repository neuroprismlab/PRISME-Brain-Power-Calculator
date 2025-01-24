function full_matrix = util_unflatten_diagonal(flat_upper)
    % Determine the size of the square matrix (n x n)
    % Solve for n in the equation for the number of elements in the upper triangle: 
    % length(flat_upper) = n * (n - 1) / 2
    n = (1 + sqrt(1 + 8 * length(flat_upper))) / 2;
    
    if n ~= floor(n)
        error('The length of flat_upper does not correspond to a valid upper triangular matrix size.');
    end
    
    % Initialize the full matrix with zeros
    full_matrix = zeros(n, n);
    
    % Set ones along the main diagonal
    full_matrix(1:n+1:end) = 1;
    
    % Fill in the upper triangle
    index = 1; % Index for elements in the flat_upper vector
    for row = 1:n-1
        for col = row+1:n
            full_matrix(row, col) = flat_upper(index);
            index = index + 1;
        end
    end
    
    % Mirror the upper triangle to the lower triangle
    full_matrix = full_matrix + full_matrix';
    full_matrix(1:n+1:end) = 1; % Ensure ones remain on the diagonal
end