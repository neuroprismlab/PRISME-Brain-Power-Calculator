function tfce_res = apply_exact_tfce(img, varargin)

    %% **Set Parameters**
    % Create input parser
    p = inputParser;
    % Add parameters with default values
    addOptional(p, 'H', 3.0);
    addOptional(p, 'E', 0.4);
    % Parse the input arguments
    parse(p, varargin{:});
    % Get the parameters
    H = p.Results.H;
    E = p.Results.E;

    % Set non upper diagnonal to 
    img(tril(true(size(img)))) = NaN;
    [~, sorted_index] = sort(img(:));
    conversion_org_array_index = @(x) ind2sub(size(img), x);

    % If n_last_non_nan is not defined, let the error be thrown
    for i = 1:numel(sorted_index)
        [x_idx, y_idx] = conversion_org_array_index(sorted_index(i));
        if isnan(img(x_idx, y_idx))
            n_last_non_nan = i - 1;
            break;
        end
    end

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
    % Start accumulation variable
    is_active = false(num_nodes, num_nodes);
    tfce_res = zeros(num_nodes, num_nodes);
   

    for i = n_last_non_nan:-1:1
        s_i = sorted_index(i);
        
        [node_i, node_j] = conversion_org_array_index(s_i);
        is_active(node_i, node_j) = true;
        is_active(node_j, node_i) = true;

        cluster_i = cluster_labels(node_i);
        cluster_j = cluster_labels(node_j);


        if cluster_i ~= cluster_j

            % Merge clusters based on size
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
            cluster_labels(clusters(absorbed_cluster).nodes) = target_cluster; 
        else
            % Otherwise simply add an edge

            clusters(cluster_i).size = clusters(cluster_i).size + 1;
            clusters(cluster_i).has_edges = true;

        end
        
        % Update tfce
        tfce_res = update_tfce(tfce_res, node_i, node_j, num_nodes, i, img, E, H, ...
            sorted_index, conversion_org_array_index, clusters, cluster_labels, is_active);
        
    end
    
  
end


function tfce_res = update_tfce( ...
    tfce_res, ...
    node_i, node_j, num_nodes, ...
    i, img, ...
    E, H, ...
    sorted_index, conversion_org_array_index, ...
    clusters, cluster_labels, is_active)

    
    % Get ths for integral
    th_current = img(node_i, node_j);
    if i > 1
        [next_node_i, next_node_j] = conversion_org_array_index(sorted_index(i - 1));
        th_next = img(next_node_i, next_node_j);
    else
        th_next = 0;
    end


    % Perform exact integration 
    for n_i = 1:num_nodes-1
        cluster_size = clusters(cluster_labels(n_i)).size;
        for n_j = n_i+1:num_nodes
            if is_active(n_i, n_j)
                contribution = cluster_size^E*(th_current^(H + 1) - th_next^(H + 1))/(H + 1);
                tfce_res(n_i, n_j) = tfce_res(n_i, n_j) + contribution;
                tfce_res(n_j, n_i) = tfce_res(n_j, n_i) + contribution;  
            end
        end
    end

end

