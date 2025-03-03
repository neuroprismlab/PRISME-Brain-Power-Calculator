function y_perm = permute_signal(GLM)
    % Permute variable
    %
    % SMN: all of these said "use the same permutation for every GLM" but I
    % don't think this is true... or I don't understand what they meant by this
    if strcmp(GLM.test,'onesample')
        do_sign_flip = 1;
    else
        do_sign_flip = 0;
    end

    if isempty(GLM.ind_nuisance) 
        %% Change here 
        %Permute signal 
        if ~do_sign_flip %% TODO: check blk_ind
            if exist('GLM.blk_ind','var')
                for j=1:GLM.n_blks
                    y_perm(GLM.blk_ind(j,:),:)= ...
                    GLM.y(GLM.blk_ind(j,randperm(GLM.sz_blk)),:);
                end
            else                
                y_perm = GLM.y(randperm(GLM.n_observations)',:);
            end
        else 
            y_perm = GLM.y.*repmat(sign(rand(GLM.n_observations,1)-0.5),1,GLM.n_GLMs);
        end
    else
        %Permute residuals
        % TODO: this returns altered GLM, not y_perm
        if exist('blk_ind','var')
            for j=1:GLM.n_blks
                GLM.resid_y(GLM.blk_ind(j,:),:)=...
                GLM.resid_y(GLM.blk_ind(j,randperm(GLM.sz_blk)),:);
            end
        else
            GLM.resid_y=GLM.resid_y(randperm(GLM.n_observations)',:);
        end
    
        %Add permuted residual back to nuisance signal, giving a realisation 
        %of the data under the null hypothesis (Freedma & Lane)
        
        if ~isempty(GLM.ind_nuisance)
            y_perm=GLM.resid_y+[GLM.X(:,GLM.ind_nuisance)]*GLM.b_nuisance;
        end
    
        %Flip signs
        %Don't permute first run % TODO: SMN - why is this here and not
        %elsewhere? also, shuffling already happened - whyis this
        %happening again here??
        if do_sign_flip
            y_perm=y_perm.*repmat(sign(rand(GLM.n_observations,1)-0.5),1,GLM.n_GLMs);
        end
    
    end
end