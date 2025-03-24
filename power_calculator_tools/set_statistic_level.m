function stat_level = set_statistic_level(method_instance_name)

    switch test_type
        
        case 'Parametric_Bonferroni'
            stat_level = 'edge';

        case 'Parametric_FDR'
            stat_level = 'edge';

        case 'Size'
            stat_level = 'edge';
  
        case 'TFCE'
            stat_level = 'edge';
            
        case 'Constrained'
            stat_level = 'network';

        case 'Constrained_FWER'
            stat_level = 'network';

        case 'Omnibus'
            stat_level = 'whole_brain';
         
        otherwise
            error('The statistical test type is not covered by this script')
            
    end

end