function generate_permutation_for_repetition(rep_number, GLM, RP)
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

    permuted_data = zeros(RP.n_var, RP.n_perms); % Prelocate double
    permuted_network_data = zeros(numel(unique(RP.edge_groups)) - 1, RP.n_perms);
    for i = 1:RP.n_perms
        % Generate permuted data
        permuted_GL = GLM;
        permuted_GL.y = permute_signal(GLM);  % Apply permutation
        permutation_edge_stats = NBSglm_smn(permuted_GL);
        
        % Store permutation
        permuted_data(:, i) = permutation_edge_stats;

        % Compute and store network-level statistics
        edge_stat_square = unflatten_matrix(permutation_edge_stats, RP.mask);
        network_stat = get_network_average(edge_stat_square, RP.edge_groups);
        permuted_network_data(:, i) = network_stat;
    end
    
    % Save permutations to file
    save(perm_file, 'permuted_data', 'permuted_network_data', '-v7.3'); % Use '-v7.3' for large data compatibility
    
end