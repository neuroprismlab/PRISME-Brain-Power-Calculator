function Params = setparams()
%% setparams
% User-defined parameters for running ground-truth and repetition calculations.
%
% This script sets the parameters for both the ground-truth (gt) workflow and the
% repetition calculation in the power calculator. Note that not all parameters are
% used by both processes; some parameters are specific to the ground-truth workflow,
% while others are specific to the repetition calculations. However, all are defined 
% in this single file.
%
% Usage:
%   Call setparams() at the beginning of your analysis to load all necessary 
%   parameters. For example:
%
%       Params = setparams();
%
%   The returned structure 'Params' contains settings for:
%     - Data and result directories (e.g., save_directory, data_dir, gt_data_dir)
%     - Ground-truth settings (e.g., gt_origin)
%     - NBS-related paths (nbs_dir, other_scripts_dir)
%     - Scan and resampling parameters (e.g., n_frames, use_trimmed_rest)
%     - Parallel processing options (parallel, n_workers)
%     - Repetition and batching settings (n_repetitions, batch_size, list_of_nsubset)
%     - Statistical test and threshold parameters (nbs_method, tthresh_first_level, pthresh_second_level,
%       all_cluster_stat_types, omnibus_type)
%     - Testing overrides for rapid development (testing, test_n_perms, test_n_repetitions, test_n_workers)
%
% Author: Fabricio Cravo | Date: March 2025

% Datasets - Commented for easy use
Params.data_dir = './data/s_abcd_fc_rosenblatt.mat';
% Params.data_dir = './data/s_hcp_fc_noble_tasks.mat';
% Params.data_dir = './data/s_hcp_act_noble_1.mat';

% Save specifications - if NaN output becomes dataset file name
Params.save_directory = './power_calculator_results/';
Params.gt_data_dir = './power_calculator_results/ground_truth/';

Params.output = 'test_new_file_structure';

% Options - full_file, compact_file;
Params.subsample_file_type = 'compact_file';

% Gt origin is currently deprecated
Params.gt_origin = 'power_calculator';

% If not NaN, it will use the atlas file found in this directory
Params.atlas_file = NaN;

% If recalculate is equal to 1 - recalculate
Params.recalculate = false;

% Directories
Params.nbs_dir = './NBS1.2';
Params.other_scripts_dir='./NBS_benchmarking/support_scripts/';

%%% Resampling parameters %%%
Params.parallel = false; % run stuff sequentially or in parallel
Params.n_workers = 10; % num parallel workers for parfor, best if # workers = # cores
Params.n_repetitions = 500;  % 500 recommended
Params.batch_size = 2;
 

%% Skip some tests - change ranges or the function
ranges = {[0, 0]};
Params.tests_to_skip = @(x) any(cellfun(@(r) (x >= r(1)) && (x <= r(2)), ranges));


%% List of subjects per subset
Params.list_of_nsubset = {20, 40, 80, 120, 200}; % To change this, add more when necessary
                    % size of subset is full group size (N=n*2 for two sample t-test or N=n for one-sample)

                            % Current model (see above design matrix) only designed for t-test
Params.force_permute = false;               
Params.n_perms = 1000;               % recommend n_perms=5000 to appreciably reduce uncertainty of p-value estimation (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Randomise/Theory)
Params.tthresh_first_level = 3.1;    % t=3.1 corresponds with p=0.005-0.001 (DOF=10-1000)
                            % Only used if cluster_stat_type='Size'
Params.pthresh_second_level = 0.05;  % FWER or FDR rate 
Params.tpr_dthresh = 0; % Threshold for true positives vs negatives
Params.save_significance_thresh = 0.15;
Params.all_cluster_stat_types = {'Parametric', 'Size_cpp', 'Fast_TFCE_cpp', 'Constrained_cpp', 'Omnibus'};

Params.all_submethods = {'FWER', 'FDR', 'Multidimensional_cNBS'};

Params.cluster_size_type = 'Extent'; % 'Intensity' | 'Extent'
                            % Only used if cluster_stat_type='Size'
% Params.all_omnibus_types = {'Multidimensional_cNBS'};
% Params.omnibus_type = 'Multidimensional_cNBS';
                 
%%%%% DEVELOPERS ONLY %%%%%
% Use a small subset of permutations for faster development -- inappropriate for inference

Params.testing = true;
Params.test_n_perms = 2;
Params.test_n_repetitions = 5;
Params.test_n_workers = 1;
Params.test_disable_save = false;

end
