function positives = get_significance_vector(is_fp, ids_pos_vec, ids_neg_vec, PowerRes, ...
        gt_size, stat_gt_level_str, pos_effect, neg_effect)
    %%
    % Calculates the absolute number of positives for both the tpr
    % calculation and fpr
    %
    % is_fpr - bool - if we are calculating the fpr we require negation
    % ids_pos_vec - bool array - varaibles with positive effect according to gt
    % ids_neg_vec - bool array - variables with negative effect acordin to gt
    % PowerRes - struct - current struct that stores the values (for gt accumulation)
    % gt_size - array - size of gt variable
    % stat_gt_level_str - level of statistics used
    % pos_effect - for whole-brain only, if there is a pos_effect
    % neg_effect - whole-brain only, if there is also a negative effect
    
    if is_fp
        ids_pos = ~ids_pos_vec;
        ids_neg = ~ids_neg_vec;
    else
        ids_pos = ids_pos_vec;
        ids_neg = ids_neg_vec;
    end

    % calculate TPR
    positives = nan(gt_size);
    if contains(stat_gt_level_str, 'variable')

        positives(ids_pos)=PowerRes.positives_total(ids_pos);
        positives(ids_neg)=PowerRes.positives_total_neg(ids_neg);

    elseif contains(stat_gt_level_str,'network')

        positives(ids_pos)=PowerRes.positives_total(ids_pos);
        positives(ids_neg)=PowerRes.positives_total_neg(ids_neg);

    elseif contains(stat_gt_level_str,'whole_brain')
        
        % If pos_effect - return all positives
        % If non positive effect - all are false positives
        positives = PowerRes.positives_total * xor(pos_effect, is_fp);
           
    end

end