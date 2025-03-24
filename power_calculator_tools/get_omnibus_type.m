function omnibus_type = get_omnibus_type(RP)
    %% Deprecated not used anymore

    if ~strcmp(RP.cluster_stat_type, 'Omnibus')
        omnibus_type = 'nobus';
    else
        omnibus_type = RP.omnibus_type;
    end
      
    
end