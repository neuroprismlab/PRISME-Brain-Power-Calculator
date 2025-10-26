function results_cell = multi_experiment_average(input_path, varargin)
    
    % Input Parser 
    p = inputParser;

    addOptional(p, 'attribute_name_calculation', 'tpr');

    parse(p, varargin{:});
    attribute = p.Results.attribute_name_calculation;
    
    %% Check if input is multiple files or single
    multiple_files = false;
    single_file = false;

    if isfolder(input_path)
        multiple_files = true;
    elseif isfile(input_path) || exist(input_path, 'file')
        single_file = true;
    end
    
    %% Open files and construct a cell for calculating averages
    if multiple_files
        file_structs = dir(fullfile(input_path, '*.mat'));
        files = cell(length(file_structs), 1);
        for i = 1:length(file_structs)
            files{i} = fullfile(input_path, file_structs(i).name);
        end
    elseif single_file
        files = {input_path};
    else
        error(['At multi_experimen_average_function - case which is neither a proper directory ' ...
            'or a single output file'])
    end
    
    %% Error checking if no files found
    if isempty(files)
        error('At multi_experiment_average - No files detected')
    end
    
    %% Store average results in a cell
    num_files = numel(files);
    results_cell = cell(num_files, 1);  % Creates num_files x 1 cell array  

    for fi = 1:num_files
        full_file = files{fi};

        file_results = get_output_file_statistics(full_file, 'attribute', attribute);
        
        results_cell{fi} = file_results;
    end

end 


