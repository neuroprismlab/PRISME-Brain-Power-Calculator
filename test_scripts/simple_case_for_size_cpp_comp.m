% Clear workspace except specific variables
vars = who; % Get a list of all variable names in the workspace
vars(strcmp(vars, 'data_matrix')) = []; % Remove the variable you want to keep from the list
vars(strcmp(vars, 'testing_yml_workflow')) = [];
clear(vars{:}); % Clear all other variables
clc;

% Define the number of nodes
N = 4;

% Create the edge statistics matrix with values (not binary)
edge_stats = [0, 3.5, 4.2, 3.8;
               3.5, 0, 3.9, 2.9;
               4.2, 3.9, 0, 3.5;
               3.8, 2.9, 3.5, 0];

% Set threshold at 3.1 (anything above is significant)
threshold = 3.1;

% Convert to binary adjacency matrix for significant connections
edge_stats_mask = edge_stats > threshold;

% Create permutation matrices with edge statistics values
perm1 = zeros(N, N);
perm1(1, 2) = 3.7; perm1(2, 1) = 3.7; % Above threshold
perm1(1, 3) = 2.9; perm1(3, 1) = 2.9; % Below threshold

perm2 = zeros(N, N);
perm2(1, 3) = 3.4; perm2(3, 1) = 3.4; % Above threshold
perm2(2, 4) = 2.8; perm2(4, 2) = 2.8; % Below threshold

perm3 = zeros(N, N);
perm3(2, 3) = 3.5; perm3(3, 2) = 3.5; % Above threshold
perm3(1, 4) = 2.7; perm3(4, 1) = 2.7; % Below threshold

perm4 = zeros(N, N);
perm4(2, 4) = 3.3; perm4(4, 2) = 3.3; % Above threshold
perm4(3, 4) = 2.9; perm4(4, 3) = 2.9; % Below threshold

perm5 = zeros(N, N);
perm5(3, 4) = 3.6; perm5(4, 3) = 3.6; % Above threshold
perm5(1, 2) = 2.8; perm5(2, 1) = 2.8; % Below threshold

% Convert permutation matrices to binary based on threshold
perm_mask1 = perm1 > threshold;
perm_mask2 = perm2 > threshold;
perm_mask3 = perm3 > threshold;
perm_mask4 = perm4 > threshold;
perm_mask5 = perm5 > threshold;

% Combine permutations into a 3D array
perm_matrices = cat(3, perm_mask1, perm_mask2, perm_mask3, perm_mask4, perm_mask5);

% Display the matrices
disp('Edge Statistics Matrix:');
disp(edge_stats);
disp('Binary Adjacency Matrix (after threshold):');
disp(edge_stats_mask);
disp('Permutation Matrices (after threshold):');
for i = 1:5
    disp(['Permutation ' num2str(i) ':']);
    disp(perm_matrices(:,:,i));
end

% Run C++ implementation
disp('Running size_pval_cpp...');
pvals_cpp = size_pval_cpp(double(edge_stats_mask), double(perm_matrices));
disp('C++ result:');
disp(pvals_cpp);

% Now run the MATLAB implementation
disp('Running get_edge_components...');
[cluster_stats, max_stat] = get_edge_components(double(edge_stats_mask), false, zeros(size(edge_stats_mask)), 0, N, find(triu(ones(N))), exist('components', 'file'));

% Calculate p-values manually similarly to the Size class
disp('Connected components:');
disp(cluster_stats);

% Create null distribution from permutation matrices
null_dist = zeros(5, 1);
for i = 1:5
    [~, max_stat_perm] = get_edge_components(double(perm_matrices(:,:,i)), false, zeros(size(perm_matrices(:,:,i))), 0, N, find(triu(ones(N))), exist('components', 'file'));
    null_dist(i) = max_stat_perm;
end

disp('Null distribution:');
disp(null_dist);

% Compute p-values (Size class approach)
pvals_matlab = zeros(size(cluster_stats));
for i = 1:N
    for j = 1:N
        if cluster_stats(i,j) > 0
            pvals_matlab(i,j) = sum(cluster_stats(i,j) <= null_dist) / 5;
        else
            pvals_matlab(i,j) = 1;
        end
    end
end

disp('MATLAB result:');
disp(pvals_matlab);


% Compare results
disp('Difference (C++ - MATLAB):');
disp(pvals_cpp - pvals_matlab);