function meta_data = extract_relevant_meta_data_from_RP(RP, rep_ids)
%
% This function works as a filter, extracting the necessary fields from RP
% to create the meta-data for subsampling and power files
% First - level threashold should changed to be a Size parameter tbh 
% 

    % Repetitions and permutations
    meta_data.n_repetitions = RP.n_repetitions;
    meta_data.n_perms = RP.n_perms;
    
    % test type
    meta_data.test_type = RP.test_type;
    
    % Threasholds - t-stat for some methods
    % pvalue for significance
    % save for complete files
    meta_data.tthresh_first_level = RP.tthresh_first_level;
    meta_data.pval_thresh = RP.pthresh_second_level;
    meta_data.save_significance_thresh = RP.save_significance_thresh;
    
    % Methods related variables - studies were called tests in legacy
    meta_data.statistical_method_class_name = RP.all_cluster_stat_types;
    meta_data.all_submethods = RP.all_submethods;
    meta_data.method_list = RP.all_full_stat_type_names;
    
    % testing code
    meta_data.testing_code = RP.testing;
    
    % Dataset extraction + output 
    meta_data.data_dir = RP.data_dir;
    meta_data.dataset = RP.data_set_base;
    meta_data.map = RP.map;
    meta_data.output = RP.output;
    meta_data.study_name = RP.test_name;

    % Edge groups + mask
    meta_data.mask = RP.mask;
    meta_data.edge_groups = RP.edge_group;

    % File related 
    meta_data.atlas_file = RP.atlas_file;

    % Sub related data
    meta_data.all_sub_ids = RP.sub_ids;
    meta_data.sub_ids_task = RP.sub_ids_task;
    meta_data.sub_ids_rest = RP.sub_ids_rest;
    meta_data.n_subs_1 = RP.n_subs_1;
    meta_data.n_subs_2 = RP.n_subs_2;
    meta_data.n_subs = RP.n_subs;
    
    % Repetition Ids resulting from the draw
    meta_data.repetition_ids = rep_ids;
    
end