function color = custom_colors(color_name)

    switch color_name
        
        case 'sci_blu'

            n_colors = 256;
            
            % Define key color points
            deep_blue = [0.0196, 0.1882, 0.3804];
            light_blue = [0.2627, 0.5765, 0.8745];
            white = [0.9686, 0.9686, 0.9686];
            light_red = [0.9569, 0.6471, 0.5098];
            deep_red = [0.4039, 0.0000, 0.0510];
            
            % Create the colormap
            color = zeros(n_colors, 3);
            
            % Calculate segment sizes
            quarter = floor(n_colors / 4);
            
            % Segment 1: Deep blue to light blue
            for i = 1:quarter
                t = (i - 1) / (quarter - 1);
                color(i, :) = (1 - t) * deep_blue + t * light_blue;
            end
            
            % Segment 2: Light blue to white
            for i = quarter + 1:2 * quarter
                t = (i - quarter - 1) / (quarter - 1);
                color(i, :) = (1 - t) * light_blue + t * white;
            end
            
            % Segment 3: White to light red
            for i = 2 * quarter + 1:3 * quarter
                t = (i - 2 * quarter - 1) / (quarter - 1);
                color(i, :) = (1 - t) * white + t * light_red;
            end
            
            % Segment 4: Light red to deep red
            for i = 3 * quarter + 1:n_colors
                t = (i - 3 * quarter - 1) / (n_colors - 3 * quarter - 1);
                color(i, :) = (1 - t) * light_red + t * deep_red;
            end

        otherwise
            error('Color not supported')

    end 

end
