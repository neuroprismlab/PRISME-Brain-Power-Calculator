function Params = check_stat_method_class_validity(Params)
% check_stat_method_class_validity - Validates properties of statistical method classes.
%
% Checks that method classes in Params.all_cluster_stat_types:
%   - Include only known constant property names
%   - Define 'level' as a required constant property
%   - If defined, 'submethod' must be a cell array of strings
%
% Inputs:
%   - Params: struct with field 'all_cluster_stat_types'
%
% Notes:
%   - Does not return anything. Only throws errors
%
% Author: Fabricio Cravo
% Date: March 2025

    allowed_properties = {'level', 'permutation_based', 'submethod', 'permutations', 'method_params'};
    
    %% Check if methods match variable type and replace if needed
    new_cluster_stat_types = cell(1, numel(Params.all_cluster_stat_types));
    for i = 1:numel(Params.all_cluster_stat_types)
        method_name = Params.all_cluster_stat_types{i};

        try
            method_obj = feval(method_name);
        catch
            error('Could not instantiate method class "%s". Check if it exists and is on the path.', ...
                method_name);
        end

        try
            method_variable_type = method_obj.level;
        catch
            error('Unable to find statistical inference method %s level property', method_name)
        end

        if ~(strcmp(method_variable_type, 'edge') || strcmp(method_variable_type, 'node'))
            replaced_method =  method_name;
        else
            replaced_method = replace_edge_per_node_methods(method_name, ...
                                method_obj.level, Params.variable_type);
            warning('The method %s was replaced by %s for an appropriate variable type', ...
                    method_name, replaced_method)
        end

        new_cluster_stat_types{i} = replaced_method;

    end
    
    Params.all_cluster_stat_types = new_cluster_stat_types;

    %% Check types
    for i = 1:numel(Params.all_cluster_stat_types)
        method_name = Params.all_cluster_stat_types{i};

        try
            method_obj = feval(method_name);
        catch
            error('Could not instantiate method class "%s". Check if it exists and is on the path.', ...
                method_name);
        end

        meta = metaclass(method_obj);
        const_props = meta.PropertyList;

        % Required: level
        if ~any(strcmp({const_props.Name}, 'level'))
            error('Method "%s" is missing required constant property "level".', method_name);
        end

        % Optional: submethod must be a cell array of strings if present
        if any(strcmp({const_props.Name}, 'submethod'))
            val = method_obj.submethod;
            if ~(iscellstr(val) || isequal(val, {}))
                error('Method "%s": "submethod" must be a cell array of strings.', method_name);
            end
        end

        % Check for unexpected constant properties
        for p = const_props
            if ~ismember(char(p.Name), allowed_properties)
                error('Method "%s" defines unrecognized constant property "%s". Check for typos.', ...
                      method_name, p.Name);
            end
        end

        % Check if variable type matches
        disp(method_name)
        if any(strcmp({const_props.Name}, 'permutations')) && method_obj.permutations ~= Params.n_perms
            warning('Method %s has permutations defined and it will override setparams permutations', method_name)
        elseif any(strcmp({const_props.Name}, 'permutations')) && method_obj.permutations > Params.n_perms
            error('Method %s has more local permutations defined than can be prepared by setparams', method_name)
        end
    end


    
end