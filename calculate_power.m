%% Workflow for Power Calculation
% This script performs the complete power calculation workflow by processing 
% repetition files one-by-one and computing power metrics against ground-truth data.
%
% The workflow proceeds as follows:
%   1. Initial Setup:
%      - Sets the working directory to the script location.
%      - Adds all subdirectories to the MATLAB path.
%      - Clears variables (except Study_Info) and clears the Command Window.
%
%   2. Parameter and Data Loading:
%      - Loads experiment parameters via setparams.
%      - Loads dataset information (Study_Info) from Params.data_dir if not already in the workspace.
%      - Determines the dataset name using get_data_set_name.
%
%   3. Repetition File Processing:
%      - Searches for repetition files in the designated output directory.
%      - Throws an error if no repetition files are found.
%
%   4. Output Directory Creation:
%      - Ensures that the power output directory exists by calling create_power_output_directory.
%
%   5. Iterative Processing:
%      - For each repetition file:
%          a. Loads the repetition data.
%          b. Extracts metadata and constructs the corresponding ground-truth (GT) filename.
%          c. Loads GT data (skips file if not found).
%          d. Extracts relevant brain data from the GT file using extract_gt_brain_data.
%          e. Computes power using summarize_tprs.
%          f. Clears repetition and GT data from memory.
%
% Dependencies:
%   - setparams
%   - get_data_set_name
%   - create_power_output_directory
%   - construct_gt_filename
%   - extract_gt_brain_data
%   - summarize_tprs
%
% Notes:
%   - This script is designed to minimize memory usage by processing repetition files sequentially.
%   - It requires that repetition and GT data files exist in the expected directories.

%% Initial setup
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(scriptDir));
cd(scriptDir);
clearvars -except Study_Info;
clc;

%% Directory to save and find rep data
Params = setparams();

% Load dataset information
if ~exist('Study_Info', 'var')
    Study_Info = load(Params.data_dir, 'study_info');
end
[Params.data_set, ~, ~] = get_data_set_name(Study_Info);

%% Process each repetition file one by one to reduce memory usage
rep_files = dir(fullfile(Params.save_directory, Params.data_set, '*.mat'));

% If no files were found output an error
if isempty(rep_files)
    error('No files found.')
end

%% Create output directory (only if it doesn't exist)
Params = create_power_output_directory(Params);

for i = 1:length(rep_files)
    % Load a single repetition data file
    rep_file_path = fullfile(rep_files(i).folder, rep_files(i).name);
    rep_data = load(rep_file_path);
    
    % Extract metadata to find corresponding GT file
    if isfield(rep_data, 'meta_data') && isfield(rep_data.meta_data, 'test_components')
        gt_filename = construct_gt_filename(rep_data.meta_data);
        gt_file_path = [Params.gt_data_dir, Params.data_set, '/', gt_filename];

        if exist(gt_file_path, 'file')
            gt_data = load(gt_file_path);
        else
            fprintf('GT file %s not found. Skipping...\n', gt_filename);
            continue;
        end
        
        stat_level = rep_data.meta_data.statistic_level;
        gt_data.brain_data = extract_gt_brain_data(gt_data, stat_level);

        % Compute power using the extracted repetition and GT data
        summarize_tprs('calculate_tpr', rep_data, gt_data, 'save_directory', Params.save_directory);
    else
        warning('Metadata missing in %s, skipping...', rep_files(i).name);
    end
    
    % Free memory before next iteration
    clear rep_data gt_data;
end