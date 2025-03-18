function max_tfce_val = perm_TFCE_comp(img, property_function)
% Optimized TFCE computation for permutations: Keeps only max TFCE value
% Uses a more efficient tracking method to avoid redundant computation.
% 
% Inputs:
%   - img: Edge-wise or voxel-wise test statistic matrix
%   - property_function: Function handle returning TFCE properties (H, E, dh)
%
% Output:
%   - max_tfce_val: Maximum TFCE value for the null distribution (scalar)

[H, E, dh] = property_function();     

% Set max threshold for empirical applications
img(img > 1000) = 100;

% Small perturbation to prevent numerical artifacts
img = img + (rand(size(img)) * 1e-15);
img(logical(eye(size(img)))) = 0; % Ensure diagonal is zero
threshs = 0:dh:max(img(:));
threshs = threshs(2:end);
ndh = length(threshs);

% Initialize tracking variables
n_elements = length(img(:));
vals = zeros(n_elements, 1);
max_tfce_val = 0; % Track only the max TFCE value

% Compute connected components dynamically
[comps, comp_sizes] = get_components2(bsxfun(@ge, img, threshs(1)), 1);

for h = 1:ndh
    % Update connected components by filtering previous ones
    if h > 1
        valid_mask = img >= threshs(h);
        comps = comps .* valid_mask; % Remove elements that fall below the threshold
    end

    % Compute cluster sizes dynamically
    clustsize = zeros(n_elements, 1);
    unique_clusters = unique(comps(comps > 0));
    
    for c = unique_clusters'
        cluster_elements = (comps == c);
        clustsize(cluster_elements) = sum(cluster_elements);
    end

    % Compute the TFCE transformation for this threshold
    curvals = (clustsize.^E) .* (threshs(h)^H);
    vals = vals + curvals;
    
    % Track the max TFCE value
    max_tfce_val = max(max_tfce_val, max(vals));
end
end