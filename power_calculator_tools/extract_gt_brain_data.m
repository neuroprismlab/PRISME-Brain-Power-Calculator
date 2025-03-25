function brain_data = extract_gt_brain_data(gt_data, stat_level)
%% extract_gt_brain_data
% Extracts ground-truth brain data based on the specified statistic level.
% For 'edge', the function returns gt_data.brain_data.edge_stats_all.
% For 'network' and 'whole_brain', it returns gt_data.brain_data.cluster_stats_all.
% Throws an error if the provided stat_level is not supported.
%
% Inputs:
%   - gt_data: Struct containing ground-truth data, with a field 'brain_data'
%              that includes various output types.
%   - stat_level: String specifying the statistic level ('edge', 'network', or 'whole_brain').
%
% Outputs:
%   - brain_data: Extracted brain data corresponding to the specified statistic level.
%

    switch stat_level

        case 'edge'
            brain_data = gt_data.brain_data.edge_stats_all;
        
        case 'network'
            brain_data = gt_data.brain_data.cluster_stats_all;

        case 'whole_brain'
            brain_data = gt_data.brain_data.cluster_stats_all;
        
        otherwise
            error('Stat level type not supported')

    end


end
