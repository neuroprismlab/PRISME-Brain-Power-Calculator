function tfced = apply_tfce(img, varargin)
% Optimized TFCE function for connectivity-based analysis (Edge-Based).
%
% Reduces redundant computations by:
%   1. Precomputing when each edge is removed.
%   2. Implementing BFS manually on the sparse adjacency matrix.
%   3. Tracking clusters efficiently using edge-based connectivity.
%
% Usage:
%   tfced = apply_tfce(img, 'matrix')
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
    
    %% **Precompute Edge Removal Masks**
    global adj_matrix;
    
    l_create_sparse_adjacency(img, threshs(1));
   

    % **Initialize TFCE accumulation variable**
    tfce_vals = zeros(size(img));  
    
    %% **Iterate Over Thresholds and Compute Edge Clusters**
    lonly_nodes = false(size(adj_matrix, 1), 1);
    for h = 1:ndh
        th = threshs(h);
        
        l_update_sparse_adjacency(th);
      
        
        connected_nodes = get_components2(adj_matrix);
      
        % Get unique clusters
        unique_clusters = unique(connected_nodes);

        % Create logical mask for each cluster
        cluster_masks = arrayfun(@(c) connected_nodes == c, unique_clusters, 'UniformOutput', false);

        % Precompute cluster sizes (number of edges per cluster)
        cluster_sizes = cellfun(@(mask) nnz(adj_matrix(mask, mask)) / 2, cluster_masks);

        % Compute TFCE updates for all clusters
        tfce_updates = (cluster_sizes .^ E) .* (th ^ H) * dh;

        tfce_update_matrix = zeros(size(tfce_vals));
        % Vectorized assignment using logical indexing
        for i = 1:numel(unique_clusters)
            tfce_update_matrix(cluster_masks{i}, cluster_masks{i}) = tfce_updates(i);
        end

        % Update TFCE values in one step (vectorized)
        tfce_vals = tfce_vals + tfce_update_matrix;
        
    end
    
    %% **Final Output**
    tfced = tfce_vals;  % The final TFCE-transformed data
end

%% **Create Initial Sparse Adjacency Matrix**
function l_create_sparse_adjacency(img, initial_thresh)
    global adj_matrix;
    adj_matrix = img .* bsxfun(@ge, img, initial_thresh);
end

%% **Update Sparse Adjacency Matrix Based on Precomputed Edge Mask**
function l_update_sparse_adjacency(th)
    global adj_matrix 
    adj_matrix = adj_matrix .* bsxfun(@ge, adj_matrix, th);
end

%% **BFS on Sparse Adjacency Matrix to Find Connected Nodes (Logical Mask)**
function connected_mask = bfs(start_node)
    % Optimized BFS using a preallocated queue (circular array technique)
    %
    % INPUT:
    %   start_node - The starting node for BFS
    %
    % OUTPUT:
    %   connected_mask - Logical vector where `true` indicates connected nodes
    
    global adj_matrix;
    n = size(adj_matrix, 1);
    
    % Preallocate queue for efficiency
    queue = zeros(n, 1);
    queue_start = 1;
    queue_end = 1;
    
    % Initialize visited mask
    connected_mask = false(n, 1);
    connected_mask(start_node) = true;
    
    % Initialize queue
    queue(queue_end) = start_node;
    
    while queue_start <= queue_end  % Efficient queue traversal
        current = queue(queue_start);
        queue_start = queue_start + 1;  % Move front pointer
        
        % Find unvisited neighbors
        neighbors = find(adj_matrix(current, :) > 0);
        unvisited_neighbors = neighbors(~connected_mask(neighbors));

        % Mark them as visited
        connected_mask(unvisited_neighbors) = true;
        
        % Enqueue new neighbors
        num_new = numel(unvisited_neighbors);
        queue(queue_end + (1:num_new)) = unvisited_neighbors;
        queue_end = queue_end + num_new;
    end
end