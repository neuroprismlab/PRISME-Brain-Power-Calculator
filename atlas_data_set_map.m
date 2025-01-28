function atlas_file = atlas_data_set_map(Params)
    
    atlas_ok = ~isnan(Params.atlas_file);
    
    atlas_file = NaN;

    disp(Params.data_set)

    if atlas_ok
        atlas_file = Params.atlas_file;
    else

        switch Params.data_set

            case 'hcp_fc'

                atlas_file = './atlas_storage/map268_subnetwork.mat';
            
            case 'test_hcp_fc'

                atlas_file = './atlas_storage/test_hcp_fc_atlas.mat';

        end

    end
       
    %% Maybe we remove this? - Not everything requires an atlas
    if isnan(atlas_file)
        error('No atlas file found')
    end

end 
