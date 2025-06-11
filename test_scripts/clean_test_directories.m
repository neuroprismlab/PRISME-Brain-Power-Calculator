function clean_test_directories()
%% clean_test_directories
% Deletes specific test directories before running power calculator tests
% 
% This function removes only:
% - ./test_hcp_fc/
% - ./test_t2_fc/
% - ./test_r_fc/

    directories_to_delete = {'./power_calculator_results/test_hcp_fc/', './power_calculator_results/test_t2_fc/', ...
        './power_calculator_results/test_r_fc/'};
    
    for i = 1:length(directories_to_delete)
        dir_path = directories_to_delete{i};
        if exist(dir_path, 'dir')
            rmdir(dir_path, 's');  % 's' flag removes subdirectories recursively
            fprintf('Deleted directory: %s\n', dir_path);
        else
            fprintf('Directory not found (already clean): %s\n', dir_path);
        end
    end
    
    fprintf('Test directories cleaned successfully.\n');
    
end