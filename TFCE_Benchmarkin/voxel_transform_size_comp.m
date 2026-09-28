function [allMatch, mismatchDetails] = validate_voxel_transform_fn(seed)
% validate_voxel_transform_fn.m
%
% Empirical validation of voxel transformation
%
% Method 1 ("traditional"): direct spatial thresholding + connected-
%   component labeling via BFS over 4-connected neighbors.
%
% Method 2 ("graph transformation"): build the transformed graph
%   nodes = voxels,
%   edges between spatially adjacent voxels (with self-loops),
%   edge weight = min(T(v1), T(v2))
%   then compute S_h via BFS over only
%   the edges surviving threshold h (Section 6.3).
%
% For every threshold tested, the two partitions (which voxels group
% together, and which voxels are excluded entirely) are compared.
%
% INPUT:
%   seed - RNG seed (only argument; grid size is fixed inside)
%
% OUTPUT:
%   allMatch        - true if N_h and S_h agreed at every threshold tested
%   mismatchDetails - cell array of strings describing any mismatches

rng(seed);

%% --- Generate a spatially correlated random test field ---
nRows = 25;
nCols = 25;

rawField = randn(nRows, nCols);

% Smooth with a small Gaussian-like kernel to induce spatial clustering
kernel = [1 2 1; 2 4 2; 1 2 1];
kernel = kernel / sum(kernel(:));
T = conv2(rawField, kernel, 'same');

nVoxels = nRows * nCols;

%% --- Build 4-connected neighbor list (adjacency used by both methods) ---
% neighbors{k} = list of linear indices adjacent to voxel k
neighbors = cell(nVoxels, 1);
for r = 1:nRows
    for c = 1:nCols
        k = sub2ind([nRows, nCols], r, c);
        nbrs = [];

        if r > 1
            nbrs(end+1) = sub2ind([nRows, nCols], r-1, c); %#ok<AGROW>
        end
        if r < nRows
            nbrs(end+1) = sub2ind([nRows, nCols], r+1, c); %#ok<AGROW>
        end
        if c > 1
            nbrs(end+1) = sub2ind([nRows, nCols], r, c-1); %#ok<AGROW>
        end
        if c < nCols
            nbrs(end+1) = sub2ind([nRows, nCols], r, c+1); %#ok<AGROW>
        end
        neighbors{k} = nbrs;
    end
end

Tvec = T(:);

%% --- Build the transformed graph's edge list (Section 6.2) ---
% Each spatial adjacency (i,j) becomes an edge with weight min(T(i),T(j)).
% Self-loops (v,v) get weight T(v), per the self-adjacency convention.
% Both directions (i,j) and (j,i) are stored explicitly (undirected graph).
% sparse graph format -> (I(i), J(i)), weight = W(I(i), J(i))
edgeI = [];
edgeJ = [];
edgeW = [];

for i = 1:nVoxels
    % self-loop
    edgeI(end+1) = i; %#ok<AGROW>
    edgeJ(end+1) = i; %#ok<AGROW>
    edgeW(end+1) = Tvec(i); %#ok<AGROW>

    for j = neighbors{i}
        w = min(Tvec(i), Tvec(j));
        edgeI(end+1) = i; %#ok<AGROW>
        edgeJ(end+1) = j; %#ok<AGROW>
        edgeW(end+1) = w; %#ok<AGROW>
    end
end

%% --- Sweep thresholds and compare the two cluster definitions ---
% TFCE integrates h from 0 to hmax (Eq. 1), so only nonnegative
% thresholds are tested here for consistency.
thresholds = linspace(0, max(Tvec) + 0.05, 40);

allMatch = true;
mismatchDetails = {};

