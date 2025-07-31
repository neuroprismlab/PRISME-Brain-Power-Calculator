function method_spe_meta_data = get_method_specific_meta_data(RP)
    
    method_spe_meta_data = struct();

    for stat_id = 1:length(RP.all_full_stat_type_names)
        method_name = RP.all_full_stat_type_names{stat_id};
        
        % Get method metadata
        method_class_name = RP.full_name_method_map(method_name);
        method_instance = feval(method_class_name);
        
        method_spe_meta_data.(method_name).level = method_instance.level;
        method_spe_meta_data.(method_name).parent_method = method_class_name;
        method_spe_meta_data.(method_name).is_permutation_based = method_instance.permutation_based;
        
    end

end