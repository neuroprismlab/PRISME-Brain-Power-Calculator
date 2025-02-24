function X = create_design_matrix(varargin)

    % Define a parser with default values
    p = inputParser;
    addRequired(p, 'test_type');
    addRequired(p, 'n_subs');
    addParameter(p, 'n_subs_1', -1); 
    addParameter(p, 'n_subs_2', -1); 

    
    % Parse the inputs
    parse(p, varargin{:});
    
    % Access parsed inputs
    test_type = p.Results.test_type;
    n_subs = p.Results.n_subs;
    n_subs_1 = p.Results.n_subs_1;
    n_subs_2 = p.Results.n_subs_2;


    switch test_type
        
        case 't'
            
            X = ones(n_subs, 1);
            
        case 't2' 
            
            if n_subs_1 == -1 || n_subs_2 == -1
                error('For a t2 desing matrix the number of subjects from both coditions must be supplied')
            end

            X = zeros(n_subs_1 + n_subs_2, 2);
            X(1:n_subs_1, 1) = 1;
            X(n_subs_1 + 1:end, 2) = 1;

            % Check if any row has both elements as 1 (invalid design)
            if any(sum(X, 2) > 1)
                error('Invalid design matrix: At least one row has both elements set to 1.');
            end

        case 'pt'

            X = zeros(n_subs * 2, n_subs + 1);
            X(1:n_subs, 1) = 1;
            X(n_subs + 1:end, 1) = -1;
    
            for i=1:n_subs
                X(i,i+1)=1;
                X(n_subs + i, i + 1) = 1;
            end

        case 'r'
            % Design matrix for r is obtained directly from the data 
            % So here we define it as NaN
            X = NaN; 
        
        otherwise

            error('Test type in create_design_matrix not supported')
        
    end
        
end