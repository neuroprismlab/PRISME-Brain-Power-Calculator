function update_meta_data_submethods(directory)
    % update_meta_data_submethods
    % Processes all .mat files in the given directory by loading their brain_data 
    % and meta_data, updating meta_data to include the current repetition indices, 
    % and then saving both brain_data and meta_data to a new output folder.
    %
    % The output folder is fixed; for example, if the input is for 'abcd_fc', the 
    % updated files will be saved in '/Users/f.cravogomes/Desktop/Pc_Res_Updated/abcd_fc'.
    
    % Define input and output directories
    output_base = '/Users/f.cravogomes/Desktop/Pc_Res_Updated';

    [~, final_folder, ~] = fileparts(directory);
    output_dir = fullfile(output_base, final_folder);
    
    % Create output directory if it doesn't exist
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    % List all .mat files in the input directory
    files = dir(fullfile(directory, '*.mat'));
    
    for i = 1:length(files)
        file_path = fullfile(files(i).folder, files(i).name);
        
        % Load only the necessary variables: brain_data and meta_data
        ld = load(file_path, 'brain_data', 'meta_data');
      
        if isfield(ld, 'meta_data') && isfield(ld, 'brain_data')
            meta_data = ld.meta_data;
            brain_data = ld.brain_data;
            num_rep = sum(all(~isnan(brain_data.pvals_all), 1));
        
            
            % Update meta_data with the current repetition index.
            % Here we store the last repetition index from repetition_indices if it exists.
            meta_data.current_rep_index = num_rep;
            if isfield(meta_data, 'omnibus')
                meta_data = rmfield(meta_data, 'omnibus');
            end

            meta_data.parent_method = l_parent_method_name(meta_data);
            meta_data.significance_method = l_test_type_update(meta_data);
            if isfield(meta_data, 'test_type')
                meta_data = rmfield(meta_data, 'test_type');
            end

            data_set_name = strcat(meta_data.dataset, '_', meta_data.map);
            test_components = strjoin(meta_data.test_components, '_');
            [~, new_file_name] = create_and_check_rep_file('', data_set_name, test_components, meta_data.test, ...
                                                  meta_data.significance_method, meta_data.subject_number, ...
                                                  meta_data.testing_code);

            % Save both brain_data and meta_data to the new output directory using the same filename
            new_file_path = fullfile(output_dir, new_file_name);
            save(new_file_path, 'brain_data', 'meta_data');
        else
            error('File %s does not contain both brain_data and meta_data. Skipping...', files(i).name);
        end
    end
end

function parent_name = l_parent_method_name(meta_data)

    switch meta_data.test_type

        case 'Constrained_FDR'
            parent_name = 'Constrained';

        case 'Constrained'
            parent_name = 'Constrained'; 

        case 'Constrained_FWER'
            parent_name = 'Constrained'; 
         
        case 'Parametric_Bonferroni'
            parent_name = 'Parametric';

        case 'Parametric_FDR'
            parent_name = 'Parametric';
        
        case 'Parametric'
            parent_name = 'Parametric';
        
        case 'Size'
            parent_name = 'Size';
        
        case 'TFCE'
            parent_name = 'TFCE';
        
        case 'Omnibus'
            parent_name = 'Omnibus';
         
        otherwise
            error('Method %s name not supported', meta_data.test_type)
    end

end


function new_test_type = l_test_type_update(meta_data)

    switch meta_data.test_type

        case 'Constrained'
            new_test_type = 'Constrained_FDR'; 

        case 'Constrained_FWER'
            new_test_type = 'Constrained_FWER'; 
         
        case 'Parametric_Bonferroni'
            new_test_type = 'Parametric_FWER';

        case 'Parametric_FDR'
            new_test_type = 'Parametric_FDR';
        
        case 'Size'
            new_test_type = 'Size';
        
        case 'TFCE'
            new_test_type = 'TFCE';
        
        case 'Omnibus'
            new_test_type = 'Omnibus_Multidimensional_cNBS';
         
        otherwise
            error('Method %s name not supported', meta_data.test_type)
    end

end