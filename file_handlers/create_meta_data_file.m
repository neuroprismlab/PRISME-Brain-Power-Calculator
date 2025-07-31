function meta_data = create_meta_data_file(abs_filename, previous_meta_data, RP, rep_ids, existing_repetitions)
% This function creates the original subsample file. It contains only the
% meta_data, with other fields added through appending 
%
    
    % Initiliaze meta-data with previous things
    meta_data = previous_meta_data;
    
    % Method specific is important, so I decided to always make it the
    % first field - please keep this
    meta_data.method_specific = get_method_specific_meta_data(RP);

    rp_meta_data = extract_relevant_meta_data_from_RP(RP);

    % Merge rp_meta_data into meta_data
    fields = fieldnames(rp_meta_data);
    for i = 1:length(fields)
        meta_data.(fields{i}) = rp_meta_data.(fields{i});
    end
    
    % Merge with previous meta-data for relevant fields
    if isfield(previous_meta_data, 'statistical_method_class_name')
        meta_data.statistical_method_class_name = unique([previous_meta_data.statistical_method_class_name, ...
            RP.all_cluster_stat_types]);
    end
    if isfield(previous_meta_data, 'all_submethods')
        meta_data.all_submethods = unique([previous_meta_data.all_submethods, RP.all_submethods]);
    end
    if isfield(previous_meta_data, 'method_list')
        meta_data.method_list = unique([previous_meta_data.method_list, RP.all_full_stat_type_names]);
    end

    % Repetition Ids resulting from the draw
    meta_data.repetition_ids = rep_ids;
    meta_data.method_current_rep = existing_repetitions;
    
    if exist(abs_filename, 'file')
        save(abs_filename, 'meta_data', '-append');
    else
        save(abs_filename, 'meta_data');
    end

end