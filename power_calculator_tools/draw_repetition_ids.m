function ids_sampled = draw_repetition_ids(RP, varargin)
%% draw_repetition_ids
% **Description**
% Generates random subject indices for each repetition of the experiment. 
% Sampling behavior depends on the test type (e.g., `pt`, `t2`) and ensures 
% the correct number of subjects are drawn from appropriate groups.
%
% **Inputs**
% - `RP` (struct): Configuration structure with fields:
%   * `n_subs` – total number of subjects.
%   * `n_subs_1` – number of group 1 subjects (for `t2`).
%   * `n_subs_subset` – number of subjects to sample per repetition.
%   * `n_repetitions` – number of repetitions.
%   * `test_type` – type of test ('t', 't2', 'pt', 'r', etc.).
%   * `ground_truth` – if true, all subject IDs are used.
%
% **Outputs**
% - `ids_sampled` (matrix): Subject indices for each repetition. Size is 
%   `[n_subs_subset (or 2×), n_repetitions]`, depending on the test type.
%
% **Workflow**
% 1. If `ground_truth` is enabled, return all subject indices.
% 2. Otherwise, for each repetition:
%    - For `pt`: draw subject IDs and duplicate them for paired contrast.
%    - For `t2`: draw IDs separately from both groups.
%    - For other test types: draw random IDs from the full set.
%
% **Notes**
% - For `pt`, sampled indices are doubled with an offset to represent both time points.
% - Sampling is random and without replacement (via `randperm`).
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025

    p = inputParser;
    p.addParameter('n_reps', 0);
    p.parse(varargin{:});
    n_reps = p.Results.n_reps;


    if RP.ground_truth
       ids_sampled(:, 1)= 1:RP.n_subs;
       return;
    end

    if n_reps == 0
        n_reps = RP.n_repetitions;
    end
    
    for r=1:n_reps
        
        switch RP.test_type
            
            case 'pt'
    
                ids = randperm(RP.n_subs, RP.n_subs_subset)';
                ids = [ids; ids + RP.n_subs]';
    
            case 't2'
                
                ids_1 = randperm(RP.n_subs_1, RP.n_subs_subset);
                ids_2 = randperm(RP.n_subs - RP.n_subs_1, RP.n_subs_subset) + RP.n_subs_1;
    
                ids = [ids_1, ids_2]';
    
            otherwise 
    
                ids=randperm(RP.n_subs, RP.n_subs_subset)';
    
        end
    
        ids_sampled(:,r)=ids;
    
    end 

end
               