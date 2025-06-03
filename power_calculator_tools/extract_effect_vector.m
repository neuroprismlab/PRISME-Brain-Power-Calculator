function [ids_pos_vec, ids_neg_vec, ids_zero_vec, pos_effect, neg_effect] ...
         = extract_effect_vector(stat_gt_level_str, gt_data, tpr_dthresh)
    
    % get indices of positive and negative ground truth dcoefficients
    ids_pos_vec=gt_data>tpr_dthresh;
    ids_neg_vec=gt_data<(-1*tpr_dthresh);
    ids_zero_vec= ~ids_pos_vec & ~ids_neg_vec;
    pos_effect = NaN;
    neg_effect = NaN;
    
    switch  stat_gt_level_str

        case 'edge'
            

        case 'network'
            

        case 'whole_brain'
            % the Cohen's d-coefficient threshold doesn't directly translate to this multivariate effect size - 
            % treating all nonzero as non-null
            pos_effect = any(gt_data > 0);
            neg_effect = any(gt_data < 0);
        
        otherwise
            error('In extract_effect_vector method not supported')
          
    end


end