function tfced = apply_tfce_node(img, varargin)
% Optimized TFCE function for connectivity-based analysis.
%
% Reduces redundant computations by:
%   1. Skipping individual nodes that are already isolated.
%   2. Tracking clusters across thresholds instead of recomputing from scratch.
%
% Usage:
%   [tfced, comps, comp_sizes] = matlab_tfce_transform(img, 'matrix' or 'image')
%
% Reference:
%   - Smith & Nichols (2009), TFCE in neuroimaging.

    %% **Set Parameters**
    dh = 0.1; % Threshold step size
    H = 3.0;
    E = 0.4;
       
    %% **Preprocessing**
    img(img > 1000) = 100; % Thresholding to avoid extreme values
    perturbation = rand(size(img)) * 1e-15; % Generate perturbation
    img = img + tril(perturbation, -1) + tril(perturbation, -1)'; % Make symmetric
    img(logical(eye(size(img)))) = 0; % Set diagonal to zero (for graphs)
    
    %% **Define Thresholds for Integration**
    threshs = 0:dh:max(img(:));
    threshs = threshs(2:end);
    ndh = length(threshs);
    
    %% **Define Node Adjacency**
    global adj_matrix
    l_create_sparse_adjacency(img, threshs(1));
    node_number = size(adj_matrix, 1);  % Get the correct number of nodes
    
    single_node = false(node_number, 1);
    cluster_size_per_node = ones(node_number, 1);
    
    % **Initialize TFCE accumulation variable**
    tfce_vals = zeros(node_number, 1);  
    
    %% **Iterate Over Thresholds and Compute Cluster Sizes**
    for h = 1:ndh
        th = threshs(h);
        
        % Update adjacency matrix by removing weak edges
        l_update_sparse_adjacency(th)
    
        % Convert sparse matrix to MATLAB graph object
        G = graph(adj_matrix);
        
        % Track explored nodes
        explored = false(node_number, 1);
    
        % **Reduce Loop Size by Filtering Active Nodes**
        active_nodes = find(~single_node & ~explored);  % Only process non-isolated nodes
    
        for i = 1:numel(active_nodes)
            i_node = active_nodes(i);
    
            if explored(i_node)
                continue
            end
    
            % Find connected component from this node
            connected_components = bfsearch(G, i_node);
    
            % Mark single nodes
            if numel(connected_components) == 1
                single_node(i_node) = true;
            end
    
            % Store cluster sizes
            cluster_size_per_node(connected_components) = numel(connected_components);
            explored(connected_components) = true;
        end
    
        % **TFCE Integration Step (Sum Over Thresholds)**
        tfce_vals = tfce_vals + (cluster_size_per_node .^ E) .* (th ^ H) * dh;
    end
    
    %% **Final Output**
    tfced = tfce_vals;  % The final TFCE-transformed data

end

function l_create_sparse_adjacency(img, initial_thresh)
    % Converts `img` into a sparse adjacency matrix, pruning edges below `initial_thresh`.
    % Stores the result in a global variable `adj_matrix`.
    %
    % INPUT:
    %   img - NxN similarity/connectivity matrix
    %   initial_thresh - Initial threshold to prune weak connections
    %
    % OUTPUT:
    %   None (stores result in global `adj_matrix`)

    global adj_matrix;

    % Create a logical mask of edges above the threshold
    valid_edges = img > initial_thresh;

    % Convert to a sparse adjacency matrix
    adj_matrix = sparse(valid_edges .* img);  % Retain edge weights, set others to 0
end


function l_update_sparse_adjacency(thresh)
    % Updates the global sparse adjacency matrix `adj_matrix` by removing edges below the new threshold.
    % 
    % INPUT:
    %   thresh - The new threshold value to apply
    %
    % OUTPUT:
    %   None (modifies global `adj_matrix`)

    global adj_matrix;

    [row_idx, col_idx] = find(adj_matrix);  % Get nonzero positions O(e)
    for k = 1:numel(row_idx)
        if adj_matrix(row_idx(k), col_idx(k)) < thresh
            adj_matrix(row_idx(k), col_idx(k)) = 0;  % Directly set value to 0
        end
    end

end

