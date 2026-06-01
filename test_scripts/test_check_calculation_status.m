function test_check_calculation_status()

    %% Setup shared RP base
    methods = {'Parametric_FWER', 'Parametric_FDR'};

    RP = struct();
    RP.save_directory       = './power_calculator_results/test_calc_stats/results/';
    RP.data_dir             = './data/TEST';
    RP.output               = 'test_calc_stats';
    RP.test_name            = 'ts';
    RP.test_type            = 't';
    RP.n_subs_subset        = 20;
    RP.n_subs               = 100;
    RP.testing              = 0;
    RP.ground_truth         = 0;
    RP.all_full_stat_type_names = methods;
    RP.subsample_file_type  = 'compact_file';
    RP.n_repetitions        = 50;
    RP.recalculate          = 0;
    RP.test_disable_save    = 1;

    %% Build the expected file path so we can write test data there
    [~, file_path] = create_and_check_rep_file(RP.save_directory, RP.output, RP.test_name, ...
        RP.test_type, RP.n_subs_subset, RP.testing, RP.ground_truth);

    if ~exist(RP.save_directory, 'dir')
        mkdir(RP.save_directory);
    end

    %% Test 1: File does not exist — should initialize everything to 0
    fprintf('Test 1: fresh start (no file)... \n');
    if isfile(file_path) 
        delete(file_path)
    end

    [existing_repetitions, ids_sampled, ~] = check_calculation_status(RP);

    assert(isstruct(existing_repetitions));
    for i = 1:length(methods)
        assert(existing_repetitions.(methods{i}) == 0, 'Expected 0 reps on fresh start');
    end
    assert(size(ids_sampled, 1) == RP.n_subs_subset, 'Wrong subject count in ids_sampled');
    fprintf('PASSED\n');

    %% Test 2: File exists with correct dataset and some repetitions
    fprintf('Test 2: file exists with partial repetitions... ');

    meta_data = struct();
    meta_data.repetition_ids = rand(RP.n_subs_subset, RP.n_repetitions);
    Parametric_FWER = struct('total_calculations', 30);
    Parametric_FDR  = struct('total_calculations', 15);
    save(file_path, 'meta_data', 'Parametric_FWER', 'Parametric_FDR');

    [existing_repetitions, ~, ~] = check_calculation_status(RP);

    assert(existing_repetitions.Parametric_FWER == 30);
    assert(existing_repetitions.Parametric_FDR == 15);
    fprintf('PASSED\n');

    %% Test 3: Dataset mismatch should error
    fprintf('Test 3: dataset mismatch... ');

    meta_data.data_dir = './data/wrong_dataset';
    save(file_path, 'meta_data');

    RP_mismatch = RP;
    RP_mismatch.mat_files = dir(fullfile(RP.save_directory, '*.mat'));

    try
        check_calculation_status(RP_mismatch);
        fprintf('FAILED (no error thrown)\n');
    catch ME
        assert(contains(ME.message, 'do not match'), 'Wrong error message');
        fprintf('PASSED\n');
    end

    %% Test 4: Subject count mismatch should error
    fprintf('Test 4: subject count mismatch... ');

    meta_data.data_dir = RP.data_dir;
    meta_data.repetition_ids = rand(99, RP.n_repetitions);  % wrong subject count
    save(file_path, 'meta_data');

    try
        check_calculation_status(RP);
        fprintf('FAILED (no error thrown)\n');
    catch ME
        fprintf('PASSED\n');
    end

    %% Test 5: recalculate flag resets everything to 0
    fprintf('Test 5: recalculate flag... ');

    meta_data.data_dir = RP.data_dir;
    meta_data.repetition_ids = rand(RP.n_subs_subset, RP.n_repetitions);
    meta_data.method_current_rep.Parametric_FWER = 50;
    meta_data.method_current_rep.Parametric_FDR  = 50;
    save(file_path, 'meta_data');

    RP_recalc = RP;
    RP_recalc.recalculate = 1;

    [existing_repetitions, ~, ~] = check_calculation_status(RP_recalc);
    for i = 1:length(methods)
        assert(existing_repetitions.(methods{i}) == 0, 'recalculate should reset to 0');
    end
    fprintf('PASSED\n');

    %% Cleanup
    if isfile(file_path)  
        delete(file_path);  
    end

    fprintf('\nAll tests passed.\n');

end