function attribute_map = anp_map_attribute_to_index(meta_data_array, extract_fn)
    % Maps attribute values to sequential indices
    % 
    % Inputs:
    %   meta_data_array: cell array of metadata structs from all files
    %   extract_fn: function handle to extract attribute (e.g., @(md) md.study_name)
    %
    % Output:
    %   attribute_map: containers.Map from attribute value to index
   
    attribute_map = containers.Map();

    counter = 0;
    
    % Loop through each metadata and build index map
    for i = 1:length(meta_data_array)
        attribute_value = extract_fn(meta_data_array{i});
        
        % Convert to string for uniform key handling
        attribute_key = string(attribute_value);

        % Add to map if not already present
        if ~isKey(attribute_map, attribute_key)
            counter = counter + 1; 
            attribute_map(attribute_key) = counter;
        end
    end
end