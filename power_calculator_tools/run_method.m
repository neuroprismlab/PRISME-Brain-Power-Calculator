function result = run_method(method_name, varargin)

    % Path to statistical methods directory
    methods_dir = './statistical_methods/';
    
    % Check if method exists
    method_path = fullfile(methods_dir, [method_name, '.m']);
    if ~exist(method_path, 'file')
        error('Method "%s" not found in %s', method_name, methods_dir);
    end

    % Call the method dynamically
    method_instance = feval(method_name);
    result = method_instance.run_method(varargin{:});

end