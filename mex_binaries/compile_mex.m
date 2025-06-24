function compile_mex()
% COMPILE_MEX Compile MEX files for Power_Calculator
%
% This function compiles all C++ files to MEX binaries
% and stores them in the mex_binaries directory
%
% Usage:
%   compile_mex()

% Define central binary directory
binary_dir = 'mex_binaries';


% Add binary directory to MATLAB path
if ~contains(path, [pwd filesep binary_dir])
    addpath([pwd filesep binary_dir]);
    fprintf('Added %s to MATLAB path\n', binary_dir);
    savepath;
end

% Define source files with relative paths from project root
source_files = {
    'statistical_methods/mex_scripts/apply_tfce_cpp.cpp', ...
    'statistical_methods/mex_scripts/constrained_pval_cpp.cpp', ...
    'statistical_methods/mex_scripts/size_pval_cpp.cpp', ...
    'statistical_methods/mex_scripts/sparse_size_pval_cpp.cpp', ...
    'statistical_methods/mex_scripts/sparse_tfce_cpp.cpp'
};

% Print header
fprintf('=================================================\n');
fprintf('  Power_Calculator MEX Compilation\n');
fprintf('  Platform: %s\n', computer('arch'));
fprintf('=================================================\n');

% Clean existing MEX files in binary directory
clean_binary_directory(binary_dir);

% Save current directory
current_dir = pwd;

% Change to the binary directory
cd(binary_dir);

% Compile each file
compilation_succeeded = true;
for i = 1:length(source_files)
    try
        % Get source path relative to project root
        source_path = fullfile('..', source_files{i});
        [~, base_name, ~] = fileparts(source_files{i});
        
        fprintf('Compiling %s -> %s...\n', source_files{i}, base_name);
        mex(source_path);
        
        fprintf('✓ Successfully compiled %s\n', base_name);
    catch ME
        fprintf('✗ Failed to compile %s: %s\n', source_files{i}, ME.message);
        compilation_succeeded = false;
    end
end

% Return to original directory
cd(current_dir);

% Report results
if compilation_succeeded
    fprintf('=================================================\n');
    fprintf('✓ All MEX files compiled successfully!\n');
    fprintf('Binary directory: %s\n', binary_dir);
    fprintf('=================================================\n');
else
    fprintf('=================================================\n');
    fprintf('✗ Some compilations failed. See details above.\n');
    fprintf('=================================================\n');
end

% List compiled files
list_binaries(binary_dir);

end

%% Helper function to clean binary directory
function clean_binary_directory(binary_dir)
    fprintf('Cleaning binary directory: %s\n', binary_dir);
    
    % Find all MEX files in the binary directory
    mex_files = dir(fullfile(binary_dir, '*.mex*'));
    
    if isempty(mex_files)
        fprintf('  No existing MEX files found.\n');
        return;
    end
    
    for j = 1:length(mex_files)
        file_path = fullfile(binary_dir, mex_files(j).name);
        fprintf('  Removing: %s\n', file_path);
        delete(file_path);
    end
end

%% Helper function to list compiled binaries
function list_binaries(binary_dir)
    fprintf('Compiled MEX binaries:\n');
    
    % Find all MEX files in the binary directory
    mex_files = dir(fullfile(binary_dir, '*.mex*'));
    
    if isempty(mex_files)
        fprintf('  No MEX files found.\n');
        return;
    end
    
    for j = 1:length(mex_files)
        fprintf('  %s\n', mex_files(j).name);
    end
end