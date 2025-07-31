function matching_datasets_check(rep_file_meta_data, gt_meta_data)
   
    rep_dataset = get_data_set_file_name(rep_file_meta_data);
    gt_dataset =  get_data_set_file_name(gt_meta_data);
    
    if ~strcmp(rep_dataset, gt_dataset)
       error('Dataset mismatch between repetition file and ground truth file');
    end

end

