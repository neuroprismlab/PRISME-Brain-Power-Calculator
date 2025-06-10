function color = method_color_assingment(method)

   switch method
       case 'Parametric_FWER'
           color = 'y';  % Yellow (edge)
       case 'Parametric_FDR'
           color = [1 0.5 0];  % Orange (edge fdr)
       case 'Size_cpp'
           color = [0 0.7 1];  % Light blue (cluster)
       case 'Size'
           color = [0 0.7 1];  % Light blue (cluster - same as cpp)
       case 'Fast_TFCE_cpp'
           color = [0 0.5 0.5];  % Dark teal (cluster rtce)
       case 'Fast_TFCE'
           color = [0 0.5 0.5];  % Dark teal (cluster rtce - same as cpp)
       case 'Constrained_cpp_FWER'
           color = [1 0.3 0.3];  % Red (network)
       case 'Constrained_FWER'
           color = [1 0.3 0.3];  % Red (network - same as cpp)
       case 'Constrained_cpp_FDR'
           color = [1 0.5 1];  % Pink/magenta (network fdr)
       case 'Constrained_FDR'
           color = [1 0.5 1];  % Pink/magenta (network fdr - same as cpp)
       case 'Omnibus_Multidimensional_cNBS'
           color = [0 0 0.7];  % Dark blue (whole brain)
       otherwise
           color = 'k';  % Black for unknown methods
   end
   
end