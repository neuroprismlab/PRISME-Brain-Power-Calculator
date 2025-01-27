function map = load_atlas_mapping(atlas_file)

    atlas_data = load(sprintf(atlas_file)); % octave
    map = atlas_data.map;

end

