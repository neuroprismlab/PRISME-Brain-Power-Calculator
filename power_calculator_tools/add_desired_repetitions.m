function existing_repetitions = add_desired_repetitions(all_full_method_names, existing_repetitions)

    existing_methods = fieldnames(existing_repetitions);
    
    n_methods = numel(all_full_method_names);
    for i = 1:n_methods
        method = all_full_method_names{i};
        
        if ~ismember(method, existing_methods)
            continue
        end
        
        existing_repetitions.(method) = 0;
    end

end 