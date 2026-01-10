function method_map = anp_single_file_method_map(meta_data)
    % Creates a map from method names to indices
    % 
    % Input:
    %   meta_data: metadata struct from a single file
    %
    % Output:
    %   method_map: containers.Map from method name to index
    
    method_list = meta_data.method_list;
    method_map = containers.Map();
    
    for i = 1:length(method_list)
        method_map(method_list{i}) = i;
    end
end
