function tfced = apply_tfce(img)
% Optimized TFCE function for connectivity-based analysis (Edge-Based).
%
% - Precomputes when each edge is introduced.
% - Updates clusters incrementally instead of recomputing from scratch.
% - Avoids redundant operations for better efficiency.
%
% Usage:
%   tfced = apply_tfce(img)

    %% **Set Parameters**
    dh = 0.1; % Threshold step size
    H = 3.0;
    E = 0.4;
       
    %% **Preprocessing**
    img(img > 1000) = 100; % Thresholding to avoid extreme values
    perturbation = rand(size(img)) * 1e-15; % Small perturbation for numerical stability
    img = img + tril(perturbation, -1) + tril(perturbation, -1)'; % Ensure symmetry
    img(logical(eye(size(img)))) = 0; % Set diagonal to zero (for graphs)

    %% **Precompute Edge Introduction Rounds**
    num_thresh = ceil(max(img(:)) / dh); % Number of threshold rounds
    edges_by_thresh = cell(num_thresh, 1); % Store edges by threshold round

    % Extract edges from adjacency matrix
    [row, col, edge_weights] = find(triu(img)); % Only upper triangle

    % Assign edges to their first appearance based on thresholding
    for i = 1:numel(edge_weights)
        if edge_weights(i) <= 0  % Skip edges with zero or negative weight
            continue;
        end
        round_idx = min(num_thresh, ceil(edge_weights(i) / dh)); % Ensure index is valid
        edges_by_thresh{round_idx} = [edges_by_thresh{round_idx}; row(i), col(i)];
    end

    %% **Initialize Variables**
    tfce_vals = zeros(size(img)); % TFCE accumulation matrix

    %% **Initialize Clusters**
    num_nodes = size(img, 1);
    cluster_labels = (1:num_nodes)';  % Start with each node as its own cluster
    cluster_sizes = ones(num_nodes, 1); % Each node starts as its own cluster

    clusters(num_nodes) = struct();

    for n = 1:num_nodes
        clusters(n).edges = false(num_nodes, num_nodes);
        clusters(n).nodes = false(num_nodes, 1);
        clusters(n).size  = 1;
        clusters(n).has_edges = false;
        clusters(n).nodes(n) = true; % Each node starts alone
    end

    %% **Iterate Over Thresholds and Incrementally Merge Clusters**
    for h = num_thresh:-1:1  % Iterate from highest to lowest threshold
        th = h * dh;  % Compute current threshold
    
        % Get edges introduced at this threshold
        new_edges = edges_by_thresh{h};  
    
        % **Merge clusters based on new edges**
        for k = 1:size(new_edges, 1)
            i = new_edges(k, 1);
            j = new_edges(k, 2);
    
            cluster_i = cluster_labels(i);
            cluster_j = cluster_labels(j);

            if cluster_i ~= cluster_j  % Merge only if they are different
                % Merge smaller cluster into the larger one
                if cluster_sizes(cluster_i) >= cluster_sizes(cluster_j)
                    target_cluster = cluster_i;
                    absorbed_cluster = cluster_j;
                else
                    target_cluster = cluster_j;
                    absorbed_cluster = cluster_i;
                end
            
                % **Add the new edge to the cluster before merging**
                clusters(target_cluster).edges(i, j) = true;
                clusters(target_cluster).edges(j, i) = true;
                clusters(target_cluster).nodes(i) = true;
                clusters(target_cluster).nodes(j) = true;
  
                clusters(target_cluster).edges = clusters(target_cluster).edges | clusters(absorbed_cluster).edges;
                clusters(target_cluster).nodes = clusters(target_cluster).nodes | clusters(absorbed_cluster).nodes;
                
                % Update cluster size
                clusters(target_cluster).size = clusters(target_cluster).size + clusters(absorbed_cluster).size;
                clusters(target_cluster).has_edges = true; % Mark as active
            
                % Mark absorbed cluster as merged
                clusters(absorbed_cluster).size = 0;
                cluster_labels(cluster_labels == absorbed_cluster) = target_cluster;
            end
        end
    
        % **Compute TFCE Contribution Efficiently**
        for c = 1:numel(clusters)
            if clusters(c).size == 0 || ~clusters(c).has_edges  % Skip merged or inactive clusters
                continue;
            end

            % Compute TFCE update for the cluster
            cluster_size = clusters(c).size;  
            tfce_update = (cluster_size .^ E) .* (th ^ H) * dh;

            % Assign TFCE contributions efficiently
            tfce_vals(clusters(c).edges) = tfce_vals(clusters(c).edges) + tfce_update;
        end
    end

    tfced = tfce_vals;

end