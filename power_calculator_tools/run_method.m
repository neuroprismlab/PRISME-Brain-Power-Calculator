function result = run_method(method_name, varargin)

    % Call the method dynamically
    method_instance = feval(method_name);
    result = method_instance.run_method(varargin{:});

end