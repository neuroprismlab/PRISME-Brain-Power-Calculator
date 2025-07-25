function result_cell = plot_method_name_map(input_cell)
    
    result_cell = {};

    for i = 1:numel(input_cell)
        method = input_cell{i};

        switch method
            case 'Parametric_FDR'
                substitute = 'Parametric FDR';

            case 'Parametric_FWER'
                substitute = 'Parametric FWER';

            case 'Constrained_cpp_FDR'
                substitute = 'Network FDR';

            case 'Constrained_cpp_FWER'
                substitute = 'Network FWER';

            case 'Fast_TFCE_cpp'
                substitute = 'TFCE';

            case 'Size_cpp'
                substitute = 'Size';

            case 'Omnibus_Multidimensional_cNBS'
                substitute = 'Whole Brain';
            
            otherwise
                substitute = method;

        end
        fprintf('%s  -> %s\n', method, substitute);
        result_cell{end + 1} = substitute; %#ok

    end 
    
end