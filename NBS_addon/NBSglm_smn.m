function test_stat = NBSglm_smn(GLM)
%% NBSglm_smn
% **Description**
% Fits a general linear model (GLM) to the data and computes the test statistic
% based on the specified test type. This function supports both t-tests (onesample
% and ttest) and F-tests, handling nuisance regressors using the Freedman &
% Lane method when applicable. If a dependent variable is identically zero, any
% resulting NaN test statistics are forced to zero.
%
% **Inputs**
% - GLM (struct): Structure containing the following fields:
%     - GLM.X:            n×p design matrix (with a column of ones if necessary).
%     - GLM.y:            n×M data matrix, where each column corresponds to a separate GLM.
%     - GLM.contrast:     1×p contrast vector (only one contrast can be specified).
%     - GLM.test:         Type of test: 'onesample', 'ttest', or 'ftest'.
%     - GLM.exchange:     (Optional) n×1 vector specifying exchange blocks for a repeated
%                         measures design.
%
% **Outputs**
% - test_stat (1×M vector): Vector of test statistics representing the result for each ROIvsROI.
%
% **Workflow**
% 1. Compute the regression coefficients (beta) using GLM.X and GLM.y.
% 2. Round beta to eliminate numerical issues.
% 3. For t-tests ('onesample' or 'ttest'):
%    - Compute residuals and mean squared error.
%    - Calculate the standard error using the contrast vector.
%    - Compute the t-statistic.
% 4. For F-tests ('ftest'):
%    - Compute sums of squares due to error (SSE) and regression (SSR) for both the
%      full and reduced models.
%    - If nuisance predictors are present, obtain the reduced model and compute the F-statistic.
% 5. Replace any NaN test statistic values with zero.
%
% **Notes**
% - A column of ones is always included in the reduced model unless it causes rank deficiency.
% - Nuisance regressors (indicated by zero contrast values) are handled using the Freedman &
%   Lane method.
% - The same permutation sequence is applied across GLMs for consistency in subsequent cluster-based inference.
% 
% **Date**: March 2025


test_stat=zeros(1, GLM.n_GLMs);

beta = GLM.X\GLM.y;

% Round beta to the nearest multiple of 1e-14 to remove numerical issues
beta = round(beta, 14);

%Compute statistic of interest
% TODO: consider moving to switch/case in glm_setup
if strcmp(GLM.test,'onesample') || strcmp(GLM.test,'ttest')

    % Compute the residuals
    resid = GLM.y - GLM.X * beta; 
    % Mean squared error
    mse = sum(resid.^2) / (GLM.n_observations - GLM.n_predictors); 
    % Compute the standard error using contrast
    se = sqrt(mse .* (GLM.contrast / (GLM.X' * GLM.X) * GLM.contrast'));
    % Prevent division by zero - numerical fix
    se(se < 1e-15) = 1e-15;
    % Compute the t-statistic
    test_stat(:) = (GLM.contrast * beta) ./ se;

elseif strcmp(GLM.test,'ftest')

    sse=zeros(1,GLM.n_GLMs);
    ssr=zeros(1,GLM.n_GLMs);
    %Sum of squares due to error
    sse=sum((GLM.y-GLM.X*beta).^2);
    %Sum of square due to regression
    ssr=sum((GLM.X*beta-repmat(mean(GLM.y),GLM.n_observations,1)).^2);
    if isempty(GLM.ind_nuisance)
        test_stat(:)=(ssr/(GLM.n_predictors-1))./(sse/(GLM.n_observations-GLM.n_predictors));
    else
        %Get reduced model
        %Column of ones will be added to the reduced model unless the
        %resulting matrix is rank deficient
        X_new=[ones(GLM.n_observations,1),GLM.X(:,GLM.ind_nuisance)];
        %+1 because a column of 1's will be added to the reduced model
        b_red=zeros(length(GLM.ind_nuisance)+1,GLM.n_GLMs);
        %Number of remaining variables
        v=length(find(GLM.contrast))-1;
        [GLM.n_observations,ncolx]=size(X_new);
        [Q,R,perm]=qr(X_new,0);
        rankx = sum(abs(diag(R)) > abs(R(1))*max(GLM.n_observations,ncolx)*eps(class(R)));
        if rankx < ncolx
            %Rank deficient, remove column of ones
            X_new=GLM.X(:,GLM.ind_nuisance);
            b_red=zeros(length(GLM.ind_nuisance),GLM.n_GLMs);
            v=length(find(GLM.contrast));
        end

        sse_red=zeros(1,GLM.n_GLMs);
        ssr_red=zeros(1,GLM.n_GLMs);
        b_red=X_new\GLM.y;
        sse_red=sum((GLM.y-X_new*b_red).^2);
        ssr_red=sum((X_new*b_red-repmat(mean(GLM.y),GLM.n_observations,1)).^2);
        test_stat(:)=((ssr-ssr_red)/v)./(sse/(GLM.n_observations-GLM.n_predictors));

    end
end

%Added to v1.1.2
%Covers the case where the dependent variable is identically zero for all
%observations. The test statistic in this case in NaN. Therefore, force any
%NaN elements to zero. This case is typical of connectivity matrices
%populated using streamline counts, in which case some regional pairs are
%not interconnected by any streamlines for all subjects. 
test_stat(isnan(test_stat)) = 0; 
    
