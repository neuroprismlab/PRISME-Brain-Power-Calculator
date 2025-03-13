function batches = split_into_batches(max_rep_pending, max_batch_number)
% Splits repetitions into batches based on max batch number
%
% Inputs:
%   - max_rep_pending: Total number of repetitions
%   - max_batch_number: Maximum number of batches
%
% Output:
%   - batches: A cell array where each cell contains indices of repetitions in that batch

    % Compute batch size (ensure it's at least 1)
    batch_size = ceil(max_rep_pending / max_batch_number);

    % Initialize cell array for batches
    batches = cell(1, ceil(max_rep_pending / batch_size));

    % Fill the batches
    for batch_idx = 1:length(batches)
        start_idx = (batch_idx - 1) * batch_size + 1;
        end_idx = min(batch_idx * batch_size, max_rep_pending);
        batches{batch_idx} = start_idx:end_idx;
    end
end