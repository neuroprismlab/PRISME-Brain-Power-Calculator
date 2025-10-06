#include "mex.h"
#include "matrix.h"
#include <vector>
#include <algorithm>
#include <cmath>

// Structure to hold cluster information
struct Cluster {
    std::vector<bool> nodes;
    int node_size;
    int size;  // number of edges
    bool active;
    bool has_edges;
    
};

// Structure to hold sorted element with its original index
struct SortedElement {
    double value;
    int row;
    int col;
};

// Comparison function for sorting in descending order
bool compareDescending(const SortedElement& a, const SortedElement& b) {
    return a.value > b.value;
}

// Function to update TFCE values
void update_tfce(double* tfce_res, 
                 int node_i, int node_j, int num_nodes,
                 int current_idx, const double* img,
                 double E, double H,
                 const std::vector<SortedElement>& sorted_elements,
                 std::vector<Cluster>& clusters,
                 std::vector<int>& cluster_labels,
                 std::vector<std::vector<bool>>& is_active) {
    
    // Get threshold values for integration
    double th_current = img[node_i + node_j * num_nodes];
    double th_next = 0.0;
    
    if (current_idx > 0) {
        int prev_idx = current_idx - 1;
        int next_row = sorted_elements[prev_idx].row;
        int next_col = sorted_elements[prev_idx].col;
        th_next = img[next_row + next_col*num_nodes];
    }
    
    // Perform exact integration
    for (int n_i = 0; n_i < num_nodes - 1; n_i++) {
        int cluster_size = clusters[cluster_labels[n_i]].size;
        
        for (int n_j = n_i + 1; n_j < num_nodes; n_j++) {
            if (is_active[n_i][n_j]) {
                double contribution = std::pow(cluster_size, E) * 
                                    (std::pow(th_current, H + 1) - std::pow(th_next, H + 1)) / 
                                    (H + 1);
                
                tfce_res[n_i + n_j * num_nodes] += contribution;
                tfce_res[n_j + n_i * num_nodes] += contribution;
            }
        }
    }
}

// Main MEX function
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[]) {
    
    // Check inputs
    if (nrhs != 3) {
        mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce:invalidNumInputs",
                          "Exactly three inputs required: apply_exact_tfce(img, H, E)");
    }
    
    // Check if input is a matrix
    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0])) {
        mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce:invalidInput",
                          "Input matrix must be real double.");
    }
    
    // Get input dimensions
    int num_nodes = mxGetM(prhs[0]);
    int num_cols = mxGetN(prhs[0]);
    
    if (num_nodes != num_cols) {
        mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce:invalidInput",
                          "Input must be a square matrix.");
    }


    // Check H parameter (prhs[1])
    if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) || mxGetNumberOfElements(prhs[1]) != 1) {
        mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce:invalidInput",
                          "H must be a real scalar double.");
    }
    
    // Check E parameter (prhs[2])
    if (!mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) || mxGetNumberOfElements(prhs[2]) != 1) {
        mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce:invalidInput",
                          "E must be a real scalar double.");
    }
    
    // Get all inputs 
    double H, E;
    double* img_input = mxGetPr(prhs[0]);
    H = mxGetScalar(prhs[1]);
    E = mxGetScalar(prhs[2]);

    // Find number of valid edges - upper triangle 
    int n_edges = num_nodes*(num_nodes - 1)/2;
    
    // Create sorted elements array
    std::vector<SortedElement> sorted_elements;
    sorted_elements.reserve(n_edges);
    
    int l_idx = 0;
    for (int j = 0; j < num_nodes; j++) {
        for (int i = 0; i < num_nodes; i++) {
            if (i >= j) {
                continue;
            }

            SortedElement elem;
            elem.value = img_input[i + j * num_nodes];
            elem.row = i;
            elem.col = j;
            sorted_elements.push_back(elem);

            l_idx = l_idx + 1;
        }
    }
    
    // Sort elements in descending order (NaN values will be at the end)
    std::sort(sorted_elements.begin(), sorted_elements.end(), compareDescending);
   
    // Initialize clusters
    std::vector<Cluster> clusters;
    std::vector<int> cluster_labels(num_nodes);
    
    for (int n = 0; n < num_nodes; n++) {
        Cluster new_cluster;

        new_cluster.nodes.resize(num_nodes, false); 
        new_cluster.nodes[n] = true;                
        new_cluster.node_size = 1;
        new_cluster.size = 0;                        
        new_cluster.active = true;
        new_cluster.has_edges = false;
        
        clusters.push_back(new_cluster);
        cluster_labels[n] = n;
    }
    
    // Initialize active edges matrix - vectors of vectors
    std::vector<std::vector<bool>> is_active(num_nodes, std::vector<bool>(num_nodes, false));
    
    // Create output matrix
    plhs[0] = mxCreateDoubleMatrix(num_nodes, num_nodes, mxREAL);
    double* tfce_res = mxGetPr(plhs[0]);
    
    // Initialize output to zeros
    for (int i = 0; i < num_nodes * num_nodes; i++) {
        tfce_res[i] = 0.0;
    }
    
    // Main processing loop (iterate in reverse order through sorted elements)
    for (int i = n_edges - 1; i >= 0; i--) {
        int node_i = sorted_elements[i].row;
        int node_j = sorted_elements[i].col;
        
        // Activate edge
        is_active[node_i][node_j] = true;
        is_active[node_j][node_i] = true;
        
        int cluster_i = cluster_labels[node_i];
        int cluster_j = cluster_labels[node_j];
        
        if (cluster_i != cluster_j) {
            // Merge clusters based on size
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
                    cluster_labels[n] = target_cluster;
                }
            }
            
            clusters[target_cluster].node_size += clusters[absorbed_cluster].node_size;
            clusters[target_cluster].size = clusters[target_cluster].size + 1 + 
                                           clusters[absorbed_cluster].size;
            clusters[absorbed_cluster].active = false;
            
        } else {
            // Simply add an edge to existing cluster
            clusters[cluster_i].size += 1;
            clusters[cluster_i].has_edges = true;
        }
        
        // Update TFCE values
        update_tfce(tfce_res, node_i, node_j, num_nodes, i, img_input, 
                   E, H, sorted_elements, clusters, cluster_labels, is_active);
    }
}