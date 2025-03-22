function GLM = NBSglm_setup_smn(GLM)
%% NBSglm_setup_smn
% **Description**
% Sets up the GLM structure for running the general linear model (GLM) in NBSglm,
% including computing count variables, identifying nuisance predictors, setting up
% exchange blocks (if provided), and performing nuisance regression.
%
% **Inputs**
% - GLM (struct): A structure that must contain the following fields:
%     - GLM.X:            n×p design matrix, where p is the number of predictors.
%     - GLM.y:            n×M data matrix, with each column representing a separate GLM.
%     - GLM.contrast:     1×p contrast vector (logical or binary indicator).
%     - GLM.test:         Type of test (e.g., 'onesample', 'ttest', 'ftest').
%     - (Optional) GLM.exchange: n×1 vector specifying exchange blocks for repeated measures.
%
% **Outputs**
% - GLM (struct): Updated with additional fields:
%     - GLM.n_predictors: Number of predictors (including intercept).
%     - GLM.n_GLMs:       Number of independent GLMs (number of columns in GLM.y).
%     - GLM.n_observations: Number of observations (number of rows in GLM.y).
%     - GLM.ind_nuisance: Indices of nuisance predictors (where contrast is false).
%     - If GLM.exchange is present:
%         - GLM.blks:       Unique exchange blocks.
%         - GLM.n_blks:     Number of exchange blocks.
%         - GLM.sz_blk:     Number of observations per block.
%         - GLM.blk_ind:    Indices for each block.
%     - If nuisance predictors exist:
%         - GLM.b_nuisance: Regression coefficients for nuisance predictors.
%         - GLM.resid_y:    Residuals after regressing out nuisance effects.
%
% **Workflow**
% 1. Compute the number of predictors, independent GLMs, and observations.
% 2. Determine nuisance predictors as those where GLM.contrast is false.
% 3. If GLM.exchange is provided, set up exchange blocks by computing unique
%    block values, block sizes, and block indices.
% 4. If nuisance predictors are found, regress them out of GLM.y to obtain residuals.
%
% **Notes**
% - Assumes that GLM.contrast is a logical or binary vector.
% - If no nuisance predictors are identified, the nuisance regression step is skipped.
% 
% **Date**: March 2025

%Number of predictors (including intercept)
GLM.n_predictors = length(GLM.contrast);

%Number of independent GLM's to fit
GLM.n_GLMs = size(GLM.y,2);

%Number of observations
GLM.n_observations = size(GLM.y,1);

%Determine nuisance predictors not in contrast
GLM.ind_nuisance = find(~GLM.contrast);

if isfield(GLM,'exchange')
    %Set up exchange blocks
    GLM.blks=unique(GLM.exchange); 
    %Number of blocks
    GLM.n_blks=length(GLM.blks);
    %Number of observations per block
    GLM.sz_blk=GLM.n_observations/GLM.n_blks; 
    GLM.blk_ind=zeros(GLM.n_blks,GLM.sz_blk);
    for i=1:length(GLM.blks)
        GLM.blk_ind(i,:)=find(GLM.blks(i)==GLM.exchange);
    end
end

if isempty(GLM.ind_nuisance)
    %No nuisance predictors
else
    %Regress out nuisance predictors and compute residual
    GLM.b_nuisance=zeros(length(GLM.ind_nuisance),GLM.n_GLMs);
    GLM.resid_y=zeros(GLM.n_observations,GLM.n_GLMs); 
    GLM.b_nuisance=GLM.X(:,GLM.ind_nuisance)\GLM.y;
    GLM.resid_y=GLM.y-GLM.X(:,GLM.ind_nuisance)*GLM.b_nuisance; 
end



