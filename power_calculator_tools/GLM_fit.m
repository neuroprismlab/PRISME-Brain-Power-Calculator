function edge_stats = GLM_fit(GLM, use_cpp)
    
    if ~use_cpp
        edge_stats = NBSglm_smn(GLM);
    else
        edge_stats = NBSglm_cpp(GLM);
    end

end