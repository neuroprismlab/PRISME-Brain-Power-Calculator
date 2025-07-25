function plot_aggregated_power_curve(directory, varargin)
    
    %% Check if input is a directory
    if ~isfolder(directory)
        error('Input must be a directory name')
    end
    
    %% Parse varargin
    % Create input parser
    p = inputParser;

     % Add optional parameter
    addParameter(p, 'undesired_subject_numbers', {}, @iscell);
  
    % Parse input
    parse(p, varargin{:});

    undesired_subject_numbers = p.Results.undesired_subject_numbers;

    %% Get averages 
    multi_variable_average = multi_experiment_average(directory);

    data_agregator = struct();

    % First loop: prepare empty structs for all subjects
    for ri = 1:numel(multi_variable_average)
        res = multi_variable_average{ri};
        n_subs = res.meta_data.subject_number;
        n_subs = ['subs_' num2str(n_subs)];
        
        if ~isfield(data_agregator, n_subs)
            data_agregator.(n_subs) = struct();
        end
    end

    % Colect file averages
    for ri = 1:numel(multi_variable_average)
        res = multi_variable_average{ri};

        n_subs = res.meta_data.subject_number;
        n_subs = ['subs_' num2str(n_subs)];
        
        for mi = 1:numel(res.meta_data.method_list)
            method = res.meta_data.method_list{mi};
            
            if ~isfield(data_agregator.(n_subs), method)
                data_agregator.(n_subs).(method) = {res.mean.(method)};
            else
                data_agregator.(n_subs).(method){end+1} = res.mean.(method);
            end
        end
        
    end

    average = struct();
    deviation = struct();
    
    %% Calculate mean and std for collected data
    sub_numbers = fieldnames(data_agregator);
    
    % Get all unique methods (assuming all subjects have same methods)
    first_subject = sub_numbers{1};
    methods = fieldnames(data_agregator.(first_subject));
    
    % Need both as row vectors
    results_x = str2double(extractAfter(sub_numbers, 'subs_')); % Extract subject numbers
    results_x = results_x';
    
    % Create figure with larger size for publication
    figure('Position', [100, 100, 1000, 700]);
    set(gcf, 'Color', 'white');        % Figure background
    set(gca, 'Color', 'white');        % Axes background
    hold on;  
    
    for mi = 1:numel(methods)
        method = methods{mi};
        results_y = zeros(1, numel(sub_numbers));

        % Skip method if cpp version exists
        disp(method)
        disp(plot_has_cpp_version(method, methods))
        if plot_has_cpp_version(method, methods)
            continue;
        end
            
        % Collect mean for this method from all subjects
        for fi = 1:numel(sub_numbers)
            subn = sub_numbers{fi};
            % Calculate mean across experiments for this subject and method
            results_y(fi) = mean([data_agregator.(subn).(method){:}]);
        end
        
        [x_fit, y_fit, r_squared, ~] = fit_power_curve(results_x, results_y);
        
        color = method_color_assingment(method);
        method_name = method_name_assigment(method);

        % Plot data points
        plot(results_x, results_y, 'o', 'Color', color, 'MarkerSize', 8, ...
             'MarkerFaceColor', color, 'DisplayName', [method_name ' (data)']);
    
        % Plot fitted curve
        plot(x_fit, y_fit, '-', 'Color', color, 'LineWidth', 3, ...
             'DisplayName', sprintf('%s (R² = %.3f)', method_name, r_squared));

    end

    % Add reference line for 80% power with label on left and larger font
    yline(80, '--k', 'Power = 80%', 'LineWidth', 1, 'Alpha', 0.7, ...
          'LabelHorizontalAlignment', 'left', 'FontSize', 14);

    hold off;
    
    % Add info
    xlabel('Number of Subjects', 'FontSize', 16, 'FontName', 'Arial');
    ylabel('Statistical Power (%)', 'FontSize', 16, 'FontName', 'Arial');
    title('Statistical Power Curves by Method', 'FontSize', 18, 'FontName', 'Arial');

    % Add legend
    legend('Location', 'best', 'FontSize', 12, 'FontName', 'Arial', ...
           'Box', 'on', 'LineWidth', 1.5);

end