function data = util_extract_subject_data(Brain_Data, task, sub_id)
    task_data = Brain_Data.(task);
    data = task_data.data(:, sub_id);
end