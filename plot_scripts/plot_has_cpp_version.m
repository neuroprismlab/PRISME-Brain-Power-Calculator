function has_cpp = plot_has_cpp_version(method, all_methods)
    % Insert _cpp before correction suffix if present
    if endsWith(method, '_FDR')
        base_method = extractBefore(method, '_FDR');
        cpp_version = [base_method '_cpp_FDR'];
    elseif endsWith(method, '_FWER')
        base_method = extractBefore(method, '_FWER');
        cpp_version = [base_method '_cpp_FWER'];
    else
        % No correction suffix, just add _cpp
        cpp_version = [method '_cpp'];
    end
    
    % Check if cpp version exists
    has_cpp = ismember(cpp_version, all_methods);
end