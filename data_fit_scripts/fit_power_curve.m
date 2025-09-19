function [x, y, r_squared, fitted_params] = fit_power_curve(results_x, results_y, varargin)


    % Parse optional parameters
    p = inputParser;
    
    % Default Weibull function
    % default_func = @(params, x) 100*(1 - exp(-(x./params(1)).^params(2)));
    default_func = @(params, x) params(3) ./ (1 + (params(1) ./ x).^params(2));
    
    addParameter(p, 'fit_function', default_func, @(x) isa(x, 'function_handle'));
    addParameter(p, 'lower_bounds', [1, 0.1, 0], @isnumeric);  % Allow custom initial params
    addParameter(p, 'upper_bounds', [100000, 5, 100], @isnumeric);  % Allow custom initial params
    
    parse(p, varargin{:});

    % Extract the function and parameters
    power_func = p.Results.fit_function;
    lb = p.Results.lower_bounds;
    ub = p.Results.upper_bounds;

    % Initial parameter estimates
    % a: roughly where we expect decent power (median of x range)
    % b: start with exponential shape (b=1)
    a_init = median(results_x);
    b_init = 1;
    c_init = 50;

    % Initial guess: [scale, shape]
    initial_params = [a_init, b_init, c_init];

    % Define cost function (sum of squared residuals)
    cost_func = @(params) sum((results_y - power_func(params, results_x)).^2);

    % Set optimization options with bounds to ensure positive parameters
    options = optimset('Display', 'off', 'MaxFunEvals', 10000);

    if exist('fmincon', 'file')
        [fitted_params, ~] = fmincon(cost_func, initial_params, [], [], [], [], lb, ub, [], options);
    else
        % Fallback to fminsearch if Optimization Toolbox not available
        [fitted_params, ~] = fminsearch(cost_func, initial_params, options);
    end


    % Generate smooth curve for plotting
    x = linspace(0, max(results_x), 200);
    y = power_func(fitted_params, x);
    
    % Calculate R-squared
    y_pred = power_func(fitted_params, results_x);
    ss_res = sum((results_y - y_pred).^2);
    ss_tot = sum((results_y - mean(results_y)).^2);
    r_squared = 1 - (ss_res / ss_tot);



end