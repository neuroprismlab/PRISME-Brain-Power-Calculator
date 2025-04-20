function [UI, RepParams] = setup_benchmarking(RepParams)
%% setup_benchmarking
% **Description**
% Prepares the configuration (`RepParams`) and user interface structure (`UI`) 
% necessary to run NBS-based benchmarking methods. This includes initializing 
% parameters, setting up the design matrix, configuring contrast vectors, and 
% assembling the required fields for NBS execution.
%
% **Inputs**
% - `RepParams` (struct): Experiment configuration containing:
%   * `test_type` – type of statistical test (`t`, `t2`, or `r`).
%   * `nbs_method`, `mask`, `nbs_dir`, `other_scripts_dir`, etc.
%   * `n_subs_subset`, `n_subs_subset_c1`, `n_subs_subset_c2`.
%   * `testing`, `ground_truth`, and test-specific settings.
%
% **Outputs**
% - `UI` (struct): Structure with fields used by the NBS toolbox:
%   * `contrast`, `perms`, `alpha`, `test`, `mask`, `edge_groups`, etc.
% - `RepParams` (struct): Updated structure with derived values and test setup.
%
% **Workflow**
% 1. Add NBS and script directories to the MATLAB path.
% 2. If in testing mode, override permutation and repetition parameters.
% 3. Build design matrix using `create_design_matrix`.
% 4. Create contrast vectors using `create_test_contrast`.
% 5. Set the number of observations and NBS test statistic based on test type.
% 6. Check if the method is permutation-based.
% 7. Assign benchmarking parameters to the `UI` structure.
%
%
% **Dependencies**
% - `create_design_matrix.m`
% - `create_test_contrast.m`
% - `check_if_permutation_method.m`
%
% **Notes**
% - This function standardizes all parameter setup for NBS and simulation.
% - Many UI fields directly reflect fields in `RepParams` for reproducibility.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025 

addpath(genpath(RepParams.nbs_dir));
addpath(genpath(RepParams.other_scripts_dir));

% Developers: parameter changes
if RepParams.testing
    RepParams.n_perms = RepParams.test_n_perms;
    % If gt always 1 rep
    if ~RepParams.ground_truth
        RepParams.n_repetitions = RepParams.test_n_repetitions;
    end
    RepParams.n_workers = RepParams.test_n_workers;
end

%% Create Design Matrix
RepParams.X_rep = create_design_matrix(RepParams.test_type, RepParams.n_subs_subset, ...
                                       'n_subs_1', RepParams.n_subs_subset_c1, ...
                                       'n_subs_2', RepParams.n_subs_subset_c2);


%% Set up constrast
[RepParams.nbs_contrast, RepParams.nbs_contrast_neg, RepParams.nbs_exchange] = ...
create_test_contrast(RepParams.test_type, RepParams.n_subs_subset);


%% Number of observations
switch RepParams.test_type

    case 't'
        RepParams.observations = RepParams.n_subs_subset;
        RepParams.nbs_test_stat = 'onesample';

    case 't2'
        RepParams.observations = RepParams.n_subs_subset_c1 + RepParams.n_subs_subset_c2;
        RepParams.nbs_test_stat = 'ttest';

    case 'r'
        RepParams.observations = RepParams.n_subs_subset;
        RepParams.nbs_test_stat = 'onesample';

    otherwise
        error('Test type not supported')

end

%% Check if there is a permutation_based method
RepParams.is_permutation_based = check_if_permutation_method(RepParams);

%% Assign params to structures
% Goal: should be able to run config file, load rep_params and UI from reference, and replicate reference results

% assign repetition parameters to rep_params
% Not needed anymore after modularization
%rep_params.data_dir=data_dir;
%rep_params.testing=testing;
%rep_params.do_simulated_effect=do_simulated_effect;
%rep_params.networks_with_effects=networks_with_effects;
%rep_params.mapping_category=mapping_category;
%rep_params.n_repetitions=n_repetitions;
%rep_params.n_subs_subset=n_subs_subset;
%rep_params.do_TPR=do_TPR;
%rep_params.use_both_tasks=use_both_tasks;
%rep_params.paired_design=paired_design;
%rep_params.task1=task1;
%if use_both_tasks; rep_params.task2=task2; end

% assign NBS parameters to UI (see NBS.m)
% UI.design.ui = dmat;
UI.contrast.ui = RepParams.nbs_contrast;
UI.test.ui = RepParams.nbs_test_stat; % alternatives are one-sample and F-test
UI.perms.ui = RepParams.n_perms;
UI.thresh.ui = RepParams.tthresh_first_level;
UI.alpha.ui = RepParams.pthresh_second_level;
% UI.statistic_type.ui = RepParams.cluster_stat_type;
UI.size.ui = RepParams.cluster_size_type;
% UI.omnibus_type.ui = RepParams.omnibus_type; 
UI.edge_groups.ui = RepParams.edge_groups;
UI.use_preaveraged_constrained.ui = RepParams.edge_groups;
UI.exchange.ui = RepParams.nbs_exchange;
UI.mask.ui = RepParams.mask;
% UI.do_Constrained_FWER_second_level.ui=do_Constrained_FWER_second_level;
UI.test_stat.ui = RepParams.test_type;

% Ground truth calculations do not require p-values
UI.ground_truth = RepParams.ground_truth;

%% Set up DIMS
UI.DIMS.nodes = RepParams.n_nodes;
UI.DIMS.observations = RepParams.observations;
UI.DIMS.predictors = size(RepParams.X_rep, 2);


end

