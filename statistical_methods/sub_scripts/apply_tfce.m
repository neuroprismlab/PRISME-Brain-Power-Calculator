function tfced = apply_tfce(img, varargin)
% Optimized TFCE function for connectivity-based analysis (Edge-Based).
%
% - Precomputes when each edge is introduced.
% - Updates clusters incrementally instead of recomputing from scratch.
% - Avoids redundant operations for better efficiency.
%
% Usage:
%   tfced = apply_tfce(img, 'H', 2.0, 'dh', 0.2, 'E', 0.5)
%   tfced = apply_tfce(img)

    %% **Set Parameters**
    % Create input parser
    p = inputParser;
    % Add parameters with default values
    addOptional(p, 'dh', 0.1);
    addOptional(p, 'H', 3.0);
    addOptional(p, 'E', 0.4);
    % Parse the input arguments
    parse(p, varargin{:});
    % Get the parameters
    dh = p.Results.dh; % Threshold step size
    H = p.Results.H;
    E = p.Results.E;
 

    %% **Preprocessing**
    img(img > 1000) = 100; % Thresholding to avoid extreme values
    % perturbation = rand(size(img)) * 1e-15; % Small perturbation for numerical stability
    % img = img + tril(perturbation, -1) + tril(perturbation, -1)'; % Ensure symmetry
    img(logical(eye(size(img)))) = 0; % Set diagonal to zero (for graphs)

    %% **Precompute Edge Introduction Rounds**
    threshs = 0:dh:(max(img(:)) + dh); % Add dh/2 to guarantee the correct number of bins
    num_thresh = numel(threshs); % Number of threshold rounds
    edges_by_thresh = cell(num_thresh, 1); % Store edges by threshold round

    % Extract edges from adjacency matrix
    [row, col, edge_weights] = find(triu(img)); % Only upper triangle

    % Assign edges to their first appearance based on thresholding
    for i = 1:numel(edge_weights)
        if edge_weights(i) <= 0  % Skip edges with zero or negative weight
            continue;
        end
        % Add small perturbation so edges are always correctly placed
        round_idx = floor(edge_weights(i) / dh + 1e-10) + 1;

        edges_by_thresh{round_idx, 1} = [edges_by_thresh{round_idx}; row(i), col(i)];
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
        clusters(n).size = 0;  
        clusters(n).active = true;
        clusters(n).has_edges = false;
    end
    active_edges = false(num_nodes, num_nodes);

    cluster_size_per_node = zeros(num_thresh, num_nodes);

    %% **Iterate Over Thresholds and Incrementally Merge Clusters**
    for h = num_thresh:-1:2  % Iterate from highest to lowest threshold
        % Get edges introduced at this threshold
        new_edges = edges_by_thresh{h};  

        %
        % **Merge clusters based on new edges**
        for k = 1:size(new_edges, 1)
            i = new_edges(k, 1);
            j = new_edges(k, 2);
            active_edges(i, j) = true;
            active_edges(j, i) = true;
            
            cluster_i = cluster_labels(i);
            cluster_j = cluster_labels(j);
          
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

                clusters(target_cluster).size = clusters(target_cluster).size + 1;
 
                % Update cluster size
                clusters(target_cluster).size = clusters(target_cluster).size + clusters(absorbed_cluster).size;

                % Mark absorbed cluster as merged
                clusters(absorbed_cluster).active = false;
                cluster_labels(clusters(absorbed_cluster).nodes) = target_cluster; % O(log N) - O(1)
            else
            
                  clusters(cluster_i).size = clusters(cluster_i).size + 1;
                  clusters(cluster_i).has_edges = true;

            end

        end
        

        for j = 1:numel(clusters)
            cc = clusters(j);
            if cc.active
                cluster_size_per_node(h, cc.nodes) = cc.size;
            end 
        end
        
    end

    %O(th*N^2 + N^2)
    %O(th*N + N^2)
    
    % Calculate and accumulate TFCE contributions directly
    % For the first threshold, just calculate the values
    cumulative_node_tfce = zeros(num_thresh, num_nodes);
    % cumulative_node_tfce(1, :) = (cluster_size_per_node(1, :) .^ E) * (th ^ H) * dh;
    cumulative_node_tfce(1, :) = 0;
    
    % For subsequent thresholds, add to the previous accumulated values
    for h = 2:num_thresh
        th = threshs(h);  % Use the actual threshold value from threshs array
        cumulative_node_tfce(h, :) = cumulative_node_tfce(h-1, :) + ...
                                     (cluster_size_per_node(h, :) .^ E) * (th ^ H) * dh;
    end
    
    tfced = zeros(num_nodes, num_nodes);
    for h = 1:num_thresh
        edges = edges_by_thresh{h}; 

        for i = 1:size(edges, 1)
            node_1 = edges(i, 1);
            node_2 = edges(i, 2);
            
            tfced(node_1, node_2) = cumulative_node_tfce(h, node_1);
            tfced(node_2, node_1) = cumulative_node_tfce(h, node_1);

        end

    end

end
