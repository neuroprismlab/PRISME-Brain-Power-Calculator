function check_results_rep_integrity(dataset_or_directory)

    files = data_set_or_directory_mat_file_loading(dataset_or_directory);

    for i = 1:numel(files)
        file_path = fullfile(files(i).folder, files(i).name);
        
        data = load(file_path);

        expected_rep_number = data.meta_data.rep_parameters.n_repetitions;

        % Assume these are your matrices
        pvals_all = data.brain_data.pvals_all;
        pvals_all_neg = data.brain_data.pvals_all_neg;
        
        % Find columns with no NaNs
        num_valid_cols_all = sum(all(~isnan(pvals_all), 1));
        num_valid_cols_neg = sum(all(~isnan(pvals_all_neg), 1));
        
        if num_valid_cols_all ~= expected_rep_number || num_valid_cols_neg ~= expected_rep_number
            error('File %s does not have the correct number of repetitions', files(i).name)
        end
        
    end

    fprintf('The files in %s passed the repetition check', dataset_or_directory)
       
end 