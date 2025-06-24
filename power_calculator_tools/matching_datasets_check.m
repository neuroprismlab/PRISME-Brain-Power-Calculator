function matching_datasets_check(rep_file_meta_data, gt_meta_data)
   
    [~, rep_dataset, ~] = fileparts(rep_file_meta_data.rep_parameters.data_dir);
    [~, gt_dataset, ~] = fileparts(gt_meta_data.rep_parameters.data_dir);
    
    if ~strcmp(rep_dataset, gt_dataset)
       error('Dataset mismatch between repetition file and ground truth file');
    end

end

