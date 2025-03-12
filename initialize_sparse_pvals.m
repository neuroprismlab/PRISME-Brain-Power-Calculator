function all_pvals = initialize_sparse_pvals(RP, UI)
    all_pvals = cell(1, length(RP.all_cluster_stat_types));  % Use a cell array

    for stat_id = 1:length(RP.all_cluster_stat_types)
        method_name = RP.all_cluster_stat_types{stat_id};
        method_instance = feval(method_name); % Instantiate method
        
        % Allocate correct sparse matrix size based on method level
        switch method_instance.level
            case "whole_brain"
                all_pvals{stat_id} = sparse(1, RP.n_repetitions);
            case "network"
                all_pvals{stat_id} = sparse(length(unique(UI.edge_groups.ui)) - 1, RP.n_repetitions);
            case "edge"
                all_pvals{stat_id} = sparse(RP.n_var, RP.n_repetitions);
            otherwise
                error("Unknown statistic level: %s", method_instance.level);
        end
    end
end
