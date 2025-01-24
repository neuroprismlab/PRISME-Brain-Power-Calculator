%% run_benchmarking
% for each study
    %% load data & set up dmat (X) and m (Y) (see below)
    % for each level of inference (edges/vox, nets, clusters, multivar)
        % set up reps: get permutations, preallocate (n_edges, n_networks; for clusters we return n_edges)
        % run repetitions (parallel)
            % NBS_run
        % aggregate the output

%% load data & set up dmat (X) and m (Y)
%   load sub-level data
%   extract variables & infer test type from sub-level data
%       see calculate_effex repo: infer_test_type
%   from test type, assign dmat and brain
%       see calculate_effex repo: see do_group_level lines 589-621
