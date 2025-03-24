function all_pvals = initialize_global_pvals(RP, max_rep_pending)
%% initialize_global_pvals
% Preallocates a cell array to store p-value arrays for each repetition.
%
% Inputs:
%   - RP: Configuration structure containing:
%         * all_cluster_stat_types: Cell array of statistical method names.
%         * n_repetitions: Total number of repetitions.
%         * n_var: Number of variables (edges) for edge-level methods.
%         * edge_groups: Matrix or vector used to define network-level grouping.
%   - max_rep_pending: The number of repetitions for which p-values need to be preallocated.
%
% Outputs:
%   - all_pvals: A 1×max_rep_pending cell array. Each cell contains a structure
%                with fields corresponding to each (sub)method. For each submethod,
%                an array of zeros is preallocated with size depending on the method level:
%                  - "whole_brain": 1×n_repetitions vector.
%                  - "network": (number of unique networks – 1)×n_repetitions matrix.
%                  - "edge": n_var×n_repetitions matrix.
%
% Example:
%   all_pvals = initialize_global_pvals(RP, max_rep_pending);
%
% Author: Fabricio Cravo | Date: March 2025

    % Preallocate a cell array for each repetition
    all_pvals = cell(1, max_rep_pending);

    % Loop over repetitions
    for rep_idx = 1:max_rep_pending
        method_struct = struct();  % Struct to store preallocated arrays

        % Loop over all statistical methods
        for stat_id = 1:length(RP.all_cluster_stat_types)
            method_name = RP.all_cluster_stat_types{stat_id};
            method_instance = feval(method_name); % Instantiate class
            
            % Check submethods exist
            if isprop(method_instance, 'sub_method')
                submethods = method_instance.sub_method;
            else
                submethods = {method_name};  % fallback
            end

            % Preallocate for each submethod
            for i = 1:numel(submethods)
                submethod_name = submethods{i};
                full_method_name = [method_name '_' submethod_name];

                switch method_instance.level
                    case "whole_brain"
                        method_struct.(full_method_name) = zeros(1, RP.n_repetitions);
                    case "network"
                        method_struct.(full_method_name) = zeros(length(unique(RP.edge_groups)) - 1, RP.n_repetitions);
                    case "edge"
                        method_struct.(full_method_name) = zeros(RP.n_var, RP.n_repetitions);
                    otherwise
                        error("Unknown statistic level: %s", method_instance.level);
                end
            end
        end

        % Store per-repetition struct
        all_pvals{rep_idx} = method_struct;
    end
end