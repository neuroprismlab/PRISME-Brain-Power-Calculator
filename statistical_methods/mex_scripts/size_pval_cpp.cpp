/**
 * size_pval_cpp.cpp - MEX implementation of the network-based statistics Size method
 *
 * Usage in MATLAB:
 *   pval = size_pval_cpp(adj_matrix, permuted_adj_matrices)
 *
 * Inputs:
 *   adj_matrix - Binary adjacency matrix of significant connections (N x N matrix)
 *   permuted_adj_matrices - Binary adjacency matrices from permutations (N x N x K matrix)
 *
 * Outputs:
 *   pval - FWER-corrected p-values for each edge (N x N matrix)
 */

#include "mex.h"
#include "matrix.h"
#include <vector>
#include <queue>
#include <cmath>
#include <algorithm>

// Structure to store node and component info
struct ComponentInfo {
    std::vector<int> nodes;
    double size;
    int id;
};

// Combined function to find connected components and calculate their sizes
std::vector<ComponentInfo> get_components_with_sizes(const double* adj_matrix, int N) {
    std::vector<ComponentInfo> components;
    std::vector<bool> visited(N, false);
    int component_id = 1;
    
    for (int start = 0; start < N; start++) {
        if (visited[start]) continue;
        
        // Check if this node has any connections
        bool has_connections = false;
        for (int i = 0; i < N; i++) {
            if (adj_matrix[start*N + i] > 0) {
                has_connections = true;
                break;
            }
        }
        
        if (!has_connections) {
            visited[start] = true;
            continue;  // Skip isolated nodes
        }
        
        // Start a new component
        ComponentInfo component;
        component.id = component_id++;
        component.size = 0; // Initialize size to 0
        
        std::queue<int> q;
        q.push(start);
        visited[start] = true;
        component.nodes.push_back(start);
        
        // BFS to find all connected nodes and count edges
        while (!q.empty()) {
            int node = q.front();
            q.pop();
            
            for (int neighbor = 0; neighbor < N; neighbor++) {
                if (adj_matrix[node*N + neighbor] > 0) {
                    // Count this edge (but avoid double counting)
                    if (node < neighbor) {
                        component.size += 1.0;
                    }
                    
                    // Continue BFS if neighbor hasn't been visited
                    if (!visited[neighbor]) {
                        visited[neighbor] = true;
                        q.push(neighbor);
                        component.nodes.push_back(neighbor);
                    }
                }
            }
        }
        
        // Only keep components with more than one node
        if (component.nodes.size() > 1) {
            components.push_back(component);
        }
    }
    
    return components;
}


// Function to create cluster statistics map
void create_cluster_stats_map(double* cluster_stats_map, 
                            const double* adj_matrix,
                            const std::vector<ComponentInfo>& components, 
                            int N) {
    // Initialize with zeros
    for (int i = 0; i < N*N; i++) {
        cluster_stats_map[i] = 0;
    }
    
    // Fill in component sizes
    for (size_t comp_idx = 0; comp_idx < components.size(); comp_idx++) {
        const ComponentInfo& component = components[comp_idx];

        for (size_t i = 0; i < component.nodes.size(); i++) {
            int node_i = component.nodes[i];
            
            for (size_t j = i+1; j < component.nodes.size(); j++) {
                int node_j = component.nodes[j];
                
                if (adj_matrix[node_i*N + node_j] > 0) {
                    cluster_stats_map[node_i*N + node_j] = component.size;
                    cluster_stats_map[node_j*N + node_i] = component.size;
                }
            }
        }
    }
}

