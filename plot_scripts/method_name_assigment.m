function name = method_name_assigment(method)

    switch method
        case 'Parametric_FWER'
            name = 'edge';
        case 'Parametric_FDR'
            name = 'edge (FDR)';
        case 'Size_cpp'
            name = 'size';
        case 'Size'
            name = 'size';
        case 'Fast_TFCE_cpp'
            name = 'TFCE';
        case 'Fast_TFCE'
            name = 'TFCE';
        case 'Constrained_cpp_FWER'
            name = 'network';
        case 'Constrained_FWER'
            name = 'network';
        case 'Constrained_cpp_FDR'
            name = 'network (FDR)';
        case 'Constrained_FDR'
            name = 'network (FDR)';
        case 'Omnibus_Multidimensional_cNBS'
            name = 'whole-brain';
        otherwise
           color = 'k';  % Black for unknown methods
    end
   
end