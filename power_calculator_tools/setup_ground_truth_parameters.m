function RP = setup_ground_truth_parameters(RP)
    
    % Do it here might be a litle suboptimal - but I prefer for
    % organization}
    % Set types - one edge, one cluster, one brain
    RP.all_cluster_stat_types = {'Parametric_Bonferroni', 'Constrained', 'Omnibus'};

    % This is a ground_truth calculation - set flag to true
    RP.ground_truth = true; 
    
    % gt only has one repetition and the subset of subs is equal to all subs
    RP.n_repetitions = 1; 
    
    % Set subject numbers
    RP.list_of_nsubset = {RP.n_subs};

    RP.n_subs_subset_c1 = RP.n_subs_1;
    RP.n_subs_subset_c2 = RP.n_subs_2;

    
end
