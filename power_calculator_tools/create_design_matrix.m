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

            % Make sure the sum of n_subs_1 and n_subs_2 does not exceed n_subs
            if n_subs_1 + n_subs_2 > n_subs
                error('The sum of n_subs_1 and n_subs_2 cannot exceed n_subs');
            end

            X = zeros(n_subs, 2);
            X(1:n_subs_1, 1) = 1;
            X(n_subs_1:n_subs_1 + n_subs_2, 2) = 1;

        case 'pt'

            X = zeros(n_subs * 2, n_subs + 1);
            X(1:n_subs, 1) = 1;
            X(n_subs + 1:end, 1) = -1;
    
            for i=1:n_subs
                X(i,i+1)=1;
                X(n_subs + i, i + 1) = 1;
            end

        % case 'r'
            % can't define here - must wait to subsample data
            % X=brain;
            % y=score;
    end
        
end