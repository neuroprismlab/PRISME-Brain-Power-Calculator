%% Questions
    % There appears to be something wrong in the network level power
    % calculations - edge level and whole brain are fine
    % I likely made an error in the atlas 
    % Cluster has network-based stats not edge
    % Found it - Likely problem in edge groups!
    % 
    %% Potential fix - More resonable results!
    %   Used tril mask on extract_atlas_related_parameters for edge groups
    %   Removed atlas reordering in setupbenchmarking 
    %
    %% Potential issues
    % - nbs_method different than statistic_type - ?
    % - 'FDR' method and cluster type - what is it ?
    % - read_exchange - says optional - how?    
    % - Params.tthresh_first_level - nbs.STATS.thresh - not being corrected 
    % for number of subjects
    % - UI.size.ui - what is it?
    % - Talk about commits not counting - should this become a new
    % repository? 
    % - UI.edge_groups.ui=edge_groups and
    % - UI.use_preaveraged_constrained.ui=edge_groups are receiving the same
    % variable? why?
    % - Removed repeat - we always have to repeat, right?
    % - was_mask_flipped is not being used - is one when mask and edge groups 
    % are not in the same triangle 
    % - triu and tril in the edge group appear to make no difference in the 
    % final SSTATS.edge_groups
    % - In NBSstats_smm.m the variable ind_upper, a upper triangular matrix
    % is used to position the test statistics instead of the experiment
    % mask - maybe this is causing the mismatch? 
    % - case 3,4, null_stats is not really stat, in get_constrained_stats
    % in NBSstats_smn.m
    % - permute_signal(GLM); - for Size, TFCE, Constrained_FWER, Contrained,  
    % permutations are equivalent to original 
    % - On NBSedge_level_parametric_corr - t-test (for t2) assumes that the
    % number of subjects in both groups is equal 
    % - NBSedge_level_parametric_corr - did not have a onesample
    % implementation
    % - NBSglm_smn.m is using a simple average to calculate the t-test
    % statistics for the onesample case
    %
    % - What is SEA and why is it mentioned in the code?
    % - The same for 'Multidimensional_cNBS' 
    % - Line 377 of NBSrun_smn.m - strcmp(nbs.STATS.statistic_type,'SEA')
    % - Params.cluster_size_type - is it being used? 
    % - bgl value?
    % -  y_perm = GLM.y.*repmat(sign(rand(GLM.n_observations,1)-0.5),1,GLM.n_GLMs); 
    % - Cluster-based - giving out the double of the p-values
    % - NBSstats_smn - line 326 - switch case for size and tfce 
    % - Equal to issue above - perform_correction 
    %
    %% TODO
    % - shen atlas check 

% Set working directory to the directory of this script
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(scriptDir));
cd(scriptDir);

vars = who;       % Get a list of all variable names in the workspace
vars(strcmp(vars, 'data_matrix')) = [];  % Remove the variable you want to keep from the list
clear(vars{:});   % Clear all other variables
clc;

%% Prepare parameters and dataset
Params = setparams();

if ~exist('Dataset', 'var')
    Dataset = load(Params.data_dir);
end

%% Set n_nodes, n_var, n_repetitions 
Params = setup_experiment_data(Params, Dataset);
Params = create_output_directory(Params);
Params.data_set = get_data_set_name(Dataset);

%% Extract dataset name
[current_path,~,~] = fileparts(mfilename('fullpath')); % assuming NBS_benchmarking is current folder
addpath(genpath(current_path));

setup_parallel_workers(Params.parallel, Params.n_workers);

OutcomeData = Dataset.outcome;
BrainData = Dataset.brain_data;
    
tests = fieldnames(OutcomeData);

for ti = 1:length(tests)
    t = tests{ti};
    % Fix RP both tasks
    % RP - stands for Repetition Parameters
    RP = Params;
    
    %% FOR DEBUGING
    RP.all_cluster_stat_types = {'Size'};
    disp('Debugging still here')

    RP = infer_test_from_data(RP, OutcomeData.(t), BrainData);
    
    % bellow - gets: test name, subject data, subject numbers, subids, and number of subjects
    [~, Y , RP] = subs_data_from_contrast(RP, OutcomeData.(t).contrast, BrainData);
    
    [RP.triumask, RP.trilmask] = create_masks_from_nodes(size(RP.mask, 1));
    
    % Sets parameters which are different than gt
    %% TODO: THIS DOES NOT MAKE SENSE
    RP = setup_parameters_for_rp(RP);

    run_benchmarking(RP, Y)
    
    return;
    %if RP.testing == 1 && ti == 2
    %    return;
    %end
    
end


% NBS_Output = run_NBS_cl(X, Y, Params);



% run_benchmarking(Params);

% I only reviewed the non-ground truth stuff
% RepParams = setup_benchmarking(Params, false);


% Fix gt stuff now
% GtParams = setup_benchmarking(Params, true);



