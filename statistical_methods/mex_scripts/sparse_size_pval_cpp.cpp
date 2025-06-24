/**
 * sparse_size_pval_cpp.cpp - MEX implementation for extracting cluster sizes from sparse matrices
 *
 * Usage in MATLAB:
 *   [I, J, ~] = find(sparse_matrix);
 *   cluster_sizes = sparse_size_pval_cpp(I, J, matrix_size)
 *
 * Inputs:
 *   I - Row indices of non-zero elements (MATLAB 1-based indexing)
 *   J - Column indices of non-zero elements (MATLAB 1-based indexing)  
 *   matrix_size - Size of the original square matrix (N)
 *
 * Outputs:
 *   cluster_sizes - Vector of cluster sizes for each node (N x 1 vector)
 *                   Value is 0 if node is not active, otherwise the size of its cluster
 */

#include "mex.h"
#include "matrix.h"
#include <vector>
#include <unordered_map>

// Main MEX function
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Check input arguments
    if (nrhs != 3) {
        mexErrMsgIdAndTxt("SparseSize:invalidNumInputs",
                         "Three inputs required: I, J, matrix_size");
    }
    
    // Check output arguments
    if (nlhs != 1) {
        mexErrMsgIdAndTxt("SparseSize:invalidNumOutputs",
                         "One output required: cluster_sizes");
    }
    
    // Get input data
    double* I = mxGetPr(prhs[0]);  // Row indices (1-based)
    double* J = mxGetPr(prhs[1]);  // Column indices (1-based)
    int N = (int)mxGetScalar(prhs[2]);  // Matrix size
    
    // Get number of non-zero elements
    int nnz = (int)mxGetM(prhs[0]);
    
    // Validate inputs
    if (mxGetM(prhs[1]) != nnz) {
        mexErrMsgIdAndTxt("SparseSize:inconsistentInputs",
                         "I and J must have the same number of elements");
    }
    
    // Cluster indicator array - 0 means no cluster assigned yet
    std::vector<int> cluster_id(N, 0);
    
    // Map from cluster_id to list of nodes in that cluster
    std::unordered_map<int, std::vector<int>> cluster_nodes;
    
    int next_cluster_id = 1;  // Cluster IDs start at 1
    
    // Process each edge according to your pseudocode
    for (int k = 0; k < nnz; k++) {
        // Convert from MATLAB 1-based to C++ 0-based indexing
        int node_i = (int)I[k] - 1;
        int node_j = (int)J[k] - 1;
        
        int cluster_i = cluster_id[node_i];
        int cluster_j = cluster_id[node_j];
        
        if (cluster_i == 0 && cluster_j == 0) {
            // Both nodes do not belong to a cluster - create new cluster
            int new_cluster = next_cluster_id++;
            cluster_id[node_i] = new_cluster;
            cluster_id[node_j] = new_cluster;
            
            cluster_nodes[new_cluster] = {node_i};
            if (node_i != node_j) {  // Avoid duplicates for self-loops
                cluster_nodes[new_cluster].push_back(node_j);
            }
            
        } else if (cluster_i == 0) {
            // Only node_j has a cluster - add node_i to it
            cluster_id[node_i] = cluster_j;
            cluster_nodes[cluster_j].push_back(node_i);
            
        } else if (cluster_j == 0) {
            // Only node_i has a cluster - add node_j to it
            cluster_id[node_j] = cluster_i;
            cluster_nodes[cluster_i].push_back(node_j);
            
        } else if (cluster_i != cluster_j) {
            // Both nodes have different clusters - MERGE!
            // Merge smaller cluster into larger one for efficiency
            if (cluster_nodes[cluster_i].size() < cluster_nodes[cluster_j].size()) {
                // Merge cluster_i into cluster_j
                for (int node : cluster_nodes[cluster_i]) {
                    cluster_id[node] = cluster_j;
                    cluster_nodes[cluster_j].push_back(node);
                }
                cluster_nodes.erase(cluster_i);
            } else {
                // Merge cluster_j into cluster_i
                for (int node : cluster_nodes[cluster_j]) {
                    cluster_id[node] = cluster_i;
                    cluster_nodes[cluster_i].push_back(node);
                }
                cluster_nodes.erase(cluster_j);
            }
        }
        // If cluster_i == cluster_j and both != 0, they're already in same cluster - do nothing
    }
    
    // Create output vector
    plhs[0] = mxCreateDoubleMatrix(N, 1, mxREAL);
    double* cluster_sizes = mxGetPr(plhs[0]);
    
    // Initialize with zeros (inactive nodes)
    for (int i = 0; i < N; i++) {
        cluster_sizes[i] = 0.0;
    }
    
    // Assign cluster sizes to each node
    for (int i = 0; i < N; i++) {
        if (cluster_id[i] != 0) {  // Active node
            int cluster = cluster_id[i];
            cluster_sizes[i] = (double)cluster_nodes[cluster].size();
        }
    }
    
    
    // Print cluster info
    for (const auto& pair : cluster_nodes) {
        int cluster = pair.first;
        int size = pair.second.size();
    }
}