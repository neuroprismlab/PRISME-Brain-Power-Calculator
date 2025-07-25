function remove_method_from_data(method_cell, directory)
    % Remove specified methods from all .mat files in a directory
    %
    % Inputs:
    %   method_cell - cell array of method names to remove (e.g., {'method1', 'method2'})
    %   directory   - path to directory containing .mat files
    
    % Get list of .mat files in directory
    mat_files = dir(fullfile(directory, '*.mat'));
    
    % Process each .mat file
    for i = 1:length(mat_files)
        file_path = fullfile(directory, mat_files(i).name);
        
        % Load the .mat file
        data = load(file_path);
        field_names = fieldnames(data);
        
        % Check each field and remove if it matches any method
        for j = 1:length(field_names)
            field_name = field_names{j};
            
            % Check if this field exactly matches any method in method_cell
            for k = 1:length(method_cell)
                if strcmp(field_name, method_cell{k})
                    data = rmfield(data, field_name);
                    fprintf('Removed field "%s" from %s\n', field_name, mat_files(i).name);
                    break;
                end
            end
        end
        
        % Also remove methods from metadata if it exists
        if isfield(data, 'meta_data')
            % Remove from method_list if it exists
            if isfield(data.meta_data, 'method_list')
                method_list = data.meta_data.method_list;
                methods_to_keep = {};
                
                for m = 1:length(method_list)
                    keep_method = true;
                    for k = 1:length(method_cell)
                        if strcmp(method_list{m}, method_cell{k})
                            keep_method = false;
                            fprintf('Removed method "%s" from method_list in %s\n', method_list{m}, mat_files(i).name);
                            break;
                        end
                    end
                    if keep_method
                        methods_to_keep{end+1} = method_list{m};
                    end
                end
                
                data.meta_data.method_list = methods_to_keep;
            end
            
            % Remove from method_current_rep if it exists
            if isfield(data.meta_data, 'method_current_rep')
                for k = 1:length(method_cell)
                    if isfield(data.meta_data.method_current_rep, method_cell{k})
                        data.meta_data.method_current_rep = rmfield(data.meta_data.method_current_rep, method_cell{k});
                        fprintf('Removed method "%s" from method_current_rep in %s\n', method_cell{k}, mat_files(i).name);
                    end
                end
            end
        end
        
        % Save the modified data back to the same file
        save(file_path, '-struct', 'data');
        fprintf('Updated file: %s\n', mat_files(i).name);
    end
    
    fprintf('Processing complete!\n');
end