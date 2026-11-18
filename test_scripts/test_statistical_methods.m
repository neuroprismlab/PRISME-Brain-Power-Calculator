function test_statistical_methods()
%% test_nbsglm_smn
% Unit tests for NBSglm_smn (t-test branch: 'onesample' / 'ttest').
%
% Each case builds a GLM struct the same way the pipeline does
% (design matrix X, data Y, contrast, then NBSglm_setup_smn) and compares the
% returned t-statistics with independent references: closed-form formulas
% and, when available, Statistics Toolbox functions (ttest, ttest2, fitlm).
%
% Design matrices follow the pipeline conventions:
%   't'  : X = ones(n,1),            contrast = 1
%   't2' : X = [group1 group2] dummies, contrast = [1 -1]
%   'r'  : X = [score ones],         contrast = [1 0]
%
% The 'ftest' branch is not covered here (not used by the pipeline).

    fprintf('Testing statistical methods on the toolbox\n');
    rng(42);
    %test_Parametric(1e-5);
    %test_Size_cpp(1e-5);
    %test_Fast_TFCE_cpp(1e-5);
    %test_Constrained(1e-5);
    %test_Constrained_cpp(1e-5);


end

%%%%%% Test Parametric
function test_Parametric(tol)
    %% test_parametric
    % Unit test for the Parametric method (FWER and FDR submethods).
    %
    % Values are hardcoded to assure consistency 
    
    t = [4.5, 3.2, 2.5, 2.1, 1.5, 0.8, 0.0, -0.8, -1.5, -3.0];
    
    % min(10 * p, 1) with p = P(T > t), df = 20
    p_fwer = [ ...
        0.001093856058685913, 0.022481077773590576, 0.10616772719566189, ...
        0.2430879362877848, 0.7461788558462623, 1, 1, 1, 1, 1];
    
    GLM = struct();
    GLM.test = 'ttest';
    % 20 is the desired for these p-values
    % 22 - 2 in the tcdf
    GLM.n_observations = 22;   
    
    STATS = struct();
    STATS.submethods.FWER = true;
    STATS.submethods.FDR = true;
    
    method = Parametric();
    pvals = method.run_method( ...
        'statistical_parameters', STATS, ...
        'glm_parameters', GLM, ...
        'edge_stats', t);
    
    % Comparison between values
    assert(all(abs(pvals.FWER(:).' - p_fwer) < tol), ...
        'Parametric: FWER differs from the hard-coded values');
end

%%%%%% Test Size_cpp
function test_Size_cpp(tol)
    %% test_Size_cpp
    % Unit test for the Size_cpp method on a 5-node network with 10 edges
    % Permutation and Data come from size_cpp_test_data function.
    %
    % The null is the maximum number of connections in each permutation
    
    % Mask is 5vs5 upper diagonal filled with 1s
    mask = triu(true(5), 1);
    
    STATS = struct();
    STATS.mask = mask;
    STATS.thresh = 3.1;
    STATS.unflatten_matrix = unflatten_matrix(mask);
    
    % Data, permutations, and expected p-values
    [obs, perms, p_size, ~] = size_cpp_test_data();

    % Flatten to the pipeline's edge vector: (1,2),(1,3),(2,3),(1,4),(2,4),
    % (3,4),(1,5),(2,5),(3,5),(4,5)
    % The vectors must be flattened to match PRISME pipeline input
    K = size(perms, 3);
    % Collapse into vector;
    edge_stats = obs(mask);
    % Use only the logicals in the mask
    permuted_edge_stats = zeros(nnz(mask), K);
    for k = 1:K
        P = perms(:, :, k);
        % Reshape to col permutations
        permuted_edge_stats(:, k) = P(mask);
    end
    
    method = Size_cpp();
    pval = method.run_method( ...
        'statistical_parameters', STATS, ...
        'edge_stats', edge_stats, ...
        'permuted_edge_data', permuted_edge_stats);
    
    assert(all(abs(pval(:) - p_size) < tol), ...
        'Size_cpp: p-values differ from the hard-coded values');
end


%%%% Test TFCE
function test_Fast_TFCE_cpp(tol)
    %% test_Fast_TFCE_cpp
    % Unit test for the Fast_TFCE_cpp method on a 5-node network (10 edges).
    % Data come from size_cpp_test_data - size they use the same data -
    % perms
    [obs, perms, ~, p_tfce] = size_cpp_test_data();

    mask = triu(true(5), 1);
    
    STATS = struct();
    STATS.mask = mask;
    STATS.unflatten_matrix = unflatten_matrix(mask);
    STATS.flatten_matrix = create_flat_function(mask);
    
    % Same deal as size - prepare input for method 
    edge_stats = obs(mask);
    permuted_edge_stats = reshape(perms, [], size(perms, 3));
    permuted_edge_stats = permuted_edge_stats(mask(:), :);

    method = Fast_TFCE_cpp();
    pval = method.run_method( ...
        'statistical_parameters', STATS, ...
        'edge_stats', edge_stats, ...
        'permuted_edge_data', permuted_edge_stats);

    assert(all(abs(pval(:) - p_tfce) < tol), ...
        'Fast_TFCE_cpp: p-values differ from the hard-coded values');

end

%%%% Test Constrained
function test_Constrained(tol)
    % Tests the cNBS method for correct p-values
    
    % Stats for method
    STATS = struct();
    
    % Create mask and flatten and unflatten functions
    mask = triu(true(5), 1);
    STATS.mask = mask;
    STATS.unflatten_matrix = unflatten_matrix(mask);
    STATS.flatten_matrix = create_flat_function(mask);
    STATS.alpha = 0.05;
    
    % Test both submethods
    STATS.submethods.FWER = true;
    STATS.submethods.FDR = true;

    % Get edge_groups, stats, and perm data
    [edge_groups, obs, perms, p_fwer, p_fdr] = network_test_data();
    K = size(perms, 3);
    STATS.edge_groups = edge_groups;
    edge_stats = obs(mask);
    permuted_edge_stats = zeros(nnz(mask), K);
    for k = 1:K
        P = perms(:, :, k);
        permuted_edge_stats(:, k) = P(mask);
    end

    method = Constrained();
    pval = method.run_method( ...
        'statistical_parameters', STATS, ...
        'edge_stats', edge_stats, ...
        'permuted_edge_data', permuted_edge_stats);

    % Comparison between values
    assert(all(abs(pval.FWER(:).' - p_fwer) < tol), ...
        'Constrained: FWER differs from the hard-coded values');

    % Comparison between values
    assert(all(abs(pval.FDR(:).' - p_fdr) < tol), ...
        'Constrained: FDR differs from the hard-coded values');

end


%%%% Test Constrained_cpp
function test_Constrained_cpp(tol)
% Tests the cNBS (C++) method for correct p-values

    STATS = struct();
    
    mask = triu(true(5), 1);
    STATS.mask = mask;
    STATS.unflatten_matrix = unflatten_matrix(mask);
    STATS.flatten_matrix = create_flat_function(mask);
    STATS.alpha = 0.05;
    
    STATS.submethods.FWER = true;
    STATS.submethods.FDR = true;
    
    [edge_groups, obs, perms, p_fwer, p_fdr] = network_test_data();
    K = size(perms, 3);
    STATS.edge_groups = edge_groups;
    edge_stats = obs(mask);
    permuted_edge_stats = zeros(nnz(mask), K);
    for k = 1:K
        P = perms(:, :, k);
        permuted_edge_stats(:, k) = P(mask);
    end
    
    method = Constrained_cpp();
    pval = method.run_method( ...
        'statistical_parameters', STATS, ...
        'edge_stats', edge_stats, ...
        'permuted_edge_data', permuted_edge_stats);
    
    assert(all(abs(pval.FWER(:).' - p_fwer) < tol), ...
        'Constrained_cpp: FWER differs from the hard-coded values');
    
    assert(all(abs(pval.FDR(:).' - p_fdr) < tol), ...
        'Constrained_cpp: FDR differs from the hard-coded values');
end

%%% Test Ominibus_cNBS(tol)
