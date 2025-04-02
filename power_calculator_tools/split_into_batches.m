function batches = split_into_batches(existing_repetitions, max_rep_pending, max_batch_length)
% Splits repetitions into batches based on max batch number
%
% Inputs:
%   - existing_repetitions: A struct of repetition counts per method.
%   - max_rep_pending: Total number of pending repetitions across methods.
%   - max_batch_length: Maximum number of repetitions per batch.
%
% Output:
%   - batches: A cell array where each cell contains indices of repetitions in that batch

     % Determine starting repetition index (next repetition to compute)
    start_rep = min(structfun(@(x) x + 1, existing_repetitions));

    % Calculate final index
    end_rep = start_rep + max_rep_pending - 1;
    
    % Get indexes to calculate
    all_indices = start_rep:end_rep;

    % Get the number of batches
    batch_number = ceil(max_rep_pending/max_batch_length);

    % Initialize cell array for batches
    batches = cell(1, batch_number);

    % Fill the batches
    for batch_idx = 1:length(batches)
        start_idx = (batch_idx - 1) * max_batch_length + 1;
        end_idx = min(max_batch_length*batch_idx, max_rep_pending);
        batches{batch_idx} = num2cell(all_indices(start_idx:end_idx));
    end


end