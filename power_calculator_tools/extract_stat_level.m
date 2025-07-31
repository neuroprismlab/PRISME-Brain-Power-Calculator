function level = extract_stat_level(level)
    
    %% Extract variable level
    % Here there is no distrinction between nodes and averages - so we
    % return to fc data
    switch level

        case 'whole_brain'
            level = 'whole_brain';

        case 'network'
            level = 'network';
        
        case 'node'
            level = 'variable';

        case 'edge'
            level = 'variable';
        
        case 'variable'
            level = 'variable';

        otherwise
            error('Variable level not supported by extract_stat_level funciton')

    end


end