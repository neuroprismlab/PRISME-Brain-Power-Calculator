function generate_permutation_for_repetition(rep_number, GLM, num_permutations, n_var)
    % generate_permutation_for_repetition
    % 
    % This function precomputes and saves permuted GLM data for a given repetition.
    %
    % Inputs:
    %   - rep_number: Integer, the repetition index (used for file naming).
    %   - GLM: Struct, original GLM structure containing design matrix & data.
    %   - num_permutations: Integer, number of permutations to generate.
    %
    % Outputs:
    %   - Saves a file named 'permutation_X.mat' inside 'GLM_permutations' folder.
    
    % Define output directory
    perm_folder = fullfile(pwd, 'GLM_permutations');
    
    % Create folder if it doesn't exist
    if ~exist(perm_folder, 'dir')
        mkdir(perm_folder);
    end
    
    % Define output file path
    perm_file = fullfile(perm_folder, sprintf('permutation_%d.mat', rep_number));
    
    % Generate permutations

    permuted_data = zeros(n_var, num_permutations); % Preallocate cell array
    for i = 1:num_permutations
        % Generate permuted data
        permuted_GL = GLM;
        permuted_GL.y = permute_signal(GLM);  % Apply permutation
        permutation_edge_stats = NBSglm_smn(permuted_GL);
        
        % Store permutation
        permuted_data(:, i) = permutation_edge_stats;
    end
    
    % Save permutations to file
    save(perm_file, 'permuted_data', '-v7.3'); % Use '-v7.3' for large data compatibility
    
    fprintf('Saved %d permutations for repetition %d to %s\n', num_permutations, rep_number, perm_file);
end