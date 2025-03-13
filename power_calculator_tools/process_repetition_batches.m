function process_repetition_batches(RP, ids_sampled)
    

    batches_indexes = split_into_batches(RP.n_repetitions, RP.max_rep_pending);

    for i_bat = 1:numel(batches_indexes)
        batch = batches_indexes{i_bat};
        batch_size = numel(batches_indexes{i_bat});
        
        X_reps = cell(1, batch_size);
        Y_reps = cell(1, batch_size);

        for i_rep = 1:batch_size
            X_reps{i_rep} = 
        
        end


    

    end 
  


end

