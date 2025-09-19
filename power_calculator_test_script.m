%% test_workflow
% Executes a full test suite to validate the statistical power calculator framework.
%
% This script runs unit and integration tests for multiple core components, 
% including edge-based and network-based inference, contrast-based test detection, 
% and ground-truth benchmarking validation. It ensures that test datasets are 
% correctly created, inference types are properly identified, and statistical 
% procedures return outputs in expected formats.
%
% Workflow
% - Create synthetic datasets for t-tests (one-sample, two-sample, and correlation).
% - Run statistical procedures:
%     - `edge_based_tests`: Executes edge-level statistical methods.
%     - `network_based_tests`: Executes network-level inference using an atlas.
% - Validate inference-type detection using contrast labels.
% - Verify integration between simulated ground truth and power estimation.
%
% Notes
% - This test suite is designed for local execution and development.
% - Omnibus test validation is not yet implemented 

clear;
clc;

%% Test hpc one sample t-tests 
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(scriptDir));
cd(scriptDir);

compile_mex()

cd(scriptDir);

clean_test_directories()

create_test_fc_data_set()
create_test_fc_atlas()

edge_based_tests('test_t2_fc.mat', 'file_structure', 'compact_file')

% Avoid errors where the same file already exists but is in a different
% format
clean_test_directories()

edge_based_tests('test_hcp_fc.mat')

network_based_tests('test_hcp_fc.mat')

%% Test inference type from data
data_inference_from_contrast_test()

%% Test power calculator
% I am going to depracate this power test 
% I need to rewrite it as a full pipeline 
% test_power_calculation_from_gt_and_data()

%% Create t2-test dataset 
create_t2_test_dataset()

edge_based_tests('test_t2_fc.mat')

network_based_tests('test_t2_fc.mat')

create_r_test_dataset()

edge_based_tests('test_r_fc.mat')

network_based_tests('test_r_fc.mat')


create_act_test_dataset()

edge_based_tests('test_act_act', 'stat_method_cell', {'Parametric', 'Size_Node_cpp', 'IC_TFCE_Node_cpp'}, ...
    'submethod_cell', {'FWER', 'FDR'}', ...
    'full_method_name_cell', {'Parametric_FWER', 'Parametric_FDR', 'Size_Node_cpp', 'IC_TFCE_Node_cpp'})


fprintf('Finished test routine correctly\n')










