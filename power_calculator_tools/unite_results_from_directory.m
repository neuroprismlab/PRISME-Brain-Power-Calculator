% Open data for visualisation script 
function RepetitionResults = unite_results_from_directory(varargin)

    % Create an input parser
    p = inputParser;
    
    addParameter(p, 'directory', './power_calculator_results/', @ischar); % Default: 'default'
    
    % Parse the inputs
    parse(p, varargin{:});
    data_dir = p.Results.directory;
    
    % Initialise empty struct
    RepetitionResults = struct;

    % Get a list of all .mat files in the directory
    matFiles = dir(fullfile(data_dir, '*.mat'));

    for i = 1:length(matFiles)
        % Get the full file path
        file_path = fullfile(data_dir, matFiles(i).name);
        
        %% Load Data
        rep_data = load(file_path);
        meta_data = rep_data.meta_data;
        
        %% Query elements 
        data_set_name = strcat(meta_data.dataset, '_', meta_data.map);
        task_name = meta_data.study_name;

        subject_number = sprintf('subs_%d', meta_data.n_subs);
        methods = meta_data.method_list;

        for j = 1:numel(methods)
            significance_method = methods{j};
         
            struct_query = {data_set_name, task_name, significance_method, subject_number};
    
            if meta_data.testing_code
                struct_query = [{'testing'}, struct_query];
            end
    
            %% Perform the assigment 
            RepetitionResults = setfield(RepetitionResults, struct_query{:}, ...
                rep_data.(significance_method));  

            struct_query = {data_set_name, task_name, significance_method, subject_number, 'meta_data'};

            if meta_data.testing_code
                struct_query = [{'testing'}, struct_query];
            end

            RepetitionResults = setfield(RepetitionResults, struct_query{:}, ...
                rep_data.meta_data);
            
        end


    end
    
end
