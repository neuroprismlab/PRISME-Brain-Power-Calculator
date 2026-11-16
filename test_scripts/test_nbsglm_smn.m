function test_nbsglm_smn()
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
    
    fprintf('test_nbsglm_smn: Testing GLM fit function \n');
    rng(1);

    test_one_sample(5);
    test_one_sample_effect(0.2);
    test_two_sample(6);
    test_correlation(6);
    test_invariances(1e-8);

    fprintf('test_nbsglm_smn: GLM Fit passed test \n');

end


%% ------------------------------------------------------------------------
function test_one_sample(tol)
% Null data (true mean 0), 100 subjects, fixed seed.
% t is ~N(0,1) under the null, so assert a loose bound, not equality with 0.
    n = 500;
    m = 5;
    Y = randn(n, m);
    X = ones(n, 1);

    t = run_glm(X, Y, 1);

    assert(isequal(size(t), [1, m]), 'One-sample: output must be 1 x n_GLMs');
    assert(all(abs(t) < tol), 'One-sample: null data should be bellow tolerance');

end


%% -----------------------------------------------------------------------
function test_one_sample_effect(tol)
    % Known population mean and standard deviation per column.
    % Expected t is d*sqrt(n), with d = mu/sigma (Cohen's d for a one-sample test).
    % The sample t is compared with this value through d_hat = t/sqrt(n).
    n = 1000;
    d     = [0.2, 0.5, 0.8, -0.5, 0.0];   % true standardized effect sizes
    sigma = [1.0, 2.0, 0.5,  3.0, 1.0];   % true standard deviations
    mu    = d .* sigma;                   % true means
    m     = numel(d);                         % tolerance on the recovered effect size
    
    Y = mu + sigma .* randn(n, m);        % column j ~ N(mu(j), sigma(j)^2)
    X = ones(n, 1);
    
    t = run_glm(X, Y, 1);
    
    assert(isequal(size(t), [1, m]), 'One-sample effect: output must be 1 x n_GLMs');
    
    % Recover the effect size from t and compare with the known one
    d_hat = t ./ sqrt(n);
    assert(all(abs(d_hat - d) < tol), ...
        'One-sample effect: t/sqrt(n) differs from the true effect size');

end

%% ------------------------------------------------------------------------
function test_two_sample(tol)
    % Two groups with known population means and standard deviations per column.
    % Group 1 has mean delta, group 2 has mean 0, both with sd sigma.
    % Expected t = delta / (sigma * sqrt(1/n1 + 1/n2)).
    n1 = 200;
    n2 = 250;
    n  = n1 + n2;
    
    % Group distances and std deviations 
    delta = [0.0, 1.0,  2.0, -1.0, 0.5];   
    sigma = [1.0, 1.0,  2.0,  0.5, 1.0];  
    % Number of GLMs 
    m     = numel(delta);
    
    % Generate group with difference
    Y = sigma .* randn(n, m);             
    Y(1:n1, :) = Y(1:n1, :) + delta;      

    % Create design matrix for both groups
    X = zeros(n, 2);
    X(1:n1, 1) = 1;
    X(n1+1:end, 2) = 1;
    
    % Run GLM fits
    t = run_glm(X, Y, [1, -1]);

    assert(isequal(size(t), [1, m]), 'Two-sample: output must be 1 x n_GLMs');

    % Expected t from the known population parameters
    t_expected = delta ./ (sigma .* sqrt(1/n1 + 1/n2));
    assert(all(abs(t - t_expected) < tol), ...
        'Two-sample: t differs from the expected value for the known means');

    % Swapping the contrast sign must flip the statistic
    t_swapped = run_glm(X, Y, [-1, 1]);
    assert(all(abs(t_swapped + t) < tol), ...
        'Two-sample: contrast [-1 1] should give -t');
end

function test_correlation(tol)
    % Known population correlation per column, n = 1000.
    % Expected t = rho*sqrt(n-2)/sqrt(1-rho^2), hard-coded below:
    %   rho =  0.3 ->   9.934953281384704
    %   rho =  0.6 ->  23.69335349839697
    %   rho = -0.3 ->  -9.934953281384704
    %   rho = -0.6 -> -23.69335349839697
    %   rho =  0.0 ->   0
    n   = 1000;
    % Set of true correlations
    rho = [0.3, 0.6, -0.3, -0.6, 0.0];   
    m   = numel(rho);
    
    % Hard coded t-stats
    t_expected = [9.934953281384704, 23.69335349839697, ...
        -9.934953281384704, -23.69335349839697, 0];

    % score ~ N(0,1); each column has corr(score, Y_j) = rho_j in the population
    score = randn(n, 1);
    Y = score * rho + sqrt(1 - rho.^2) .* randn(n, m);
    
    % Scores plus one matrix - run glm
    X = [score, ones(n, 1)];
    t = run_glm(X, Y, [1, 0]);

    assert(isequal(size(t), [1, m]), 'Correlation: output must be 1 x n_GLMs');
    assert(all(abs(t - t_expected) < tol), ...
        'Correlation: t differs from the expected value for the known correlation');
end



%% ------------------------------------------------------------------------
function test_invariances(tol)
    n = 35; 
    m = 9;
    score = randn(n, 1);
    Y = randn(n, m) + 0.5 * score;
    X = [score, ones(n, 1)];
    t = run_glm(X, Y, [1, 0]);

    % The pipeline derives the negative statistic as -t
    assert_close(run_glm(X, -Y, [1, 0]), -t, tol, 'Negating Y should negate t');

    % Rescaling the data must not change t
    assert_close(run_glm(X, 7.5 * Y, [1, 0]), t, tol, 'Rescaling Y changed t');

    % Shifting the data must not change t when an intercept is present
    assert_close(run_glm(X, Y + 100, [1, 0]), t, tol, 'Shifting Y changed t');

    % Linear transform of the score must not change t
    X_aff = [3 * score + 10, ones(n, 1)];
    assert_close(run_glm(X_aff, Y, [1, 0]), t, tol, 'Affine transform of score changed t');

    % GLMs are independent: a single column must match its place in the full run
    for j = [1, 4, m]
        tj = run_glm(X, Y(:, j), [1, 0]);
        assert_close(tj, t(j), tol, ...
            sprintf('Column %d fitted alone differs from the joint fit', j));
    end

    % Row order of the subjects must not matter (design and data permuted together)
    idx = randperm(n);
    assert_close(run_glm(X(idx, :), Y(idx, :), [1, 0]), t, tol, ...
        'Reordering subjects changed t');
end


%% ------------------------------------------------------------------------
function t = run_glm(X, Y, contrast)

    % Build the GLM struct as the pipeline does and fit it
    GLM = struct();
    GLM.X = X;
    GLM.y = Y;
    GLM.contrast = contrast;
    GLM.test = 'ttest';
    GLM = NBSglm_setup_smn(GLM);
    t = NBSglm_smn(GLM);

end


function assert_close(actual, expected, tol, msg)
    err = max(abs(actual(:) - expected(:)) ./ max(1, abs(expected(:))));
    assert(err < tol, '%s (max relative error %.3g, tol %.3g)', msg, err, tol);
end