// Main MEX function
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Check input arguments
    if (nrhs != 2) {
        mexErrMsgIdAndTxt("Size:invalidNumInputs",
                         "Two inputs required: adj_matrix, permuted_adj_matrices");
    }
    
    // Check output arguments
    if (nlhs != 1) {
        mexErrMsgIdAndTxt("Size:invalidNumOutputs",
                         "One output required: p-values");
    }
    
    // Get inputs
    double* adj_matrix = mxGetPr(prhs[0]);
    double* permuted_adj_matrices = mxGetPr(prhs[1]);
    
    // Get dimensions
    const mwSize* dims_adj = mxGetDimensions(prhs[0]);
    int N = static_cast<int>(dims_adj[0]);  // Number of nodes
    
    const mwSize* dims_perm = mxGetDimensions(prhs[1]);
    int K = static_cast<int>(dims_perm[2]);  // Number of permutations
    
    if (dims_adj[0] != dims_adj[1] || dims_perm[0] != dims_perm[1] || 
        dims_adj[0] != dims_perm[0]) {
        mexErrMsgIdAndTxt("Size:invalidDimensions",
                         "Dimensions of adj_matrix and permuted_adj_matrices must be consistent");
    }

    // Verify dimensions of permuted matrices
    if (mxGetNumberOfDimensions(prhs[1]) != 3) {
        mexErrMsgIdAndTxt("Size:invalidDimensions", 
                         "permuted_adj_matrices must be a 3D array (N×N×K)");
    }

    if (dims_perm[0] != N || dims_perm[1] != N) {
        mexErrMsgIdAndTxt("Size:invalidDimensions", 
                         "Dimensions of permuted_adj_matrices must match adj_matrix");
    }
    
    // Find connected components in target data
    std::vector<ComponentInfo> components = get_components_with_sizes(adj_matrix, N);
    
    /*
    mexPrintf("Number of components: %zu\n", components.size());
    for (size_t comp_idx = 0; comp_idx < components.size(); comp_idx++) {
        const ComponentInfo& component = components[comp_idx];
        mexPrintf("Component %d: ID=%d, Size=%.1f, Nodes=%zu\n", 
                  (int)comp_idx, 
                  component.id, 
                  component.size, 
                  component.nodes.size());
                  
        // Optionally print the nodes in each component
        mexPrintf("  Nodes: ");
        for (size_t i = 0; i < component.nodes.size(); i++) {
            mexPrintf("%d ", component.nodes[i]);
            if (i > 0 && i % 10 == 0) {
                mexPrintf("\n         "); // For better formatting of long node lists
            }
        }
        mexPrintf("\n");
    } */
    
    // After getting the adjacency matrix
    /*
    mexPrintf("Input adjacency matrix:\n");
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            mexPrintf("%.1f ", adj_matrix[i*N + j]);
        }
        mexPrintf("\n");
    }
    
    // Print permutation matrices before the loop
    mexPrintf("Permutation matrices:\n");
    for (int k = 0; k < K; k++) {
        mexPrintf("Permutation %d:\n", k);
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                mexPrintf("%.1f ", permuted_adj_matrices[(k*N*N) + (i*N) + j]);
            }
            mexPrintf("\n");
        }
    } */
    
    // Create cluster statistics map
    double* cluster_stats_map = new double[N*N]();
    create_cluster_stats_map(cluster_stats_map, adj_matrix, components, N);
    
    // Compute null distribution
    std::vector<double> null_dist(K);
    double* perm_adj_matrix = new double[N*N]();
    
    for (int k = 0; k < K; k++) {
        // Copy permutation data to properly formed adjacency matrix
        for (int i = 0; i < N*N; i++) {
            perm_adj_matrix[i] = permuted_adj_matrices[i + (k * N * N)];
        }
        
        // Find connected components in permutation
        std::vector<ComponentInfo> perm_components = get_components_with_sizes(perm_adj_matrix, N);
        
        // Get maximum component size for this permutation
        double perm_max_sz = 1;
        for (size_t comp_idx = 0; comp_idx < perm_components.size(); comp_idx++) {
            const ComponentInfo& component = perm_components[comp_idx];
            if (component.size > perm_max_sz) {
                perm_max_sz = component.size;
            }
        }
        
        // Store in null distribution
        null_dist[k] = perm_max_sz;
    }

    // Compute p-values
    mwSize dims_out[2] = {static_cast<mwSize>(N), static_cast<mwSize>(N)};
    plhs[0] = mxCreateNumericArray(2, dims_out, mxDOUBLE_CLASS, mxREAL);
    double* pval = mxGetPr(plhs[0]);
    
    // Initialize with 1s
    for (int i = 0; i < N*N; i++) {
        pval[i] = 1.0;
    }
    
    // Calculate p-values for each edge
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            double stat = cluster_stats_map[i*N + j];
            
            if (stat > 0) {
                double p_count = 0;
                
                // Count how many values in null distribution are >= the statistic
                for (int k = 0; k < K; k++) {
                    if (null_dist[k] >= stat) {
                        p_count += 1.0;
                    }
                }

                // Compute p-value (minimum 0, maximum 1)
                pval[i*N + j] = std::min(p_count / K, 1.0);
            }
        }
    }

    // Add this after calculating null_dist
    /*
    mexPrintf("Null distribution values:\n");
    for (int k = 0; k < K; k++) {
        mexPrintf("  %d: %.1f\n", k, null_dist[k]);
    }
    
    // Add this after creating the cluster_stats_map
    mexPrintf("Cluster stats map (non-zero entries):\n");
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            double stat = cluster_stats_map[i*N + j];
            if (stat > 0) {
                mexPrintf("  (%d,%d): %.1f\n", i, j, stat);
            }
        }
    } */
    
    // Clean up
    delete[] cluster_stats_map;
    delete[] perm_adj_matrix;
}