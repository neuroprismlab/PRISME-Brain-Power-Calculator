function flat_function = create_flat_function(mask, varargin)
    % Parse variable_type like in unflatten_matrix
    p = inputParser;
    addParameter(p, 'variable_type', 'edge', @ischar);
    parse(p, varargin{:});
    variable_type = p.Results.variable_type;
    
    % Ok, it stayed like this because of legacy code, sorry
    switch variable_type
        otherwise
            flat_function = @(x) x(mask);
    end
end