function meta_data = create_meta_data_file(abs_filename, RP, rep_ids, existing_repetitions)
% This function creates the original subsample file. It contains only the
% meta_data, with other fields added through appending 
%
    
    % Initiliaze empty struct
    meta_data = struct();
    
    % Method specific is important, so I decided to always make it the
    % first field - please keep this
    meta_data.method_specific = get_method_specific_meta_data(RP);

    rp_meta_data = extract_relevant_meta_data_from_RP(RP);

    % Merge rp_meta_data into meta_data
    fields = fieldnames(rp_meta_data);
    for i = 1:length(fields)
        meta_data.(fields{i}) = rp_meta_data.(fields{i});
    end

    % Repetition Ids resulting from the draw
    meta_data.repetition_ids = rep_ids;
    meta_data.method_current_rep = existing_repetitions;

    
    save(abs_filename, 'meta_data', '-v7.3');

end