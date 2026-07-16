% clean_rosenblatt_nans.m
% Standalone script: loads s_slim_fc_rosenblatt.mat, removes any subject whose
% brain data contains a NaN (across all conditions under brain_data), removes the
% matching entries from sub_ids, sub_ids_motion, and motion, and saves the result
% as s_slim_fc_rosenblatt_fabi.mat in the same directory.

clear; clc;

in_file  = '/Users/f.cravogomes/Desktop/Cloned Repos/PRISME-Brain-Power-Calculator/data/s_slim_fc_rosenblatt.mat';
out_file = '/Users/f.cravogomes/Desktop/Cloned Repos/PRISME-Brain-Power-Calculator/data/s_slim_fc_rosenblatt_fabi.mat';

fprintf('Loading %s\n', in_file);
Dataset = load(in_file);
outcome = Dataset.outcome;
study_info = Dataset.study_info;

conds = fieldnames(Dataset.brain_data);

for c = 1:numel(conds)
    cond = conds{c};
    S = Dataset.brain_data.(cond);

    % data is edge × subject: a bad subject is any column containing a NaN
    good  = ~any(isnan(S.data), 1);        % 1 × n_subjects logical
    n_bad = sum(~good);

    if n_bad == 0
        fprintf('%s: no NaN subjects, unchanged (%d subjects)\n', cond, numel(good));
        continue;
    end

    % Subset every subject-aligned field by the SAME column selection
    S.data           = S.data(:, good);
    S.sub_ids        = S.sub_ids(good);
    S.sub_ids_motion = S.sub_ids_motion(good);
    S.motion         = S.motion(good);

    assert(~any(isnan(S.data(:))), '%s: NaN remaining after removal', cond);

    brain_data.(cond) = S;
end

% Save under the ORIGINAL variable name so downstream loaders still work.
fprintf('Saving %s\n', out_file);
save(out_file, 'brain_data', 'outcome', 'study_info', '-v7.3');

fprintf('Done.\n');