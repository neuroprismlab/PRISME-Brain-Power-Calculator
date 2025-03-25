function [all_stat_types, method_map] = extract_submethod_info(Params)
%% extract_submethod_info 
% Expand method classes into method_submethod combinations
% and map each full name to its original method name.
%
% Inputs:
%   - Params: Struct with fields:
%       - Params.all_cluster_stat_types: Cell array of method names (e.g., {'Parametric', 'Omnibus'})
%       - Params.all_submethods (optional): Submethods to include (e.g., {'FDR', 'FWER'})
%
% Outputs:
%   - all_stat_types: Cell array of strings like {'Parametric_FDR', 'Omnibus_XYZ'}
%   - method_map: containers.Map mapping full method names to base methods

    all_stat_types = {};
    method_map = containers.Map();

    if ~isfield(Params, 'all_submethods')
        Params.all_submethods = {};
    end

    for i = 1:numel(Params.all_cluster_stat_types)
        method = Params.all_cluster_stat_types{i};
        method_obj = feval(method);

        if isprop(method_obj, 'submethod')
            submethods = method_obj.submethod; % Default to compute all
        else
            submethods = {};  % No submethod — treat as default
        end

        if ~isempty(Params.all_submethods)
            submethods = submethods(ismember(submethods, Params.all_submethods));
        end
        
        if ~isempty(submethods)

            for j = 1:numel(submethods)
                sub = submethods{j};
                
                full_name = [method '_' sub];
    
                all_stat_types{end+1} = full_name; %#ok<AGROW>
                method_map(full_name) = method;
                
            end

        else

            full_name = method;
            all_stat_types{end+1} = full_name; %#ok<AGROW>
            method_map(full_name) = method;

        end

    end
    
    if isempty(all_stat_types)
        error('In extract_submethod_info - No valid method + submethod combinations were found.')
    end
    
end