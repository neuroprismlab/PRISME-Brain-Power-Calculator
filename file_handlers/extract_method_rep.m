function existing_repetitions = extract_method_rep(file_type, file_path, meta_data, existing_repetitions)
    % This function extracts the existing repetitions from meta-data
    % This allows one to restart calculation from a point before
    % It's safer to check the method level for compact files
    switch file_type

        case 'full_file'
            if isfield(meta_data, 'method_current_rep')
                method_reps = meta_data.method_current_rep;
                method_names = fieldnames(method_reps);
                for i = 1:length(method_names)
                    method_name = method_names{i};
                    if isfield(existing_repetitions, method_name)
                        existing_repetitions.(method_name) = method_reps.(method_name);
                    end
                end
            end

        case 'compact_file'
            file_info = whos('-file', file_path);  
            file_vars = {file_info.name};
            
            % Get method names from existing_repetitions
            method_names = fieldnames(existing_repetitions);
            
            for i = 1:length(method_names)
                method_name = method_names{i};
                
                if ismember(method_name, file_vars)
                    % Load just this method's struct
                    loaded_data = load(file_path, method_name);
                    method_struct = loaded_data.(method_name);
                    
                    % Use total_calculations field to get actual repetition count
                    if isfield(method_struct, 'total_calculations')
                        existing_repetitions.(method_name) = method_struct.total_calculations;
                    else
                        error('Compact file meta-data missing repetitions field. The data is corrupted')
                    end
                else
                    % Method doesn't exist in file yet, so 0 repetitions
                    existing_repetitions.(method_name) = 0;
                end
            end
    end

    
end