function save_directory = create_power_output_directory(Params)

    save_directory = [Params.save_directory, Params.output, '/power_calculation/'];

    if ~exist(save_directory, 'dir') % Check if the directory does not exist
        mkdir(save_directory);       % Create the directory
    end

end