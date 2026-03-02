function subset_cell = cap_t2_test_subs_when_data_limited(RP)

    subset_cell = {};
    for i = 1:numel(RP.list_of_nsubset)
        n = RP.list_of_nsubset{i};

        if n >= RP.n_subs_1 || n >= (RP.n_subs - RP.n_subs_1)
            fprintf(['Subset size %d exceeds minority group (%d vs %d). ' ...
                'Removing from analysis.\n'], ...
                n, RP.n_subs_1, RP.n_subs - RP.n_subs_1);
        else
            subset_cell{end+1} = n;
        end
    end

end