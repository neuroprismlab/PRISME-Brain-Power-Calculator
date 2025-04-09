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
    
    %% Size is the number of edges connected to the cluster
    clusters(num_nodes) = struct();
    for n = 1:num_nodes
        clusters(n).nodes = false(num_nodes, 1);
        clusters(n).nodes(n) = true;
        clusters(n).node_size = 1;
        clusters(n).size  = 1;
        clusters(n).active = true;
        clusters(n).has_edges = false;
    end
    active_edges = false(num_nodes, num_nodes);

    cluster_size_per_node = zeros(num_thresh, num_nodes);

    %% **Iterate Over Thresholds and Incrementally Merge Clusters**
    for h = num_thresh:-1:1  % Iterate from highest to lowest threshold
        th = h * dh;  % Compute current threshold

        % Get edges introduced at this threshold
        new_edges = edges_by_thresh{h};  

        % **Merge clusters based on new edges**
        for k = 1:size(new_edges, 1)
            i = new_edges(k, 1);
            j = new_edges(k, 2);
            active_edges(i, j) = true;
            active_edges(j, i) = true;
            
            cluster_i = cluster_labels(i);
            cluster_j = cluster_labels(j);

            clusters(cluster_i).size = clusters(cluster_i).size + 1;
            clusters(cluster_j).size = clusters(cluster_j).size + 1;

            cluster(cluster_i).has_edges = true;
            cluster(cluster_j).has_edges = true;
          
            if cluster_i ~= cluster_j  % Merge only if they are different
                % Merge smaller cluster into the larger one
                if clusters(cluster_i).node_size >= clusters(cluster_j).node_size
                    target_cluster = cluster_i;
                    absorbed_cluster = cluster_j;
                else
                    target_cluster = cluster_j;
                    absorbed_cluster = cluster_i;
                end
                
                % Combine clusters
                clusters(target_cluster).nodes(clusters(absorbed_cluster).nodes) = true;
                clusters(target_cluster).node_size = clusters(target_cluster).node_size + ...
                                                        clusters(absorbed_cluster).node_size;
 
                % Update cluster size
                clusters(target_cluster).size = clusters(target_cluster).size + clusters(absorbed_cluster).size;

                % Mark absorbed cluster as merged
                clusters(absorbed_cluster).active = false;
                cluster_labels(clusters(absorbed_cluster).nodes) = target_cluster;
            end

        end
        

        for j = 1:clusters 
           
        end

        % **Compute TFCE Contribution Efficiently**
        for c = 1:numel(clusters)
            if ~clusters(c).active || ~clusters(c).has_edges  % Skip merged or inactive clusters
                continue;
            end

            % Compute TFCE update for this cluster
            cluster_size = clusters(c).size;  % Already tracked incrementally
            tfce_update = (cluster_size .^ E) .* (th ^ H) * dh;

            % Update TFCE values only for this cluster's edges
            node_mask = clusters(c).nodes;
            tfce_vals(node_mask, node_mask) = tfce_update .* active_edges(node_mask, node_mask);
        end
        
    end

    tfced = tfce_vals;
end
