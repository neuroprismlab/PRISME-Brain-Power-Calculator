function batches = split_into_batches(max_rep_pending, max_batch_length)
% Splits repetitions into batches based on max batch number
%
% Inputs:
%   - max_rep_pending: Total number of repetitions
%   - max_batch_number: Maximum number of batches
%
% Output:
%   - batches: A cell array where each cell contains indices of repetitions in that batch

    % Compute batch size (ensure it's at least 1)
    
    batch_number = ceil(max_rep_pending/max_batch_length);

    % Initialize cell array for batches
    batches = cell(1, batch_number);

    % Fill the batches
    for batch_idx = 1:length(batches)
        start_idx = (batch_idx - 1) * max_batch_length + 1;
        end_idx = min(max_batch_length*batch_idx, max_rep_pending);
        batches{batch_idx} = num2cell(start_idx:end_idx);
    end


end