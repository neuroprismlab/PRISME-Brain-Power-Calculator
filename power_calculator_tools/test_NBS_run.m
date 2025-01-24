function NBS_Output = test_NBS_run(X, Y, Params)

    UI.method.ui = Params.nbs_method;
    UI.design.ui = X;
    UI.contrast.ui = [1, -1];
    UI.test.ui = Params.nbs_test_stat; % alternatives are one-sample and F-test
    UI.perms.ui = Params.n_perms;
    UI.thresh.ui = Params.tthresh_first_level;
    UI.alpha.ui = Params.pthresh_second_level;
    UI.statistic_type.ui = Params.cluster_stat_type; 
    UI.size.ui = Params.cluster_size_type;
    UI.omnibus_type.ui = Params.omnibus_type; 
    % UI.exchange.ui = nbs_exchange;
    UI.matrices.ui = Y;

    NBS_Output = NBSrun_smn(UI);
    
end