function flat_function = create_flat_function(mask, varargin)
    % Parse variable_type like in unflatten_matrix
    p = inputParser;
    addParameter(p, 'variable_type', 'edge', @ischar);
    parse(p, varargin{:});
    variable_type = p.Results.variable_type;
    
    switch variable_type
        case 'node'
            flat_function = @(x) x(:);
        otherwise
            flat_function = @(x) x(mask);
    end
end