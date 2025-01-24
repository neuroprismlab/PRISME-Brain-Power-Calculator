function MetaData = add_meta_data_to_repetition_data(varargin)
    
    MetaData = struct;

    % Create an input parser
    p = inputParser;
    
    % Default is NaN for all non required
    addParameter(p, 'dataset', NaN, @ischar); 
    addParameter(p, 'rep_parameters', NaN, @isstruct)
    addParameter(p, 'map', NaN, @ischar); 
    addParameter(p, 'test', NaN, @ischar); 
    addParameter(p, 'test_type', NaN, @ischar);
    addParameter(p, 'omnibus', NaN, @(x) ischar(x) || isnan(x));
    addParameter(p, 'test_components', NaN, @iscell); 
    addParameter(p, 'subject_number', NaN, @isnumeric);
    addParameter(p, 'date', NaN);
    addParameter(p, 'run_time', NaN, @isnumeric);
    addParameter(p, 'testing_code', true, @islogical);
    
    % Parse the inputs
    parse(p, varargin{:});   

    MetaData.dataset = p.Results.dataset;
    MetaData.rep_parameters = p.Results.rep_parameters;
    MetaData.map = p.Results.map;
    MetaData.test = p.Results.test;
    MetaData.test_type = p.Results.test_type;
    MetaData.omnibus =  p.Results.omnibus;
    MetaData.test_components = p.Results.test_components;
    MetaData.subject_number =  p.Results.subject_number;
    MetaData.date = p.Results.date;
    MetaData.testing_code = p.Results.testing_code;
    
end

