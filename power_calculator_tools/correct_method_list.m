function update_meta_method_list(directory)
% Updates meta_data.method_list in all .mat files in the given directory
% based on actual fields present in each file (excluding known non-method fields)

    mat_files = dir(fullfile(directory, '*.mat'));
    if isempty(mat_files)
        warning('No .mat files found in %s', directory);
        return;
    end

    % Fields to exclude from method list
    excluded_fields = {'meta_data', 'edge_level_stats', 'network_level_stats'};

    for i = 1:length(mat_files)
        file_path = fullfile(mat_files(i).folder, mat_files(i).name);
        try
            file_data = load(file_path);

            % Must contain meta_data
            if ~isfield(file_data, 'meta_data')
                fprintf('Skipping %s (no meta_data)', mat_files(i).name);
                continue;
            end

            % Get top-level fieldnames excluding known metadata/statistics
            method_fields = setdiff(fieldnames(file_data), excluded_fields);

            % Update method list
            file_data.meta_data.method_list = cell(method_fields');

            % Save updated meta_data back into the file
            meta_data = file_data.meta_data; %#ok<NASGU>
            save(file_path, 'meta_data', '-append');

            fprintf('Updated method_list in %s\n', mat_files(i).name);

        catch ME
            warning('Failed to update %s: %s', mat_files(i).name, ME.message);
        end
    end
end