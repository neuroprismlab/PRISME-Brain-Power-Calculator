function cmap = redblue(n)
% REDBLUE Creates a red-white-blue diverging colormap
%   CMAP = REDBLUE(N) returns an N-by-3 matrix containing a diverging
%   colormap with red for negative values, white for zero, and blue for
%   positive values. If N is not specified, N = 256 is used.
%
%   Example:
%       colormap(redblue)
%       colormap(redblue(128))
%
%   This colormap is ideal for data that ranges from negative to positive
%   values, such as correlation matrices or functional connectivity.

    if nargin < 1
        n = 256;
    end
    
    if n < 2
        error('Colormap must have at least 2 colors');
    end
    
    % Create the colormap
    if mod(n,2) == 0
        % Even number of colors
        n_half = n/2;
        
        % Red to white (bottom half)
        red_to_white = [
            linspace(0.7, 1, n_half)' ...  % R: dark red to white
            linspace(0, 1, n_half)' ...    % G: dark red to white
            linspace(0, 1, n_half)'         % B: dark red to white
        ];
        
        % White to blue (top half)
        white_to_blue = [
            linspace(1, 0, n_half)' ...    % R: white to dark blue
            linspace(1, 0, n_half)' ...    % G: white to dark blue  
            linspace(1, 0.7, n_half)'      % B: white to dark blue
        ];
        
        cmap = [red_to_white; white_to_blue];
    else
        % Odd number of colors - ensure white is exactly in the middle
        n_half = floor(n/2);
        
        % Red to white (bottom half, not including white)
        red_to_white = [
            linspace(0.7, 1, n_half)' ...  % R
            linspace(0, 1, n_half)' ...    % G
            linspace(0, 1, n_half)'         % B
        ];
        
        % White (middle)
        white = [1 1 1];
        
        % White to blue (top half, not including white)
        white_to_blue = [
            linspace(1, 0, n_half)' ...    % R
            linspace(1, 0, n_half)' ...    % G
            linspace(1, 0.7, n_half)'      % B
        ];
        
        cmap = [red_to_white; white; white_to_blue];
    end
    
    % Ensure values are in [0,1] range
    cmap = max(0, min(1, cmap));
end

