/*==========================================================
 * sparse_tfce_cpp.cpp - Sparse TFCE implementation for MEX
 *
 * Optimized TFCE function for sparse connectivity-based analysis.
 * Uses I,J,V format for memory efficiency with large matrices.
 * - Precomputes when each edge is introduced.
 * - Updates clusters incrementally instead of recomputing from scratch.
 * - Memory-efficient sparse matrix handling.
 *
 * Usage:
 *   [I_out, J_out, V_out] = sparse_tfce_cpp(I, J, V, num_nodes, dh, H, E)
 *
 *========================================================*/

#include "mex.h"
#include <vector>
#include <algorithm>
#include <cmath>
#include <unordered_map>

// Structure to represent clusters
struct Cluster {
    std::vector<int> nodes;
    int size;
    bool active;
};

// Core sparse TFCE implementation
std::vector<double> sparse_tfce_impl(double *I, double *J, double *V, int nnz, 
                                     int num_nodes, double dh, double H, double E) {
    std::vector<double> node_tfce_values(num_nodes, 0.0); 
    
    double max_val = *std::max_element(V, V + nnz);

    // Create thresholds
    std::vector<double> threshs;
    for (double t = 0; t <= max_val + dh; t += dh) {
        threshs.push_back(t);
    }
    int num_thresh = static_cast<int>(threshs.size());
    
    // Precompute edge introduction rounds
    std::vector<std::vector<int>> edges_by_thresh(num_thresh);

    for (int idx = 0; idx < nnz; idx++) {
        int i = static_cast<int>(I[idx]) - 1; // Convert to 0-based indexing
        int j = static_cast<int>(J[idx]) - 1;
        double weight = V[idx];
        
        // Only store upper triangle to avoid duplicates
        if (i < j) {
            continue;
        }

        // Skip diagonal and non-positive weights
        if (weight < 0) {
            continue;
        }

        int round_idx = static_cast<int>(floor(weight / dh + 1e-10));
        if (round_idx < num_thresh) {
            edges_by_thresh[round_idx].push_back(idx);
        }
        
    }

    // Initialize clusters
    std::vector<int> cluster_labels(num_nodes);
    std::vector<Cluster> clusters(num_nodes);
    std::vector<bool> node_inactive(num_nodes, true);
    
    for (int n = 0; n < num_nodes; n++) {
        cluster_labels[n] = n;
        clusters[n].nodes.push_back(n); 
        clusters[n].size = 0;
        clusters[n].active = true;
    }

    // Iterate over thresholds and incrementally merge clusters
    for (int h = num_thresh - 1; h >= 1; h--) {
    
        // Get edges introduced at this threshold
        std::vector<int> new_edges = edges_by_thresh[h];
        
        // Merge clusters based on new edges
        for (int edge_idx : new_edges) {
            int i = static_cast<int>(I[edge_idx]) - 1;
            int j = static_cast<int>(J[edge_idx]) - 1;
            double weight = V[edge_idx];
            
            int cluster_i = cluster_labels[i];
            int cluster_j = cluster_labels[j];

            if(node_inactive[i]){
                clusters[cluster_i].size = clusters[cluster_i].size + 1;
                node_inactive[i] = false;
            }

            if(node_inactive[j]){
                clusters[cluster_j].size = clusters[cluster_j].size + 1;
                node_inactive[j] = false;
            }
        
            if (cluster_i != cluster_j) {
                // Merge smaller cluster into the larger one
                int target_cluster, absorbed_cluster;
                if (clusters[cluster_i].size >= clusters[cluster_j].size) {
                    target_cluster = cluster_i;
                    absorbed_cluster = cluster_j;
                } else {
                    target_cluster = cluster_j;
                    absorbed_cluster = cluster_i;
                }
                
                // Combine clusters - just append all node IDs from absorbed cluster
                for (int node_id : clusters[absorbed_cluster].nodes) {
                    clusters[target_cluster].nodes.push_back(node_id);
                }
                // Update cluster size
                clusters[target_cluster].size += clusters[absorbed_cluster].size;
                
                // Mark absorbed cluster as merged
                clusters[absorbed_cluster].active = false;
                
                // Update cluster labels - only iterate over nodes actually in the absorbed cluster
                for (int node_id : clusters[absorbed_cluster].nodes) {
                    cluster_labels[node_id] = target_cluster;
                }
            } 

        }

        // After the cluster merging loop for each threshold h:
        double current_threshold = threshs[h]; 

        for (int node_id = 0; node_id < num_nodes; node_id++) {
            if (!node_inactive[node_id]) {  // Only process active nodes
                int cluster_id = cluster_labels[node_id];
                
                if (clusters[cluster_id].active && clusters[cluster_id].size > 0) {
                    double tfce_contribution = pow(clusters[cluster_id].size, E) * 
                        pow(current_threshold, H) * dh;
                    
                    node_tfce_values[node_id] += tfce_contribution;
                }
            }
        }
   
    
    }
    
    return node_tfce_values;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Check for proper number of arguments
    if (nrhs != 7) {
        mexErrMsgIdAndTxt("MATLAB:sparse_tfce_cpp:invalidNumInputs",
                "Seven inputs required: I, J, V, num_nodes, dh, H, E");
    }
    
    if (nlhs != 1) {
        mexErrMsgIdAndTxt("MATLAB:sparse_tfce_cpp:invalidNumOutputs",
                            "Exactly one output argument required.");
    }

    // Validate input types
    for (int i = 0; i < nrhs; i++) {
        if (!mxIsDouble(prhs[i])) {
            mexErrMsgIdAndTxt("MATLAB:sparse_tfce_cpp:invalidInput",
                    "All inputs must be of type double.");
        }
    }
    
    // Get input arrays
    double *I = mxGetPr(prhs[0]);
    double *J = mxGetPr(prhs[1]);
    double *V = mxGetPr(prhs[2]);
    int nnz = static_cast<int>(mxGetNumberOfElements(prhs[0]));
    
    // Get scalar parameters
    int num_nodes = static_cast<int>(mxGetScalar(prhs[3]));
    double dh = mxGetScalar(prhs[4]);
    double H = mxGetScalar(prhs[5]);
    double E = mxGetScalar(prhs[6]);
    
    // Validate parameters
    if (num_nodes <= 0) {
        mexErrMsgIdAndTxt("MATLAB:sparse_tfce_cpp:invalidInput",
                "num_nodes must be positive.");
    }
    if (dh <= 0) {
        mexErrMsgIdAndTxt("MATLAB:sparse_tfce_cpp:invalidInput",
                "dh must be positive.");
    }
  
    // Call the implementation function
    std::vector<double> results = sparse_tfce_impl(I, J, V, nnz, num_nodes, dh, H, E);
    
    // Create output arrays
    // My bad I was not clear is a node-based TFCE

    // Create output array and copy results
    plhs[0] = mxCreateDoubleMatrix(num_nodes, 1, mxREAL);
    double *output = mxGetPr(plhs[0]);
    
    for (int n = 0; n < num_nodes; n++) {
        output[n] = results[n];
    }

}