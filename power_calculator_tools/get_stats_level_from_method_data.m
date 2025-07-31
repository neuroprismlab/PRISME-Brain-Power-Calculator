function stat_level = gets_stats_level_from_method_data(method_name, method_data, meta_data)


    if isfield(meta_data, 'method_specific')
        stat_level = extract_stat_level(meta_data.method_specific.(method_name).level);
        return;
    end
    
    % Legacy 
    if isfield(method_data, 'meta_data')
        stat_level = extract_stat_level(method_data.meta_data.level);
        return;
    end


end 