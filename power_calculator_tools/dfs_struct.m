function RepData = dfs_struct(f_call, RepData)

    % This is for testing - when set to true only the first path is
    % explored

    RepData = dfs_recursion(RepData, {}, RepData);
    

    function RepData = dfs_recursion(node, path_cell, RepData)
        
        fields = fieldnames(node); 

        %% Loop over 
        for i = 1:numel(fields)
            field_name = fields{i};
            path_cell = [path_cell, {field_name}];
    
            %% Stopping condition?
            flag_meta = strcmp(field_name, 'meta_data');
            flag_brain = strcmp(field_name, 'brain_data');
            
            if ~flag_meta && ~flag_brain

                RepData = dfs_recursion(node.(field_name), path_cell, RepData); 

            elseif flag_meta
                path_cell = path_cell(1:end-1);
                
                data = getfield(RepData, path_cell{:});
                f_call(data);
              
            end
            path_cell = path_cell(1:end-1);   

        end
 
    end

end
