/*==========================================================
 * apply_tfce.cpp - Optimized TFCE implementation for MEX
 *
 * Optimized TFCE function for connectivity-based analysis (Edge-Based).
 * - Precomputes when each edge is introduced.
 * - Updates clusters incrementally instead of recomputing from scratch.
 * - Avoids redundant operations for better efficiency.
 *
 * Usage:
 *   tfced = apply_tfce(img, dh, H, E)
 *   tfced = apply_tfce(img) - uses default parameters (dh=0.1, H=3.0, E=0.4)
 *
 *========================================================*/

#include "mex.h"
#include <vector>
#include <algorithm>
#include <cmath>
#include <string>
#include <unordered_map>

// Structure to represent edges
struct Edge {
    int row;
    int col;
};

// Structure to represent clusters
struct Cluster {
    std::vector<bool> nodes;
    int node_size;
    int size;
    bool active;
    bool has_edges;
};

// Core implementation function with explicit parameters
void apply_tfce_impl(double *img, int num_nodes, double dh, double H, double E, double *tfced) {
    // Preprocessing
    // Thresholding to avoid extreme values
    for (int i = 0; i < num_nodes * num_nodes; i++) {
        if (img[i] > 1000) {
            img[i] = 100;
        }
    }
    
    // Set diagonal to zero (for graphs)
    for (int i = 0; i < num_nodes; i++) {
        img[i * num_nodes + i] = 0;
    }
    
    // Find maximum value in the image
    double max_val = 0;
    for (int i = 0; i < num_nodes; i++) {
        for (int j = i + 1; j < num_nodes; j++) {
            if (img[i + j * num_nodes] > max_val) {
                max_val = img[i + j * num_nodes];
            }
        }
    }
    
    // Create thresholds
    std::vector<double> threshs;
    for (double t = 0; t <= max_val + dh; t += dh) {
        threshs.push_back(t);
    }
    int num_thresh = static_cast<int>(threshs.size());
    
    // Precompute edge introduction rounds
    std::vector<std::vector<Edge>> edges_by_thresh(num_thresh);
    
    // Extract edges from adjacency matrix (upper triangle only)
    for (int i = 0; i < num_nodes; i++) {
        for (int j = i + 1; j < num_nodes; j++) {
            double edge_weight = img[i + j * num_nodes];
            if (edge_weight <= 0) {
                continue;
            }
            
            // Add small perturbation so edges are always correctly placed
            int round_idx = static_cast<int>(floor(edge_weight / dh + 1e-10));
            if (round_idx < num_thresh) {
                Edge edge = {i, j};
                edges_by_thresh[round_idx].push_back(edge);
            }
        }
    }
    
    // Initialize clusters
    std::vector<int> cluster_labels(num_nodes);
    std::vector<Cluster> clusters(num_nodes);
    
    for (int n = 0; n < num_nodes; n++) {
        cluster_labels[n] = n;
        clusters[n].nodes.resize(num_nodes, false);
        clusters[n].nodes[n] = true;
        clusters[n].node_size = 1;
        clusters[n].size = 0;
        clusters[n].active = true;
        clusters[n].has_edges = false;
    }
    
    std::vector<std::vector<bool>> active_edges(num_nodes, std::vector<bool>(num_nodes, false));
    std::vector<std::vector<int>> cluster_size_per_node(num_thresh, std::vector<int>(num_nodes, 0));
    
    // Iterate over thresholds and incrementally merge clusters
    for (int h = num_thresh - 1; h >= 1; h--) {
        // Get edges introduced at this threshold
        std::vector<Edge>& new_edges = edges_by_thresh[h];
        
        // Merge clusters based on new edges
        for (size_t k = 0; k < new_edges.size(); k++) {
            int i = new_edges[k].row;
            int j = new_edges[k].col;
            active_edges[i][j] = true;
            active_edges[j][i] = true;
            
            int cluster_i = cluster_labels[i];
            int cluster_j = cluster_labels[j];
            
            if (cluster_i != cluster_j) {
                // Merge smaller cluster into the larger one
                int target_cluster, absorbed_cluster;
                if (clusters[cluster_i].node_size >= clusters[cluster_j].node_size) {
                    target_cluster = cluster_i;
                    absorbed_cluster = cluster_j;
                } else {
                    target_cluster = cluster_j;
                    absorbed_cluster = cluster_i;
                }
                
                // Combine clusters
                for (int n = 0; n < num_nodes; n++) {
                    if (clusters[absorbed_cluster].nodes[n]) {
                        clusters[target_cluster].nodes[n] = true;
                    }
                }
                clusters[target_cluster].node_size += clusters[absorbed_cluster].node_size;
                clusters[target_cluster].size += 1;
                
                // Update cluster size
                clusters[target_cluster].size += clusters[absorbed_cluster].size;
                
                // Mark absorbed cluster as merged
                clusters[absorbed_cluster].active = false;
                
                // Update cluster labels
                for (int n = 0; n < num_nodes; n++) {
                    if (clusters[absorbed_cluster].nodes[n]) {
                        cluster_labels[n] = target_cluster;
                    }
                }
            } else {
                clusters[cluster_i].size += 1;
                clusters[cluster_i].has_edges = true;
            }
        }
        
        for (int j = 0; j < num_nodes; j++) {
            if (clusters[j].active) {
                for (int n = 0; n < num_nodes; n++) {
                    if (clusters[j].nodes[n]) {
                        cluster_size_per_node[h][n] = clusters[j].size;                      
                    }
                }
            }
        }
    }
    
    // Calculate and accumulate TFCE contributions directly
    std::vector<std::vector<double>> cumulative_node_tfce(num_thresh, std::vector<double>(num_nodes, 0.0));
    
    // For subsequent thresholds, add to the previous accumulated values
    for (int h = 1; h < num_thresh; h++) {
        double th = threshs[h];
        for (int n = 0; n < num_nodes; n++) {
            cumulative_node_tfce[h][n] = cumulative_node_tfce[h-1][n] + 
                                        pow(cluster_size_per_node[h][n], E) * pow(th, H) * dh;
        }
    }

    // Zero-initialize the output matrix
    for (int i = 0; i < num_nodes * num_nodes; i++) {
        tfced[i] = 0.0;
    }
    
    // Fill in TFCE values
    for (int h = 1; h < num_thresh; h++) {
        std::vector<Edge>& edges = edges_by_thresh[h];
        
        for (size_t i = 0; i < edges.size(); i++) {
            int node_1 = edges[i].row;
            int node_2 = edges[i].col;
            
            // MATLAB uses column-major order
            tfced[node_1 + node_2 * num_nodes] = cumulative_node_tfce[h][node_1];
            tfced[node_2 + node_1 * num_nodes] = cumulative_node_tfce[h][node_1];
        }
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Check for proper number of arguments
    if (nrhs < 1) {
        mexErrMsgIdAndTxt("MATLAB:apply_tfce:invalidNumInputs",
                "At least one input required.");
    }
    
    if (nlhs > 1) {
        mexErrMsgIdAndTxt("MATLAB:apply_tfce:maxlhs",
                "Too many output arguments.");
    }
    
    // Get the input adjacency matrix
    if (!mxIsDouble(prhs[0])) {
        mexErrMsgIdAndTxt("MATLAB:apply_tfce:invalidInput",
                "Input matrix must be of type double.");
    }
    
    double *img = mxGetPr(prhs[0]);
    mwSize m = mxGetM(prhs[0]);
    mwSize n = mxGetN(prhs[0]);
    int num_nodes = static_cast<int>(n);
    
    if (m != n) {
        mexErrMsgIdAndTxt("MATLAB:apply_tfce:invalidInput",
                "Input matrix must be square.");
    }


    // Check optional parameters are of proper type
    if (nrhs >= 2 && !mxIsDouble(prhs[1])) {
        mexErrMsgIdAndTxt("MATLAB:apply_tfce:invalidInput",
                "dh parameter must be of type double.");
    }
    if (nrhs >= 3 && !mxIsDouble(prhs[2])) {
        mexErrMsgIdAndTxt("MATLAB:apply_tfce:invalidInput",
                "H parameter must be of type double.");
    }
    if (nrhs >= 4 && !mxIsDouble(prhs[3])) {
        mexErrMsgIdAndTxt("MATLAB:apply_tfce:invalidInput",
                "E parameter must be of type double.");
    }
    
    // Set default parameters
    double dh = 0.1;
    double H = 3.0;
    double E = 0.4;
    
    // Process all arguments directly (no name-value pairs)
    if (nrhs >= 2) {
        dh = mxGetScalar(prhs[1]);
    }
    if (nrhs >= 3) {
        H = mxGetScalar(prhs[2]);
    }
    if (nrhs >= 4) {
        E = mxGetScalar(prhs[3]);
    }
    
    // Create output matrix
    plhs[0] = mxCreateDoubleMatrix(num_nodes, num_nodes, mxREAL);
    double *tfced = mxGetPr(plhs[0]);

    //plhs[0] = mxCreateDoubleMatrix(8, 4, mxREAL);
    //double *tfced = mxGetPr(plhs[0]);
    
    // Call the implementation function with explicit parameters
    apply_tfce_impl(img, num_nodes, dh, H, E, tfced);
}