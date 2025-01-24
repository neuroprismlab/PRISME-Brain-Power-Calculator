function RP = setup_parameters_for_rp(RP)
    
    % This is not gt
    RP.ground_truth = false;

    % Only for t2 test - divide rep subjects into two equal sets
    RP.n_subs_subset_c1 = floor(RP.n_subs_subset/2);
    RP.n_subs_subset_c2 = ceil(RP.n_subs_subset/2);

end