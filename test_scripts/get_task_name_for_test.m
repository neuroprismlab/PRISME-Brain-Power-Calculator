function task_name = get_task_name_for_test(Dataset)

    % This funciton gets only test1 task name - it's reserved for the
    % testing script
    task_name = 'unkown';

    if iscell(Dataset.outcome.test1.contrast)

        contrast = Dataset.outcome.test1.contrast;
        
        if length(contrast) == 2

            if strcmp(contrast{1}, 'REST')
                rest_contrast = contrast{1};
                task_contrast = contrast{2};
            elseif strcmp(contrast{2}, 'REST')
                rest_contrast = contrast{2};
                task_contrast = contrast{1};
            else
                rest_contrast = contrast{1};
                task_contrast = contrast{2};
            end

            task_name = strcat(rest_contrast, '_', task_contrast);
        
        elseif length(contrast) == 1

            task_name = contrast{1};

        end

    end
    
    % If there is no contrast, the test number is used as default
    if strcmp(task_name, 'unkown')
        task_name = 'test1';
    end 
    
    % This is here for future updates - In case someone, wrongly changes
    % the line above.
    if strcmp(task_name, 'unkown')
        error('Task name was not obtained from test data');
    end

end