#include <vector>
#include <cmath>
#include <algorithm>
#include <queue>
#include <cstring>
#include "mex.h"

// Find connected components using BFS and return cluster edge counts for each node
void findConnectedComponents(const std::vector<std::vector<double>>& adjMatrix, 
                            double threshold,
                            std::vector<int>& clusterSizePerNode) {
    int n = adjMatrix.size();
    std::vector<bool> visited(n, false);
    std::fill(clusterSizePerNode.begin(), clusterSizePerNode.end(), 0);
    
    for (int start = 0; start < n; ++start) {
        if (visited[start]) continue;
        
        // BFS to find component
        std::queue<int> q;
        std::vector<int> component;
        q.push(start);
        visited[start] = true;
        component.push_back(start);
        
        // Count edges in this component
        int edgeCount = 0;
        
        while (!q.empty()) {
            int node = q.front();
            q.pop();
            
            for (int neighbor = 0; neighbor < n; ++neighbor) {
                if (adjMatrix[node][neighbor] >= threshold) {
                    // Count this edge (only upper triangle to avoid double counting)
                    if (node < neighbor) {
                        edgeCount++;
                    }
                    
                    if (!visited[neighbor]) {
                        visited[neighbor] = true;
                        q.push(neighbor);
                        component.push_back(neighbor);
                    }
                }
            }
        }
        
        // Assign cluster size (number of edges) to all nodes in component
        for (int node : component) {
            clusterSizePerNode[node] = edgeCount;
        }
    }
}

// Main TFCE computation
std::vector<std::vector<double>> computeTFCE(const std::vector<std::vector<double>>& img,
                                             double H, double E, double dh) {
    int n = img.size();
    std::vector<std::vector<double>> tfced(n, std::vector<double>(n, 0.0));
    
    // Find maximum value in the matrix
    double maxVal = 0.0;
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {  // Only upper triangle
            maxVal = std::max(maxVal, img[i][j]);
        }
    }
    
    // Generate thresholds - matching Fast_TFCE implementation exactly
    std::vector<double> thresholds;
    for (double t = 0.0; t <= maxVal + dh; t += dh) {
        thresholds.push_back(t);
    }
    
    // Vector to store cluster sizes for each node at current threshold
    std::vector<int> clusterSizePerNode(n);
    
    // For each threshold (skip index 0, matching Fast_TFCE)
    for (size_t h = 1; h < thresholds.size(); ++h) {
        double thresh = thresholds[h];
        // Find connected components at this threshold
        findConnectedComponents(img, thresh, clusterSizePerNode);
        
        // Calculate TFCE contribution for each edge
        for (int i = 0; i < n; ++i) {
            for (int j = i + 1; j < n; ++j) {
                if (img[i][j] >= thresh && clusterSizePerNode[i] > 0) {
                    // Both nodes should have the same cluster size
                    double contribution = std::pow(clusterSizePerNode[i], E) * 
                                        std::pow(thresh, H) * dh;
                
                    tfced[i][j] += contribution;
                    tfced[j][i] += contribution;  // Symmetric
                }
            }
        }
    }
    
    return tfced;
}

// MEX gateway function
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Check input arguments
    if (nrhs != 4) {
        mexErrMsgIdAndTxt("TFCE:invalidNumInputs",
                          "Four inputs required: matrix, H, E, dh");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt("TFCE:invalidNumOutputs",
                          "Too many output arguments");
    }
    
    // Get input matrix
    if (!mxIsDouble(prhs[0])) {
        mexErrMsgIdAndTxt("TFCE:invalidInput",
                          "Input matrix must be double");
    }
    
    double *matrixPtr = mxGetPr(prhs[0]);
    int rows = mxGetM(prhs[0]);
    int cols = mxGetN(prhs[0]);
    
    if (rows != cols) {
        mexErrMsgIdAndTxt("TFCE:invalidInput",
                          "Input must be a square matrix");
    }
    
    // Get parameters
    double H, E, dh;
    H = mxGetScalar(prhs[1]);
    E = mxGetScalar(prhs[2]);
    dh = mxGetScalar(prhs[3]);
    
    // Convert MATLAB matrix to C++ vector (column-major to row-major)
    std::vector<std::vector<double>> img(rows, std::vector<double>(cols));
    for (int i = 0; i < rows; ++i) {
        for (int j = 0; j < cols; ++j) {
            img[i][j] = matrixPtr[j * rows + i];
            // Apply preprocessing similar to MATLAB version
            if (img[i][j] > 1000) {
                img[i][j] = 100;
            }
            // Set diagonal to zero
            if (i == j) {
                img[i][j] = 0;
            }
        }
    }
    
    // Compute TFCE
    std::vector<std::vector<double>> tfced = computeTFCE(img, H, E, dh);
    
    // Create output matrix
    plhs[0] = mxCreateDoubleMatrix(rows, cols, mxREAL);
    double *outputPtr = mxGetPr(plhs[0]);
    
    // Convert back to MATLAB format (row-major to column-major)
    for (int i = 0; i < rows; ++i) {
        for (int j = 0; j < cols; ++j) {
            outputPtr[j * rows + i] = tfced[i][j];
        }
    }
}