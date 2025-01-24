function [brain_data_query, meta_data_query, stat_level] = power_calculator_query_constructor(base_query, meta_data)
    
    stat_level = set_statistic_level(meta_data.test_type);
    brain_data_query = [base_query, {stat_level}];
    meta_data_query = [base_query, {'meta_data'}];
    
end