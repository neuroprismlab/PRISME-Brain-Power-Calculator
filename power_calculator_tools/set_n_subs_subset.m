function RP  = set_n_subs_subset(RP)
    
    if ~RP.ground_truth

        switch RP.test_type
            
            case 't'
                RP.n_subs_subset_c1 = RP.n_subs_subset;
                RP.n_subs_subset_c2 = RP.n_subs_subset;
             
            case 't2'
                RP.n_subs_subset_c1 = floor(RP.n_subs_subset/2);
                RP.n_subs_subset_c2 = ceil(RP.n_subs_subset/2);
    
            case 'r'
                RP.n_subs_subset_c1 = RP.n_subs_subset;
                RP.n_subs_subset_c2 = RP.n_subs_subset;
    
            otherwise
                error('Test type not yet supported')
    
        end
        
    end

end
