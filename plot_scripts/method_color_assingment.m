function color = method_color_assingment(method)

   switch method
       case 'edge'
           color = 'y';  % Yellow (edge)
       case 'edge (FDR)'
           color = [1 0.5 0];  % Orange (edge fdr)
       case 'size'
           color = [0 0.7 1];  % Light blue (cluster)
       case 'TFCE'
           color = [0 0.5 0.5];  % Dark teal (cluster rtce)
       case 'network'
           color = [1 0.3 0.3];  % Red (network)
       case 'network (FDR)'
           color = [1 0.5 1];  % Pink/magenta (network fdr)
       case 'whole-brain'
           color = [0 0 0.7];  % Dark blue (whole brain)
       otherwise
           error('Lacking color assingment')
   end
   
end