for h = thresholds

    % ---- Method 1: traditional N_h via BFS ----
    % labelTrad will label the nodes with their respective cluster
    labelTrad = zeros(nVoxels, 1); % 0 = excluded (below threshold, no valid path)
    visited = false(nVoxels, 1);
    nextLabel = 1;

    for start = 1:nVoxels
        if visited(start)
            continue
        end

        if Tvec(start) < h
            visited(start) = true; % below threshold: never included, per N_h definition
            continue;
        end

        % BFS starting from the first node above threshold
        queue = start;
        visited(start) = true;
        comp = start;
        qi = 1;
        while qi <= numel(queue)

            % Get next element in queue
            node = queue(qi);
            % Add one to see if we reach the end next ite
            qi = qi + 1;

            for nb = neighbors{node}

                % Add new node to end of queue and cluster if conditions
                % match
                if ~visited(nb) && Tvec(nb) >= h
                    visited(nb) = true;
                    queue(end+1) = nb; %#ok<AGROW>
                    comp(end+1) = nb; %#ok<AGROW>
                end
            end

        end

        % Comp contains the index of the nodes in the cluster
        % labelTrad(comp) - assigns cluster label to all voxels in cluster
        % Finally, update label for next cluster as BFS is over
        labelTrad(comp) = nextLabel;
        nextLabel = nextLabel + 1;
    end

    % ---- Method 2: graph transformation S_h via BFS over Gamma(D) ----
    % Index which edges and indexes of the sparse matrix to keep
    keep = edgeW >= h;
    kI = edgeI(keep);
    kJ = edgeJ(keep);

    % adjacency list restricted to surviving edges
    % we consider only the nodes where the self edge survives
    % for the other edges - simply add to adjacency list
    activeNode = false(nVoxels, 1);
    adjKeep = cell(nVoxels, 1);
    for e = 1:numel(kI)
        i = kI(e); j = kJ(e);

        if i == j
            % If self edge, add active node
            activeNode(i) = true;
        else
            % If other edge, add to adjacency
            adjKeep{i}(end+1) = j;
            adjKeep{j}(end+1) = i;
        end
    end

    % New labels for the sparse transformed computation
    labelGraph = zeros(nVoxels, 1);
    visited2 = false(nVoxels, 1);
    nextLabel2 = 1;

    % BFS on the sparse graph
    for start = 1:nVoxels

        % If already visited continue
        if visited2(start)
            continue;
        end

        % If not active, just add to visited and continue
        if ~activeNode(start)
            visited2(start) = true;
            continue;
        end

        % Run BFS
        queue = start;
        visited2(start) = true;
        comp = start;
        qi = 1;
        while qi <= numel(queue)
            node = queue(qi); qi = qi + 1;
            for nb = adjKeep{node}
                if ~visited2(nb)
                    visited2(nb) = true;
                    queue(end+1) = nb; %#ok<AGROW>
                    comp(end+1) = nb; %#ok<AGROW>
                end
            end
        end

        % Assign cluster labels to node and update labels
        labelGraph(comp) = nextLabel2;
        nextLabel2 = nextLabel2 + 1;
    end

    % ---- Compare partitions (ignore arbitrary label numbering) ----
    % Two partitions are equal iff their co-membership matrices match:
    % voxel a and b are in the same nonzero cluster under method 1
    % iff they are under method 2, AND a voxel is "included" (nonzero)
    % under method 1 iff it is under method 2.

    includedTrad = labelTrad > 0;
    includedGraph = labelGraph > 0;
    
    % If the cluster labels are not equal, accuse mismatch
    if ~isequal(includedTrad, includedGraph)
        allMatch = false;
        mismatchDetails{end+1} = sprintf( ...
            'h=%.4f: inclusion mismatch (trad included=%d, graph included=%d)', ...
            h, sum(includedTrad), sum(includedGraph)); %#ok<AGROW>
        continue;
    end
    
    % Provide location of mismatch
    idx = find(includedTrad);
    ok = true;
    for a = 1:numel(idx)
        for b = a+1:numel(idx)
            va = idx(a); vb = idx(b);
            sameTrad = (labelTrad(va) == labelTrad(vb));
            sameGraph = (labelGraph(va) == labelGraph(vb));
            if sameTrad ~= sameGraph
                ok = false;
                break;
            end
        end
        if ~ok, break; end
    end

    if ~ok
        allMatch = false;
        mismatchDetails{end+1} = sprintf('h=%.4f: cluster grouping mismatch', h); %#ok<AGROW>
    end
end

%% --- Report --- 
fprintf('[seed=%d] Tested %d thresholds spanning [%.4f, %.4f].\n', ...
    seed, numel(thresholds), min(thresholds), max(thresholds));

if allMatch
    fprintf(['[seed=%d] PASS: traditional N_h clusters and graph-transformation ' ...
        'S_h clusters are identical at every threshold tested.\n'], seed);
else
    fprintf('[seed=%d] FAIL: mismatches found:\n', seed);
    for k = 1:numel(mismatchDetails)
        fprintf('  %s\n', mismatchDetails{k});
    end
end

end