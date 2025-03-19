#include "mex.h"
#include <vector>
#include <queue>
#include <algorithm>
#include <cmath>
#include <unordered_set>

// BFS for connected components, skipping already known nodes
void bfs_component(const std::vector<std::vector<int>> &adj_list, std::vector<bool> &visited, 
                   int start_node, int &cluster_size) {
    std::queue<int> q;
    q.push(start_node);
    visited[start_node] = true;
    cluster_size = 0;

    while (!q.empty()) {
        int node = q.front();
        q.pop();
        cluster_size++;

        for (int neighbor : adj_list[node]) {
            if (!visited[neighbor]) {
                visited[neighbor] = true;
                q.push(neighbor);
            }
        }
    }
}

// TFCE computation with cluster tracking and skipping isolated nodes
void compute_tfce(double* img, mwSize nElements, double H, double E, double dh, double* tfced, 
                  const std::vector<std::vector<int>> &adj_list) {
    // Determine thresholds
    std::vector<double> thresholds;
    double max_val = 0.0;
    for (mwSize i = 0; i < nElements; i++) {
        max_val = std::max(max_val, img[i]);
    }
    for (double t = dh; t <= max_val; t += dh) {
        thresholds.push_back(t);
    }
    mwSize ndh = thresholds.size();

    // Initialize TFCE values
    std::vector<double> vals(nElements, 0.0);
    std::vector<bool> is_isolated(nElements, false);  // Track isolated nodes
    std::vector<bool> visited(nElements, false);  // To track visited nodes

    // Compute TFCE at each threshold
    for (mwSize h = 0; h < ndh; h++) {
        double thresh = thresholds[h];

        // Reset visited array for this threshold
        std::fill(visited.begin(), visited.end(), false);

        // Iterate through all elements, skipping isolated ones
        for (mwSize i = 0; i < nElements; i++) {
            if (is_isolated[i] || visited[i]) continue;  // Skip isolated nodes and already computed clusters

            // If this node is below the threshold, mark as isolated and continue
            if (img[i] < thresh) {
                is_isolated[i] = true;
                continue;
            }

            // Compute connected component for this node
            int cluster_size = 0;
            bfs_component(adj_list, visited, i, cluster_size);

            // Apply TFCE transformation to all elements in the cluster
            double curval = std::pow(cluster_size, E) * std::pow(thresh, H);
            for (mwSize j = 0; j < nElements; j++) {
                if (visited[j]) {
                    vals[j] += curval;
                }
            }
        }
    }

    // Normalize TFCE values
    for (mwSize i = 0; i < nElements; i++) {
        tfced[i] = vals[i] * dh;
    }
}

// MEX function entry point
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Validate input arguments
    if (nrhs != 5) {
        mexErrMsgIdAndTxt("TFCE:InvalidInput", "Usage: tfce_mex(img, H, E, dh, adj_list)");
    }

    // Read input arguments
    double* img = mxGetPr(prhs[0]);
    mwSize nElements = mxGetNumberOfElements(prhs[0]);
    double H = mxGetScalar(prhs[1]);
    double E = mxGetScalar(prhs[2]);
    double dh = mxGetScalar(prhs[3]);

    // Read adjacency list from input
    mxArray* adj_list_mx = prhs[4];
    std::vector<std::vector<int>> adj_list(nElements);

    for (mwSize i = 0; i < nElements; i++) {
        mxArray* cell = mxGetCell(adj_list_mx, i);
        if (cell != nullptr) {
            double* neighbors = mxGetPr(cell);
            mwSize num_neighbors = mxGetNumberOfElements(cell);
            adj_list[i].assign(neighbors, neighbors + num_neighbors);
        }
    }

    // Create output matrix
    plhs[0] = mxCreateDoubleMatrix(nElements, 1, mxREAL);
    double* tfced = mxGetPr(plhs[0]);

    // Compute TFCE
    compute_tfce(img, nElements, H, E, dh, tfced, adj_list);
}