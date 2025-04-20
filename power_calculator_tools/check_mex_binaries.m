function Params = check_mex_binaries(Params)
% CHECK_MEX_AVAILABILITY - Check if required MEX binaries are available
%
% This function checks if required MEX binaries are available and compatible
% with the current system. It updates Params.use_cpp accordingly and throws
% errors if incompatible configurations are detected.
%
% Syntax:
%   Params = check_mex_availability(Params)
%
% Input:
%   Params - Structure with at least these fields:
%       .use_cpp - Boolean flag indicating whether to use C++ optimizations
%       .all_cluster_stat_types - Cell array of all cluster stat types
%
% Output:
%   Params - Updated structure with possibly modified .use_cpp field
%
% Example:
%   Params.use_cpp = true;
%   Params.all_cluster_stat_types = {'Parametric', 'Size', 'Fast_TFCE'};
%   Params = check_mex_availability(Params);

cpp_based_methods = {'Fast_TFCE_cpp'};
cpp_required_stat_types = {};

% Check if any of the stat types require C++
for i = 1:length(Params.all_cluster_stat_types)
    stat_type = Params.all_cluster_stat_types{i};
    
    % Check if current stat_type is in cpp_based_methods
    if any(strcmpi(stat_type, cpp_based_methods))
        cpp_required_stat_types{end+1} = stat_type;
    end
end

% Check if we found any C++ required methods
has_cpp_methods = ~isempty(cpp_required_stat_types);
if ~has_cpp_methods
    return; % no need to continue
end
    

% Get current platform's MEX extension
current_mexext = mexext();

% List of required MEX files
required_mex_files = {'apply_tfce_cpp'};

% Check if each required MEX file exists and is compatible
all_exist = true;
all_compatible = true;
missing_files = {};
incompatible_files = {};

for i = 1:length(required_mex_files)
    % Check if file exists
    file_path = which(required_mex_files{i});
    
    if isempty(file_path)
        % File not found
        all_exist = false;
        missing_files{end+1} = required_mex_files{i};
    else
        % File exists, check compatibility
        [~, ~, file_ext] = fileparts(file_path);
        if ~strcmp(file_ext(2:end), current_mexext)
            % Extension doesn't match current platform
            all_compatible = false;
            incompatible_files{end+1} = required_mex_files{i};
        end
    end
end

% Check if MEX files are missing or incompatible
if ~all_exist || ~all_compatible
    % If any stat types require C++, throw an error
    if ~isempty(cpp_required_stat_types)
        error(['The following statistical methods require C++ optimizations,\n' ...
               'but required MEX files are missing or incompatible:\n' ...
               '- %s\n\n' ...
               'Missing or incompatible MEX files:\n%s\n\n' ...
               'Please compile the MEX files for your platform or remove these methods.'], ...
               strjoin(cpp_required_stat_types, '\n- '), ...
               strjoin(union(missing_files, incompatible_files), ', '));
    else
        % Just disable C++ optimizations
        fprintf('Required MEX files not available for this platform.\n');
        if ~all_exist
            fprintf('Missing files: %s\n', strjoin(missing_files, ', '));
        end
        if ~all_compatible
            fprintf('Incompatible files: %s\n', strjoin(incompatible_files, ', '));
        end
        fprintf('Disabling C++ optimizations and using MATLAB implementations.\n');
        Params.use_cpp = false;
    end
else
    fprintf('All required MEX files found and compatible. Using C++ optimizations.\n');
end

end