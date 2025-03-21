function test_score_set = get_test_score_set(TestData)
%% get_test_score_set
% **Description**
% Extracts the set of unique scores from `TestData.score`, removing empty 
% entries or NaNs. Ensures the result is always returned as a cell array.
%
% **Inputs**
% - `TestData` (struct): Contains a `score` field, which can be either a numeric 
%   array or a cell array of strings.
%
% **Outputs**
% - `test_score_set` (cell): Unique, non-empty, non-NaN values from `TestData.score`.
%
% **Workflow**
% 1. If `TestData.score` is a cell:
%    - Use `unique` to extract unique values.
%    - Remove empty entries.
% 2. If numeric:
%    - Remove NaNs.
%    - Convert to cell array for uniform output format.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025

    if iscell(TestData.score)
        test_score_set = unique(TestData.score); 
        test_score_set(cellfun('isempty', test_score_set)) = []; % Remove empty cells
    else
        test_score_set = unique(TestData.score);
        test_score_set(isnan(test_score_set)) = []; % Remove NaNs from numeric data
        test_score_set = num2cell(test_score_set); % Convert numeric to cell for uniformity
    end

end
