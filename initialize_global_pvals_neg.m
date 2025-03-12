function initialize_global_pvals_neg(RP, UI, num_pending_per_method)
    global all_pvals_neg; % Use global variable for storage
    all_pvals_neg = struct(); % Initialize struct

    for stat_id = 1:length(RP.all_cluster_stat_types)
        method_name = RP.all_cluster_stat_types{stat_id};
        method_instance = feval(method_name); % Instantiate method
        
        % Get the number of pending repetitions for this method
        num_pending = num_pending_per_method.(method_name);

        % Skip methods with no pending repetitions
        if num_pending == 0
            continue;
        end

        % Allocate correct matrix size based on method level
        switch method_instance.level
            case "whole_brain"
                all_pvals_neg.(method_name) = zeros(1, num_pending);
            case "network"
                all_pvals_neg.(method_name) = zeros(length(unique(UI.edge_groups.ui)) - 1, num_pending);
            case "edge"
                all_pvals_neg.(method_name) = zeros(RP.n_var, num_pending);
            otherwise
                error("Unknown statistic level: %s", method_instance.level);
        end
    end
end