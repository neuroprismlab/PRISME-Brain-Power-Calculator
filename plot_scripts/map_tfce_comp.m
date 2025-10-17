function map = map_tfce_comp()
    map = struct();
    
    % Map functions return maps that change names to display names
    method_to_display = containers.Map();
    method_to_display('IC_TFCE_FC_cpp_dh1') = 'IC-TFCE dh 0.01';
    method_to_display('IC_TFCE_FC_cpp_dh5') = 'IC-TFCE dh 0.05';
    method_to_display('IC_TFCE_FC_cpp_dh10') = 'IC-TFCE dh 0.1';
    method_to_display('IC_TFCE_FC_cpp_dh25') = 'IC-TFCE dh 0.25';
    map.display = method_to_display;
    
    % Color gradient for TFCE variants (green/teal gradient)
    color_map = containers.Map();
    color_map('IC-TFCE dh 0.01') = [0, 150, 136]/255;   % Dark teal
    color_map('IC-TFCE dh 0.05') = [76, 175, 80]/255;   % Green
    color_map('IC-TFCE dh 0.1') = [129, 199, 132]/255;  % Light green
    color_map('IC-TFCE dh 0.25') = [165, 214, 167]/255; % Lighter green
    map.color = color_map;

end