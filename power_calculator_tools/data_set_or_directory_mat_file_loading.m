function files = data_set_or_directory_mat_file_loading(dataset_or_directory, varargin)

    p = inputParser;
    addParameter(p, 'sub_directory', '');  % default: 10
    parse(p, varargin{:});
    sub_directory = p.Results.sub_directory;

     % If input is a dataset name, construct the expected directory path
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir); % Go one level up
    power_calculator_data = fullfile('/power_calculator_results/', sub_directory);
    base_dir = fullfile(base_dir, power_calculator_data);

    full_dir = fullfile(base_dir, dataset_or_directory);
    if isfolder(full_dir)
        data_dir = fullfile(base_dir, dataset_or_directory);
    elseif isfolder(dataset_or_directory)
        data_dir = dataset_or_directory; % Assume full directory path is given
    else
        error('Invalid dataset name or directory: %s', dataset_or_directory);
    end

    % Get list of all result files in directory
    files = dir(fullfile(data_dir, '*.mat'));
    if isempty(files)
        error('No result files found in the specified directory: %s', data_dir);
    end

end
    