function check_stat_method_class_validity(Params)
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

    allowed_properties = {'level', 'permutation_based', 'submethod', 'permutations', 'method_params',
        'variable_type'};
    
    %% Check types
    for i = 1:numel(Params.all_cluster_stat_types)
        method_name = Params.all_cluster_stat_types{i};

        try
            method_obj = feval(method_name);
        catch
            error('Could not instantiate method class "%s". Check if it exists and is on the path.', method_name);
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
        
        disp(method_name)
        if any(strcmp({const_props.Name}, 'permutations')) && method_obj.permutations ~= Params.n_perms
            warning('Method %s has permutations defined and it will override setparams permutations', method_name)
        elseif any(strcmp({const_props.Name}, 'permutations')) && method_obj.permutations > Params.n_perms
            error('Method %s has more local permutations defined than can be prepared by setparams', method_name)
        end
    end


    
end