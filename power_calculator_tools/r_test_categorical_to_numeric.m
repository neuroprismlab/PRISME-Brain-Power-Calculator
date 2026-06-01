function numerical_scores = r_test_categorical_to_numeric(test_scores)


    switch class(test_scores)
    
        case 'double'
            numerical_scores = test_scores;

        case 'categorical'
            numerical_scores = map_cell_to_integers(cellstr(test_scores));
    
        case 'cell'   
            numerical_scores = map_cell_to_integers(test_scores);
    
        otherwise
            error('Unsupported score type "%s". Expected double or cell array of strings.', class(test_scores));
    
    end

end

function numerical_scores = map_cell_to_integers(test_scores)

    unique_scores = unique(test_scores);
    unique_scores = unique_scores(~cellfun(@(x) isnumeric(x) && isnan(x), unique_scores));
    unique_scores = sort(unique_scores);
    mapping_str = strjoin(arrayfun(@(i) sprintf('%s -> %d', unique_scores{i}, i), ...
        1:numel(unique_scores), 'UniformOutput', false), ',\n');
    warning('Categorical scores mapped to integers:\n %s. Verify this matching suits you.', mapping_str);

    numerical_scores = nan(size(test_scores));
    for i = 1:numel(unique_scores)
        numerical_scores(strcmp(test_scores, unique_scores{i})) = i;
    end

end