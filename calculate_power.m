function calculate_power(varargin)
    %% Workflow for Power Calculation
    % This script performs the complete power calculation workflow by processing 
    % repetition files one-by-one and computing power metrics against ground-truth data.
    %
    % The workflow proceeds as follows:
    %   1. Initial Setup:
    %      - Sets the working directory to the script location.
    %      - Adds all subdirectories to the MATLAB path.
    %      - Clears variables (except Study_Info) and clears the Command Window.
    %
    %   2. Parameter and Data Loading:
    %      - Loads experiment parameters via setparams.
    %      - Loads dataset information (Study_Info) from Params.data_dir if not already in the workspace.
    %      - Determines the dataset name using get_data_set_name.
    %
    %   3. Repetition File Processing:
    %      - Searches for repetition files in the designated output directory.
    %      - Throws an error if no repetition files are found.
    %
    %   4. Output Directory Creation:
    %      - Ensures that the power output directory exists by calling create_power_output_directory.
    %
    %   5. Iterative Processing:
    %      - For each repetition file:
    %          a. Loads the repetition data.
    %          b. Extracts metadata and constructs the corresponding ground-truth (GT) filename.
    %          c. Loads GT data (skips file if not found).
    %          d. Extracts relevant brain data from the GT file using extract_gt_brain_data.
    %          e. Computes power using summarize_tprs.
    %          f. Clears repetition and GT data from memory.
    %
    % Dependencies:
    %   - setparams
    %   - get_data_set_name
    %   - create_power_output_directory
    %   - construct_gt_filename
    %   - extract_gt_brain_data
    %   - summarize_tprs
    %
    % Notes:
    %   - This script is designed to minimize memory usage by processing repetition files sequentially.
    %   - It requires that repetition and GT data files exist in the expected directories.
    %% Handle input parameters
    p = inputParser;
    addParameter(p, 'parameters', setparams(), @(x) isstruct(x));
    addParameter(p, 'study_info', [], @(x) isstruct(x) || isempty(x));
    parse(p, varargin{:});
    
    Params = p.Results.parameters;
    Study_Info = p.Results.study_info;

    %% Initial setup
    scriptDir = fileparts(mfilename('fullpath'));
    addpath(genpath(scriptDir));
    cd(scriptDir);
    clearvars -except Study_Info Params;
    clc;

    % Load dataset information
    if ~isempty('Study_Info')
        Study_Info = load(Params.data_dir, 'study_info');
        [~, filename, ~] = fileparts(Params.data_dir);
        Study_Info.file_name = filename;
    end
    [Params.output, ~, ~] = get_data_set_name(Study_Info, Params);
    
    %% Process each repetition file one by one to reduce memory usage
    rep_files = dir(fullfile(Params.save_directory, Params.output, "repetitions",'*.mat'));

    % If no files were found output an error
    if isempty(rep_files)
        error('No files found.')
    end
    
    %% Create output directory (only if it doesn't exist)
    [Params.gt_data_dir, Params.gt_output] = setup_gt_directory(Params);
    Params.save_directory = create_power_output_directory(Params);
    
    for i = 1:length(rep_files)
        % Load a single repetition data file
        rep_file_path = fullfile(rep_files(i).folder, rep_files(i).name);
        rep_data = load(rep_file_path);
        
        
        % Meta-data from the file encompassing everything
        method_list = rep_data.meta_data.method_list;
        

        [test_components, test_type, sub_number, testing_code] = get_data_for_file_naming(rep_data.meta_data);
        [~, file_name] = create_and_check_rep_file(Params.save_directory, Params.output, test_components, ...
                                                   test_type, ...
                                                   sub_number, ...
                                                   testing_code, false);
    
        % Split the path and filename
        [file_path, file_name_only, file_ext] = fileparts(file_name);
        % Add the prefix to just the filename
        file_name = fullfile(file_path, ['pr-', file_name_only, file_ext]);
        
        % Save metadata regardless
        meta_data = rep_data.meta_data;
        
        % Get file type for correct calculation
        file_type = get_file_type(rep_data.meta_data);

        % Calculate means and save everything
        [edge_level_stats_mean, network_level_stats_mean, edge_level_stats_std, network_level_stats_std] = ...
             calculate_edge_stats(file_type, rep_data);

        save(file_name, 'meta_data', 'edge_level_stats_mean', 'network_level_stats_mean', 'edge_level_stats_std', ...
                'network_level_stats_std');
   
    
        for j = 1:numel(method_list)
            method = method_list{j};
            method_data = rep_data.(method);
    
            gt_filename = construct_gt_filename(rep_data.meta_data, Params.gt_output);
            gt_fullpath = fullfile(Params.gt_data_dir, gt_filename);
          
            if exist(gt_filename, 'file')
                gt_data = load(gt_fullpath);
            else
                error(['GT file %s not found. Please either set the correct name with Params.output or check if the ' ...
                    'file is missing\n'], gt_filename);
            end
    
            matching_datasets_check(rep_data.meta_data, gt_data.meta_data)
     
            stat_level = get_stat_level_from_file(rep_data, method);
            
            gt_brain_data = extract_gt_brain_data(gt_data, stat_level);
    
            PowerRes = summarize_tprs('calculate_tpr', method_data, gt_brain_data, Params, method, ...
                file_type, meta_data);
            eval([method ' = PowerRes;']);  % creates a variable named after the method
            
            save(file_name, method, '-append');
    
        end

        fprintf('Finished power calculation for file %s \n', file_name);
    
    end

end