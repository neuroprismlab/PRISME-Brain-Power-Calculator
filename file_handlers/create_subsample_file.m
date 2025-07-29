function create_subsample_file(abs_filename, RP)
% This function creates the original subsample file. It contains only the
% meta_data, with other fields added through appending 
%
    
    if exits(abs_filename)
        error('File %s already exists')
    end

    meta_data = extract_relevant_meta_data_from_RP(RP);

end