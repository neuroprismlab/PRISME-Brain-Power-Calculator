function [sorted_array, sort_indices] = natural_sort(cell_array)
    % NATURAL_SORT - Sort cell array of strings considering numeric values
    % 
    % This function sorts strings naturally, taking into account numeric
    % values at the end of strings (e.g., 'test1', 'test2', 'test10')
    %
    % Inputs:
    %   cell_array - Cell array of character vectors to sort
    %
    % Outputs:
    %   sorted_array - Sorted cell array
    %   sort_indices - Indices showing original positions
    %
    % Examples:
    %   input = {'test1', 'test10', 'test2', 'test20', 'test3'};
    %   sorted = natural_sort(input);
    %   % Result: {'test1', 'test2', 'test3', 'test10', 'test20'}
    %
    %   input = {'file1.txt', 'file10.txt', 'file2.txt'};
    %   sorted = natural_sort(input);
    %   % Result: {'file1.txt', 'file2.txt', 'file10.txt'}
    
    if isempty(cell_array)
        sorted_array = cell_array;
        sort_indices = [];
        return;
    end
    
    % Initialize arrays to store parsed components
    n = length(cell_array);
    text_parts = cell(n, 1);
    numeric_parts = zeros(n, 1);
    has_number = false(n, 1);
    
    % Parse each string to separate text and numeric parts
    for i = 1:n
        str = cell_array{i};
        
        % Find the last sequence of digits in the string
        digit_matches = regexp(str, '\d+', 'match');
        digit_starts = regexp(str, '\d+', 'start');
        
        if ~isempty(digit_matches)
            % Take the last number found
            last_num_str = digit_matches{end};
            last_num_start = digit_starts(end);
            
            % Split into text and numeric parts
            text_parts{i} = str(1:last_num_start-1);
            numeric_parts(i) = str2double(last_num_str);
            has_number(i) = true;
        else
            % No number found, treat as pure text
            text_parts{i} = str;
            numeric_parts(i) = 0;
            has_number(i) = false;
        end
    end
    
    % Create sorting keys
    % First sort by text part, then by numeric part
    sort_keys = cell(n, 1);
    for i = 1:n
        if has_number(i)
            % For strings with numbers: [text_part, numeric_value]
            sort_keys{i} = {text_parts{i}, numeric_parts(i)};
        else
            % For strings without numbers: [text_part, -Inf] (so they come first)
            sort_keys{i} = {text_parts{i}, -Inf};
        end
    end
    
    % Create a matrix for sorting: [text_part_index, numeric_part]
    % First, get unique text parts and assign indices
    unique_texts = unique(text_parts);
    text_indices = zeros(n, 1);
    
    for i = 1:n
        text_indices(i) = find(strcmp(text_parts{i}, unique_texts));
    end
    
    % Create sort matrix: [text_index, numeric_value]
    sort_matrix = [text_indices, numeric_parts];
    
    % Sort by text index first, then by numeric value
    [~, sort_indices] = sortrows(sort_matrix);
    
    % Return sorted array
    sorted_array = cell_array(sort_indices);
end