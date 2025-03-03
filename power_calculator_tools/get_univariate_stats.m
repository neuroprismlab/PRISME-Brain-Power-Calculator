function [test_stat]=get_univariate_stats(STATS,GLM,precomputed,idx)

    if precomputed
        %Precomputed test statistics
        test_stat=STATS.test_stat(idx,:); % TODO: here and next section - should not threshold if doing TFCE
    else
        %Compute test statistics on the fly
        test_stat=NBSglm_smn(GLM); % replaced glm so only does one perm, not the orig and then another
    end
    
end
