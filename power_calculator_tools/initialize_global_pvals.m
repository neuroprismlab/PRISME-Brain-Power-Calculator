function initialize_global_pvals(RP, UI, num_pending)
    global all_pvals; % Use global variable for storage
    all_pvals = struct(); % Initialize struct

    for stat_id = 1:length(RP.all_cluster_stat_types)
        method_name = RP.all_cluster_stat_types{stat_id};
        method_instance = feval(method_name); % Instantiate method
        
        % Allocate correct matrix size based on method level
        switch method_instance.level
            case "whole_brain"
                all_pvals.(method_name) = zeros(1, num_pending);
            case "network"
                all_pvals.(method_name) = zeros(length(unique(UI.edge_groups.ui)) - 1, num_pending);
            case "edge"
                all_pvals.(method_name) = zeros(RP.n_var, num_pending);
            otherwise
                error("Unknown statistic level: %s", method_instance.level);
        end
    end
    
end