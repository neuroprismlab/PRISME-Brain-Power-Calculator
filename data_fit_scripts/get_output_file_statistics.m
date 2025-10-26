function results = get_output_file_statistics(file_name, varargin)

    % Input Parser 
    p = inputParser;

    addOptional(p, 'attribute', 'tpr');
    parse(p, varargin{:});
    attribute = p.Results.attribute;
    
    
    results = struct();
    results.mean = struct();
    results.deviation = struct();

    data = load(file_name);
    results.meta_data = data.meta_data;
    
    method_list = data.meta_data.method_list;
    for m = 1:length(method_list)
        method_name = method_list{m}; 

        results.mean.(method_name) = mean(data.(method_name).(attribute), 'omitnan');
        results.deviation.(method_name) = std(data.(method_name).(attribute), 'omitnan');
        
    end
    
    % Check if either is empty
    if isempty(fieldnames(results.mean)) || isempty(fieldnames(results.deviation))
        fprintf('At least one of mean or deviation is empty\n');
    end
    
end