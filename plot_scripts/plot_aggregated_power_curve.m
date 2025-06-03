function plot_aggregated_power_curve(directory, varargin)
    
    %% Check if input is a directory
    if isfolder(directory)
        error('Input must be a directory name')
    end
    
    %% Parse varargin
    % Create input parser
    p = inputParser;

     % Add optional parameter
    addParameter(p, 'undesired_subject_numbers', {}, @iscell);
  
    % Parse input
    parse(p, directory, varargin{:});

    undesired_subject_numbers = p.Results.undesired_subject_numbers;


    %% Get averages 
    averages = multi_experiment_average(directory);
    
    

    for i = 1:numel(averages)

    end
    


end