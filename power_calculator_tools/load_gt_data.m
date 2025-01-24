function GtData = load_gt_data(varargin)
    
    % Create an input parser
    p = inputParser;

    addParameter(p, 'directory', './power_calculator_results/ground_truth/', @ischar); % Default: 'default'
    addParameter(p, 'gt_origin', 'power_calculator');

    %% Get GT data files from directory 
    parse(p, varargin{:});
    gt_dir = p.Results.directory;
    gt_origin = p.Results.gt_origin;

    % Get a list of all .mat files in the directory
    gt_files = {dir(fullfile(gt_dir, '*.mat')).name};
    
    %% Define struct and store data
    GtData = struct;


    %% TODO - improve this 
    switch gt_origin

        case 'effect_size'

            for i_f = 1:length(gt_files)
                gt_file_name = gt_files{i_f};
                
                gt_absolute_file = [gt_dir, gt_file_name];
                % small gt data means a single file - struct is the combination
                gt_data = load(gt_absolute_file);
                gt_data = gt_data.results;
                meta_data = gt_data.study_info;
         
                query_cell = gt_query_cell_generator(meta_data);        
        
                GtData = setfield(GtData, query_cell{:}, gt_data);
            end

        case 'power_calculator'  

            for i_f = 1:length(gt_files)
                gt_file_name = gt_files{i_f}; % Get file
                gt_absolute_file = [gt_dir, gt_file_name]; % Absolute path

                data = load(gt_absolute_file); % Load
                
                gt_data = data.brain_data;
                meta_data = data.meta_data;
                % The meta data is overriden multi-times depending on the
                % experiment - it's not optimized, but it guarantess there
                % will always be one meta-data
                meta_data_reduced = transform_meta_data_in_gt(meta_data);
                
                % Initial part of the struct query
                base_query = gt_query_cell_generator(meta_data);

                % Construct the query according to stat level and extract
                % correct data
                [brain_data_query, meta_data_query, stat_level] = ...
                    power_calculator_query_constructor(base_query, meta_data); 
                gt_data = get_data_from_level(gt_data, stat_level);
              
                
                % Perform the queries
                GtData = setfield(GtData, meta_data_query{:}, meta_data_reduced);
                GtData = setfield(GtData, brain_data_query{:}, gt_data);
                
            end    
    
    end

end
