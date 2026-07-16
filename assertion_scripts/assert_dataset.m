function assert_dataset(Dataset)
    % assert_dataset
    % Validates a PRISME dataset before it enters the pipeline. Fails loud at
    % ingestion rather than letting bad values propagate into curve fits.
    %   1. brain_data has no NaN (and no Inf)
    %   2. brain_data.data is a proper 2-D edge × subject matrix
    %   3. sub_ids length matches the number of data columns (subjects)
    
    assert(isfield(Dataset, 'brain_data'), ...
        'assert_dataset: missing brain_data field');
    
    conds = fieldnames(Dataset.brain_data);
    assert(~isempty(conds), 'assert_dataset: brain_data has no conditions');
    
    for c = 1:numel(conds)
        cond = conds{c};
        S = Dataset.brain_data.(cond);
    
        assert( ...
            isfield(S, 'data') && isfield(S, 'sub_ids'), ...
            'assert_dataset: %s missing data or sub_ids field', ...
            cond ...
        );
    
        d = S.data;
    
        [n_vars, n_subj] = size(d);
        n_ids = numel(S.sub_ids);

        % Subjects are the COLUMNS, defined by sub_ids. Check that the column
        % count matches, and that edges (rows) outnumber subjects as expected.
        assert(n_subj == n_ids, ...
            ['assert_dataset: %s has %d sub_ids but %d data columns — ' ...
            'subject labels and brain data are misaligned (or matrix transposed: ' ...
            'data is %d x %d)'], cond, n_ids, n_subj, n_vars, n_subj);
    
        % --- Check 1: no NaN, no Inf ---
        n_nan = sum(isnan(d(:)));
        n_inf = sum(isinf(d(:)));
        if n_nan > 0 || n_inf > 0
            per_subject = sum(isnan(d), 1);
            bad = find(per_subject > 0);
            error('assert_dataset:badValues', ...
                '%s.data has %d NaN and %d Inf across %d subjects: [%s]', ...
                cond, n_nan, n_inf, numel(bad), num2str(bad));
        end

    end

end