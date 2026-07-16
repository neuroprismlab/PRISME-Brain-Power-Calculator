function transpose_ukb_brain_data()
    origin = '/Users/f.cravogomes/Desktop/Cloned Repos/PRISME-Brain-Power-Calculator/data/s_ukb_fc_jiang.mat';
    dest   = '/Users/f.cravogomes/Desktop/Cloned Repos/PRISME-Brain-Power-Calculator/data/s_ukb_fc_fabricio.mat';
    
    S = load(origin);
    
    conds = fieldnames(S.brain_data);
    for c = 1:numel(conds)
        S.brain_data.(conds{c}).data = S.brain_data.(conds{c}).data.';
    end
    
    builtin('save', dest, '-struct', 'S', '-v7.3');

end