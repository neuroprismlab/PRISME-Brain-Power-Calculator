function [flat_to_spatial, spatial_to_flat] = create_spatial_flat_map(RP)

    switch RP.variable_type

        case 'node'
            % Create flat_to_spatial: cell array of coordinates
            active_linear_indices = find(RP.mask);
            matrix_size = size(RP.mask);  
            flat_to_spatial = cell(RP.n_var, 1);
            
            % Create 3D lookup array with flat indices at their positions
            spatial_lookup = zeros(matrix_size);
            
            for flat_idx = 1:RP.n_var
                spatial_linear_idx = active_linear_indices(flat_idx);
                coords = cell(1, length(matrix_size));
                [coords{:}] = ind2sub(matrix_size, spatial_linear_idx);
                flat_to_spatial{flat_idx} = coords;
                
                % Store flat_idx at its spatial position
                spatial_lookup(coords{:}) = flat_idx;
            end

            % Inverse to do flat to spatial
            spatial_to_flat = @(coords) spatial_lookup(coords{:});
            
        case 'edge'
            flat_to_spatial = NaN;
            spatial_to_flat = NaN;
            
        otherwise
            flat_to_spatial = NaN;
            spatial_to_flat = NaN;
    end

end

