function atlas_file = atlas_data_set_map(Params)
    
    atlas_ok = ~isnan(Params.atlas_file);
    
    atlas_file = NaN;

    if atlas_ok
        atlas_file = Params.atlas_file;
    else

        switch Params.data_set

            case 'hcp_fc'

                atlas_file = './atlas_storage/map268_subnetwork.mat';
            
            case 'test_hpc_fc'

                atlas_file = './atlas_storade/test_hpc_fc_atlas.mat';

        end

    end

end 
