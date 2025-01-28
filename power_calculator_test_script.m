
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(scriptDir));
cd(scriptDir);

create_test_fc_data_set()
create_test_fc_atlas()

% parametric_bonferroni_test('test_hpc_fc.mat')
constrained_test('test_hcp_fc.mat')

