function node_tfce_values = apply_tfce_sparse(I, J, V, num_nodes, dh, H, E)
% APPLY_TFCE_SPARSE - MATLAB implementation of sparse TFCE
%
% Optimized TFCE function for sparse connectivity-based analysis.
% Uses I,J,V format for memory efficiency with large matrices.
% - Precomputes when each edge is introduced.
% - Updates clusters incrementally instead of recomputing from scratch.
% - Memory-efficient sparse matrix handling.
%
% Usage:
%   node_tfce_values = apply_tfce_sparse(I, J, V, num_nodes, dh, H, E)
%
% Inputs:
%   I, J, V     - Sparse matrix format (edge indices and weights)
%   num_nodes   - Total number of nodes
%   dh          - Threshold step size
%   H           - Height exponent for TFCE
%   E           - Extent exponent for TFCE
%
% Output:
%   node_tfce_values - TFCE values for each node

% Initialize output
node_tfce_values = zeros(num_nodes, 1);

% Find maximum value for threshold range
max_val = max(V);

% Create thresholds
thresholds = 0:dh:(max_val + dh);
num_thresh = length(thresholds);

% Precompute edge introduction rounds
edges_by_thresh = cell(num_thresh, 1);
for i = 1:num_thresh
    edges_by_thresh{i} = [];
end

% Populate edges by threshold
for idx = 1:length(I)
    i = I(idx);
    j = J(idx);
    weight = V(idx);
    
    % Only store upper triangle to avoid duplicates
    if i < j
        continue;
    end
    
    % Skip diagonal and non-positive weights
    if weight < 0
        continue;
    end
    
    % Find which threshold this edge belongs to
    round_idx = floor(weight / dh + 1e-10) + 1; % MATLAB 1-based indexing
    if round_idx <= num_thresh
        edges_by_thresh{round_idx} = [edges_by_thresh{round_idx}, idx];
    end
end

% Initialize clusters - using cell arrays for dynamic node lists
cluster_labels = (1:num_nodes)';  % Each node starts as its own cluster
clusters = cell(num_nodes, 1);    % Store node IDs for each cluster
cluster_sizes = zeros(num_nodes, 1);
cluster_active = true(num_nodes, 1);
node_inactive = true(num_nodes, 1);

% Initialize each cluster with its own node
for n = 1:num_nodes
    clusters{n} = n;
    cluster_sizes(n) = 0;  % Will be updated when node becomes active
end


% Iterate over thresholds from highest to lowest
for h = num_thresh:-1:2  % Skip threshold 1 (zero threshold)
    
    % Get edges introduced at this threshold
    new_edges = edges_by_thresh{h};
    
    if isempty(new_edges)
        continue;
    end
    
    % Merge clusters based on new edges
    for edge_idx = new_edges
        i = I(edge_idx);
        j = J(edge_idx);
        
        cluster_i = cluster_labels(i);
        cluster_j = cluster_labels(j);
        
        % Activate nodes if they're not already active
        if node_inactive(i)
            cluster_sizes(cluster_i) = cluster_sizes(cluster_i) + 1;
            node_inactive(i) = false;
        end
        
        if node_inactive(j)
            cluster_sizes(cluster_j) = cluster_sizes(cluster_j) + 1;
            node_inactive(j) = false;
        end
        
        % Merge clusters if they're different
        if cluster_i ~= cluster_j
            % Merge smaller cluster into larger one
            if cluster_sizes(cluster_i) >= cluster_sizes(cluster_j)
                target_cluster = cluster_i;
                absorbed_cluster = cluster_j;
            else
                target_cluster = cluster_j;
                absorbed_cluster = cluster_i;
            end
            
            % Combine clusters - append node IDs from absorbed cluster
            clusters{target_cluster} = [clusters{target_cluster}, clusters{absorbed_cluster}];
            
            % Update cluster size
            cluster_sizes(target_cluster) = cluster_sizes(target_cluster) + cluster_sizes(absorbed_cluster);
            
            % Mark absorbed cluster as inactive
            cluster_active(absorbed_cluster) = false;
            
            % Update cluster labels for all nodes in absorbed cluster
            for node_id = clusters{absorbed_cluster}
                cluster_labels(node_id) = target_cluster;
            end
            
            % Clear the absorbed cluster to save memory
            clusters{absorbed_cluster} = [];
        end
    end
    
    % Calculate TFCE contribution for this threshold
    current_threshold = thresholds(h);
    
    for node_id = 1:num_nodes
        if ~node_inactive(node_id)  % Only process active nodes
            cluster_id = cluster_labels(node_id);
            
            if cluster_active(cluster_id) && cluster_sizes(cluster_id) > 0
                tfce_contribution = (cluster_sizes(cluster_id)^E) * ...
                                  (current_threshold^H) * dh;
                
                node_tfce_values(node_id) = node_tfce_values(node_id) + tfce_contribution;
            end
        end
    end

end


end