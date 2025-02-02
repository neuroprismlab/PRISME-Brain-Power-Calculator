%% Important
% Changed NBSrun_smn pvalue corrections scripts to <= for the test scripts
% Notes - issue with <= / how much does it impact power?
% FWER can become an issue ....
% MatLab mafdr is not working so well ... I had to modify it 



scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(scriptDir));
cd(scriptDir);

create_test_fc_data_set()
create_test_fc_atlas()

% edge_based_tests('test_hcp_fc.mat')
% network_based_tests('test_hcp_fc.mat')

% Write tests for 
% infer_test_from_data
% subs_data_from_contrast



