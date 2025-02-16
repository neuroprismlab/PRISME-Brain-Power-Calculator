function Params = setparams()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% User-defined parameters for running NBS with design matrix via command line
%
% Can define all numerical arguments as numeric or string types
% (Original NBS designed to parse string data)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% NBS toolbox
Params.save_directory = './power_calculator_results/';
% Params.data_dir = './data/s_abcd_fc_rosenblatt.mat';
Params.data_dir = './data/s_hcp_fc_noble_tasks.mat';
Params.gt_data_dir = './power_calculator_results/ground_truth/';

Params.gt_origin = 'power_calculator';

% If not NaN, it will use the atlas file found in this directory
Params.atlas_file = NaN;

% If recalculate is equal to 1 - recalculate
Params.recalculate = 0;

% Directories
Params.nbs_dir = './NBS1.2';
Params.other_scripts_dir='./NBS_benchmarking/support_scripts/';

%%% Trimmed Scans %%%
% Specify whether to use resting runs for task2 which have been trimmed to match each task's scan duration
% (in no. frames for single encoding direction; cf. https://protocols.humanconnectome.org/HCP/3T/imaging-protocols.html)
% Note: all scans were acquired with the same TR
Params.use_trimmed_rest = 0; % default = 0
Params.n_frames.EMOTION = 176;
Params.n_frames.GAMBLING = 253;
Params.n_frames.LANGUAGE = 316;
Params.n_frames.MOTOR = 284;
Params.n_frames.RELATIONAL = 232;
Params.n_frames.SOCIAL = 274;
Params.n_frames.WM = 405;
Params.n_frames.REST = 1200;
Params.n_frames.REST2 = 1200;

%%% Resampling parameters %%%
Params.n_workers = 5; % num parallel workers for parfor, best if # workers = # cores
Params.parallel = false; % run stuff sequentially or in parallel
Params.n_repetitions = 500;  % 500 recommended

%% List of subjects per subset
Params.list_of_nsubset = {20, 40, 80, 120, 200}; % To change this, add more when necessary
Params.list_of_nsubset = {20};
                    % size of subset is full group size (N=n*2 for two sample t-test or N=n for one-sample)

% NBS parameters
Params.nbs_method = 'Run NBS';       % 'Run NBS' (all procedures except edge-level) | 'Run Parametric Edge-Level Correction' | 'Run FDR' (nonparametric edge-level FDR correction)
% not needed anymore
% Params.nbs_test_stat = 't-test';     % 't-test' | 'one-sample' | 'F-test'
                            % Current model (see above design matrix) only designed for t-test
Params.n_perms = 1000;               % recommend n_perms=5000 to appreciably reduce uncertainty of p-value estimation (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Randomise/Theory)
Params.tthresh_first_level = 3.1;    % t=3.1 corresponds with p=0.005-0.001 (DOF=10-1000)
                            % Only used if cluster_stat_type='Size'
Params.pthresh_second_level = 0.05;  % FWER or FDR rate   
Params.all_cluster_stat_types = {'Parametric_Bonferroni', 'Parametric_FDR', 'Size', 'TFCE', ...
    'Constrained', 'Constrained_FWER', 'Omnibus'};

Params.cluster_size_type = 'Extent'; % 'Intensity' | 'Extent'
                            % Only used if cluster_stat_type='Size'
Params.all_omnibus_types = {'Multidimensional_cNBS'};
                 
%%%%% DEVELOPERS ONLY %%%%%
% Use a small subset of permutations for faster development -- inappropriate for inference

Params.testing = true;
Params.test_n_perms = '20';
Params.test_n_repetitions = 20;
Params.test_n_workers = 8;

end
