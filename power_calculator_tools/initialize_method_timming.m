function method_timing_all = initialize_method_timing(RP, max_rep_pending)
%% initialize_method_timing
% Preallocates a cell array to store method execution timing data for each repetition.
%
% Inputs:
% - RP: Configuration structure containing:
%   * all_full_stat_type_names: Array of full method names (method_submethod format)
% - max_rep_pending: The number of repetitions for which timing data needs to be preallocated.
%
% Outputs:
% - method_timing_all: A 1×max_rep_pending cell array. Each cell contains a structure
%   with fields corresponding to each method_submethod, where each field
%   contains a scalar value to store the execution time.
%
% Example:
% method_timing_all = initialize_method_timing(RP, max_rep_pending);
%
% Author: Based on code by Fabricio Cravo | Date: April 2025

    % Preallocate a cell array for each repetition
    method_timing_all = cell(1, max_rep_pending);
    
    % Loop over repetitions
    for rep_idx = 1:max_rep_pending
        method_struct = struct(); % Struct to store timing values
        
        % Loop over all full method names directly
        for i = 1:length(RP.all_full_stat_type_names)
            full_method_name = RP.all_full_stat_type_names{i};
            
            % Initialize timing field with zero
            method_struct.(full_method_name) = 0;
        end
        
        % Store per-repetition struct
        method_timing_all{rep_idx} = method_struct;
    end
end