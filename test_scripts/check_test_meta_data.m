function check_test_meta_data(meta_data, method)

    assert(meta_data.rep_parameters.n_repetitions == 20)

    assert(meta_data.rep_parameters.n_subs_subset_c1 == meta_data.rep_parameters.n_subs_subset_c2)
    assert(meta_data.rep_parameters.n_subs_subset_c1 == meta_data.rep_parameters.n_subs_subset)
    assert(meta_data.rep_parameters.n_subs_subset_c1 == 40)
    assert(strcmp(meta_data.rep_parameters.cluster_stat_type, method))

    switch meta_data.rep_parameters.test_type

        case 't'
            assert(strcmp(meta_data.rep_parameters.nbs_test_stat,'onesample'))
            assert(meta_data.rep_parameters.observations == 40)

        case 't2'
            assert(strcmp(meta_data.rep_parameters.nbs_test_stat,'ttest'))
            assert(meta_data.rep_parameters.observations == 80)

        case 'r' 
            assert(strcmp(meta_data.rep_parameters.nbs_test_stat,'onesample'))
            assert(meta_data.rep_parameters.observations == 40)
        
        otherwise
            error('A stored test type does not matched the covered test types')

    end

end

