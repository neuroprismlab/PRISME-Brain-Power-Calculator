function X_vs_X_vec = pre_compute_inverse_product(X_subs, RP)

    
    switch RP.test_type

        case {'t', 't2'}
            X_vs_X_vec = @(idx) RP.X_vs_X_vec;

        case 'r'
            % For 'r' case, just create an array of precomputed values
            num_subs = length(X_subs);
            precomputed_array = cell(num_subs, 1);
            
            for i = 1:num_subs
                precomputed_array{i} = (X_subs{i}' * X_subs{i}) \ X_subs{i}';
            end
            
            % Return a function that accesses the array
            X_vs_X_vec = @(idx) precomputed_array{idx};

    end

end



