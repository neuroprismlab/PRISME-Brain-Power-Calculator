function [GtData, RepData] = load_rep_and_gt_results(Params, varargin)
    
    %% Input Parsing section
    p = inputParser;
        
    addOptional(p, 'gt_origin', 'power_calculator');
    addOptional(p, 'repetition_data', struct());
    addOptional(p, 'gt_data', struct());
    addOptional(p, 'dataset', NaN);
    
    parse(p, varargin{:});

    gt_origin = p.Results.gt_origin;
    RepData = p.Results.repetition_data;
    GtData = p.Results.gt_data;
    dataset = p.Results.dataset;
    
    if isnan(dataset)
        error('Dataset must be specified')
    end 

    %% Get rep data
    if isempty(fieldnames(RepData))
        RepData = unite_results_from_directory('directory', [Params.save_directory, dataset, '/']);
        if isempty(fieldnames(RepData))
            error('RepData was not load correctly')
        end
    end
    
    %% Get GT data
    if isempty(fieldnames(GtData))
        GtData = load_gt_data('directory', [Params.gt_data_dir, dataset, '/'], 'gt_origin', gt_origin);
        if isempty(fieldnames(GtData))
            error('GtData was not load correctly')
        end
    end

    %% Load gt data location in rep data
    RepData = l_dfs_add_gt_location(RepData, {}, RepData);
    
    %% TODO: Optimize this with dfs_struct 
    function RepData = l_dfs_add_gt_location(node, path_cell, RepData)
        fields = fieldnames(node);
        
        %% Loop over 
        for i = 1:numel(fields)
            field_name = fields{i};
            path_cell = [path_cell, {field_name}];
    
            %% Stopping condition?
            flag_meta = strcmp(field_name, 'meta_data');
            flag_brain = strcmp(field_name, 'brain_data');
            
            if ~flag_meta && ~flag_brain
                RepData = l_dfs_add_gt_location(node.(field_name), path_cell, RepData);
            elseif flag_meta
                RepData = add_gt_location_to_rep_data(path_cell, RepData, gt_origin);
            end
            path_cell = path_cell(1:end-1);

        end

    end

end


