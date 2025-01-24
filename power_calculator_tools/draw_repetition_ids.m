function ids_sampled = draw_repetition_ids(RP)

    if RP.ground_truth
       ids_sampled(:, 1)= 1:RP.n_subs;
       return;
    end
    
    for r=1:RP.n_repetitions
        
        switch RP.test_type
            
            case 'pt'
    
                ids = randperm(RP.n_subs, RP.n_subs_subset)';
                ids = [ids; ids + RP.n_subs];
    
            case 't2'
                
                ids_1 = randperm(RP.n_subs_1, floor(RP.n_subs_subset/2));
                ids_2 = randperm(RP.n_subs - RP.n_subs_1 + 1, ceil(RP.n_subs_subset/2)) + (RP.n_subs_1 - 1);
    
                ids = [ids_1; ids_2];
    
            otherwise 
    
                ids=randperm(RP.n_subs, RP.n_subs_subset)';
    
        end
    
        ids_sampled(:,r)=ids;
    
    end 

end
               