function stat_level = get_stat_level_from_file(rep_data, method)
    % Although this function is named from file, it uses the data loaded
    % directly from a file 
    
    if isfield(rep_data.meta_data, 'method_specific')
        stat_level = extract_stat_level(rep_data.meta_data.method_specific.(method).level);
    end
    
    % Legacy file format
    if isfield(rep_data.(method), 'meta_data')
        stat_level = extract_stat_level(rep_data.(method).meta_data.level);
    end

end