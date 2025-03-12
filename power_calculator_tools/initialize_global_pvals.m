function all_pvals = initialize_global_pvals(RP, UI, max_rep_pending)
    % Preallocate a cell array for each repetition
    all_pvals = cell(1, max_rep_pending);

    % Loop over repetitions
    for rep_idx = 1:max_rep_pending
        method_struct = struct();  % Preallocate struct to store sparse matrices

        % Loop over all statistical methods
        for stat_id = 1:length(RP.all_cluster_stat_types)
            method_name = RP.all_cluster_stat_types{stat_id};
            method_instance = feval(method_name); % Instantiate method
            
            % Allocate correct sparse matrix size based on method level
            switch method_instance.level
                case "whole_brain"
                    method_struct.(method_name) = zeros(1, RP.n_repetitions);
                case "network"
                    method_struct.(method_name) = zeros(length(unique(UI.edge_groups.ui)) - 1, RP.n_repetitions);
                case "edge"
                    method_struct.(method_name) = zeros(RP.n_var, RP.n_repetitions);
                otherwise
                    error("Unknown statistic level: %s", method_instance.level);
            end
        end
        % Assign preallocated struct to corresponding repetition cell
        all_pvals{rep_idx} = method_struct;
    end

end