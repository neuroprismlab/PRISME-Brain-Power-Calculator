function latex_code = generate_latex_table_from_cell(cell_data, headers, varargin)
    % GENERATE_LATEX_TABLE_FROM_CELL Creates separate LaTeX tables for each test
    %
    % Inputs:
    %   cell_data - Cell array with headers in first row, data in subsequent rows
    %   'format_numbers' - Number of decimal places for numeric values (default: 2)
    %
    % Output:
    %   latex_code - String containing multiple LaTeX tables (one per test)
    %
    % Example:
    %   latex_code = generate_latex_table_from_cell(giant_cell, 'format_numbers', 2);
    
    %% Parse optional arguments

    p = inputParser;
    addParameter(p, 'format_numbers', 2, @isnumeric);
    addParameter(p, 'replace_methods', true);
    parse(p, varargin{:});
    
    decimal_places = p.Results.format_numbers;
    
    if size(cell_data, 2) ~= numel(headers)
        error('Header data must be provided with correct number of headers')
    end

    %% Extract data
    if size(cell_data, 1) < 2
        error('Cell array must have at least 2 rows (header + data)');
    end
    
    data = cell_data;
    
    %% Get unique test names from first column
    test_column = data(:, 1);
    unique_tests = unique(test_column, 'stable'); % Keep original order
        
    %% Generate one table for each unique test
    all_tables = {};
    for i = 1:length(unique_tests)
        test_name = unique_tests{i};
        
        % Find all rows for this specific test
        test_rows = strcmp(test_column, test_name);
        test_data = data(test_rows, :);
        
        % Generate complete LaTeX table for this test
        table_code = create_single_test_table(test_name, headers, test_data, decimal_places);
        all_tables{end+1} = table_code;
    end
    
    %% Combine all tables
    latex_code = strjoin(all_tables, [newline newline]);
    
    try
        clipboard('copy', latex_code);
        fprintf('LaTeX code copied to clipboard!\n');
    catch
        fprintf('Could not copy to clipboard, but code is displayed above.\n');
    end
end

function table_code = create_single_test_table(test_name, headers, test_data, decimal_places)
    % Create one complete LaTeX table for a single test
    latex_lines = {};
    
    % Table environment start
    latex_lines{end+1} = '\begin{table}[htbp]';
    latex_lines{end+1} = '    \centering';
    latex_lines{end+1} = sprintf('    \\caption{Power Analysis Results - %s}', clean_latex_string(test_name));
    latex_lines{end+1} = sprintf('    \\label{tab:power_%s}', strrep(test_name, 'test', ''));
    
    % Headers WITHOUT the first column (test name column)
    header_subset = headers(2:end);
    n_cols = length(header_subset);
    
    % Column alignment: first column (method) left, rest centered
    col_align = ['l', repmat('c', 1, n_cols-1)];
    latex_lines{end+1} = sprintf('    \\begin{tabular}{%s}', col_align);
    
    % Add table header
    latex_lines{end+1} = '        \toprule';
    header_line = ['        ', format_row_for_latex(header_subset, false, decimal_places)];
    latex_lines{end+1} = char(header_line);
    latex_lines{end+1} = '        \midrule';
    
    % Add data rows (exclude first column which is test name)
    for row = 1:size(test_data, 1)
        row_data = test_data(row, 2:end); % Skip first column (test name)
        data_line = ['        ', format_row_for_latex(row_data, true, decimal_places)];
        latex_lines{end+1} = char(data_line);
    end
    
    % Close table
    latex_lines{end+1} = '        \bottomrule';
    latex_lines{end+1} = '    \end{tabular}';
    latex_lines{end+1} = '\end{table}';
    
    table_code = strjoin(latex_lines, newline);
end

function formatted_row = format_row_for_latex(row_data, is_data_row, decimal_places)
    % Format a single row for LaTeX output
    formatted_cells = {};
    
    for i = 1:length(row_data)
        cell_value = row_data{i};
        
        if is_data_row && isnumeric(cell_value)
            % Format numeric data
            if isnan(cell_value)
                formatted_value = '--';
            elseif abs(cell_value) < 0.001 && cell_value ~= 0
                % More compact scientific notation
                exponent = floor(log10(abs(cell_value)));
                if abs(cell_value) < 1e-6
                    formatted_value = sprintf('$<10^{%d}$', exponent);
                else
                    coefficient = cell_value / (10^exponent);
                    formatted_value = sprintf('$%.1f \\cdot 10^{%d}$', coefficient, exponent);
                end
            else
                format_str = sprintf('%%.%df', decimal_places);
                formatted_value = sprintf(format_str, cell_value);
            end
        else
            % Format text (headers or method names)
            formatted_value = clean_latex_string(cell_value);
        end
        
        formatted_cells{i} = char(formatted_value);
    end
    
    formatted_row = [strjoin(formatted_cells, ' & '), ' \\'];
end

function clean_string = clean_latex_string(input_string)
    % Clean strings for LaTeX output
    if ischar(input_string) || isstring(input_string)
        clean_string = strrep(string(input_string), '_', '\_');
        clean_string = strrep(clean_string, 'Power\_subs\_', 'n=');
    else
        clean_string = string(input_string);
    end
end