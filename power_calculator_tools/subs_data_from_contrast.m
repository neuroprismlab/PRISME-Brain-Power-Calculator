function [X, Y, RP] = subs_data_from_contrast(RP, contrast, BrainData)
    

    switch numel(contrast) 

        case 1
            [X, Y, RP] = subs_data_contrast_1(RP, contrast, BrainData);
        
        case 2
            [X, Y, RP] = subs_data_contrast_2(RP, contrast, BrainData);

        otherwise
            error('Contrast length not compatible')

    end

    

end