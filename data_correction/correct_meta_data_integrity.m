function correct_meta_data_integrity(directory_path)
    % Get all .mat files in the directory
    files = dir(fullfile(directory_path, '*.mat'));
    
    % Check if any files were found
    if isempty(files)
        error('No .mat files found in the specified directory: %s', directory_path);
    end
    
    for i = 1:length(files)
        file_path = fullfile(directory_path, files(i).name);
        disp(['Processing file: ', file_path]);
        
        % Load the data file
        data = load(file_path);
        
        % Get all fieldnames from the data structure
        all_fields = fieldnames(data);
        
        % Exclude meta_data, edge_level_stats, and network_level_stats
        excluded_fields = {'meta_data', 'edge_level_stats', 'network_level_stats'};
        method_fields = all_fields(~ismember(all_fields, excluded_fields));
        
        % Update the method_list in meta_data
        data.meta_data.method_list = method_fields';
        
        % Check sig_prob matrices for non-NaN columns in each method field
        for j = 1:length(method_fields)
            field_name = method_fields{j};
            
            % Skip if the field doesn't have sig_prob or sig_prob_negative
            if ~isfield(data.(field_name), 'sig_prob') && ~isfield(data.(field_name), 'sig_prob_negative')
                disp(['Skipping field ', field_name, ': No sig_prob or sig_prob_negative found']);
                continue;
            end
            
            % Calculate non-NaN columns
            non_nan_count = 0;
            
            % Check sig_prob if it exists
            if isfield(data.(field_name), 'sig_prob')
                sig_prob_matrix = data.(field_name).sig_prob;
                non_nan_columns = sum(~isnan(sig_prob_matrix), 1) > 0;
                non_nan_count = sum(non_nan_columns);
            end
            
            % Check sig_prob_negative if it exists
            if isfield(data.(field_name), 'sig_prob_negative')
                sig_prob_neg_matrix = data.(field_name).sig_prob_negative;
                non_nan_columns_neg = sum(~isnan(sig_prob_neg_matrix), 1) > 0;
                non_nan_count = max(non_nan_count, sum(non_nan_columns_neg));
            end
            
            % Update method_current_rep for this field
            data.meta_data.method_current_rep.(field_name) = non_nan_count;
        end
        
        % Save the updated file, overriding the old one
        save(file_path, '-struct', 'data');
        disp(['Updated and saved: ', file_path]);
    end
    
    disp('Metadata integrity correction completed for all files.');
end