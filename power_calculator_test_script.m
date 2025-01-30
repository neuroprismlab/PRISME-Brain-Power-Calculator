%% Important
% Changed NBSrun_smn pvalue corrections scripts to <= for the test scripts
% MatLab mafdr is not working so well ... I had to modify it 



scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(scriptDir));
cd(scriptDir);

% Notes - issue with <= -

create_test_fc_data_set()
create_test_fc_atlas()

edge_based_tests('test_hcp_fc.mat')
% network_based_tests('test_hcp_fc.mat')


