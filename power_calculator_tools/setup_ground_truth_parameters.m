function RP = setup_ground_truth_parameters(RP)
%% setup_ground_truth_parameters
% Configures a repetition parameter structure for ground-truth power calculations.
%
% This function modifies a given RP (Repetition Parameters) structure to match the settings
% required for running a ground-truth evaluation. It disables multiple repetitions and assigns
% all subjects to the same repetition, using a single method ('Ground_Truth').
%
% Inputs:
%   - RP: Structure containing fields required to define a benchmarking run.
%
% Outputs:
%   - RP: Updated structure with fields configured for ground-truth estimation.
%
% Changes made to RP:
%   - Sets method type to 'Ground_Truth' for all statistic levels.
%   - Sets the number of repetitions to 1.
%   - Sets the subset size to include all subjects.
%   - Populates helper fields used downstream: `all_cluster_stat_types`, 
%     `all_full_stat_type_names`, and `full_name_method_map`.
%
    
    % Do it here might be a litle suboptimal - but I prefer for
    % organization}
    % Set types - one edge, one cluster, one brain
    RP.all_cluster_stat_types = {'Ground_Truth'};
    RP.all_full_stat_type_names = {'Ground_Truth'};
    RP.full_name_method_map = containers.Map({'Ground_Truth'}, {'Ground_Truth'});

    % This is a ground_truth calculation - set flag to true
    RP.ground_truth = true; 
    
    % gt only has one repetition and the subset of subs is equal to all subs
    RP.n_repetitions = 1; 
    
    % Set subject numbers
    RP.list_of_nsubset = {RP.n_subs};

    RP.n_subs_subset_c1 = RP.n_subs_1;
    RP.n_subs_subset_c2 = RP.n_subs_2;
 
end

