function map = map_method_plot_name()
    
    map = struct();

    % Map functions return maps that change names to display names
    method_to_display = containers.Map();
    method_to_display('Parametric_FWER') = 'edge';
    method_to_display('Parametric_FDR') = 'edge (fdr)';
    method_to_display('Size_cpp') = 'cluster';
    method_to_display('Size') = 'cluster';
    method_to_display('Fast_TFCE_cpp') = 'cluster tfce';
    method_to_display('Fast_TFCE') = 'cluster tfce';
    method_to_display('Constrained_cpp_FWER') = 'network';
    method_to_display('Constrained_FWER') = 'network';
    method_to_display('Constrained_cpp_FDR') = 'network (fdr)';
    method_to_display('Constrained_FDR') = 'networkm (fdr)';
    method_to_display('Omnibus_Multidimensional_cNBS') = 'whole brain';

    map.display = method_to_display;

     % Create mapping from internal method names to display order
    map_display_order = containers.Map();
    map_display_order('edge') = 1;
    map_display_order('edge (fdr)') = 2;
    map_display_order('cluster') = 3;
    map_display_order('cluster tfce') = 4;
    map_display_order('network') = 5;
    map_display_order('network (fdr)') = 6;
    map_display_order('whole brain') = 7;

    map.order = map_display_order;

end