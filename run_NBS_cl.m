function nbs = run_NBS_cl(X, Y, Params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Runs NBS from command line
% Directions:
% 1. fill out setparams
% 2. run this script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Developer parameter changes
if Params.testing 
    Params.n_perms=Params.test_n_perms;
end

% Move parameters into UI variable (comes from the NBS GUI)
% UI.DIMS.ui = 
UI.method.ui=Params.nbs_method;
UI.design.ui=X;
UI.contrast.ui=Params.contrast;
UI.test.ui=Params.nbs_test_stat;
UI.perms.ui=Params.n_perms;
UI.thresh.ui=Params.tthresh_first_level;
UI.alpha.ui=Params.pthresh_second_level;
UI.statistic_type.ui=Params.cluster_stat_type;
UI.size.ui=Params.cluster_size_type;
UI.edge_groups.ui=Params.edge_groups_file;
UI.exchange.ui=Params.exchange;
UI.matrices.ui=Y;
UI.use_preaveraged_constrained.ui=Params.use_preaveraged_constrained;

% Run command line NBS (TODO: maybe rename NBSrun_cl)
nbs=NBSrun_smn(UI);

return;

% Significant results
if ischar(Params.pthresh_second_level); pthresh_second_level=str2num(pthresh_second_level); end
sig_results=nbs.NBS.pval<pthresh_second_level;

% Map significant cNBS results to the edge level
% Note: Requires edge_groups_file to be a numerical matrix workspace 
% variable. cNBS results will be 1 x n subnetworks, where the first entry 
% corresponds to edges in edge group 1, second to edges in edge group 2, etc
if strcmp(cluster_stat_type,'Constrained')
    if exist('nbs','var')
        edge_groups=nbs.STATS.edge_groups.groups;
        sig_edge_results=edge_groups;
        it=1;
        for i=unique(nonzeros(edge_groups))'
            sig_edge_results(edge_groups==i)=sig_results(it);
            it=it+1;
        end
    end
    % simple visualization
    image(sig_edge_results*1000);
end


