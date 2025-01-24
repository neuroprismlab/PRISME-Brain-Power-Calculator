function BrainData = add_brain_data_to_repetition_data(varargin)
    
    BrainData = struct;

    % 'edge_stats_all','cluster_stats_all','pvals_all', ...
    % 'FWER','edge_stats_all_neg','cluster_stats_all_neg', ...
    % 'pvals_all_neg','FWER_neg', 

    % Create an input parser
    p = inputParser;
    
    % Default is NaN for all non required
    addParameter(p, 'edge_stats_all', NaN); 
    addParameter(p, 'edge_stats_all_neg', NaN); 
    addParameter(p, 'pvals_all', NaN); 
    addParameter(p, 'pvals_all_neg', NaN); 
    addParameter(p, 'cluster_stats_all', NaN); 
    addParameter(p, 'cluster_stats_all_neg', NaN);
    addParameter(p, 'FWER', NaN);
    addParameter(p, 'FWER_neg', NaN);

    % Parse the inputs
    parse(p, varargin{:}); 

    BrainData.edge_stats_all = p.Results.edge_stats_all;
    BrainData.edge_stats_all_neg = p.Results.edge_stats_all_neg;
    BrainData.pvals_all = p.Results.pvals_all;
    BrainData.pvals_all_neg = p.Results.pvals_all_neg;
    BrainData.cluster_stats_all = p.Results.cluster_stats_all;
    BrainData.cluster_stats_all_neg = p.Results.cluster_stats_all_neg; 
    BrainData.FWER = p.Results.FWER;
    BrainData.FWER_neg = p.Results.FWER_neg; 

end