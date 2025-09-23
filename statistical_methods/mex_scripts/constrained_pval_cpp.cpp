/**
 * constrained_pval_mex.cpp - Simplified MEX implementation for constrained p-value calculations
 * 
 * This MEX function calculates both FWER and FDR p-values for the Constrained NBS method
 * using network indices.
 * 
 * Syntax:
 *   [pvals_fwer, pvals_fdr] = constrained_pval_mex(edge_stats, permuted_edge_stats, network_indices, alpha)
 * 
 * Inputs:
 *   edge_stats         - Raw test statistics for edges (vector)
 *   permuted_edge_stats - Precomputed permutation edge statistics (matrix: edges x permutations)
 *   network_indices    - Network indices for each edge (vector same length as edge_stats)
 *   alpha              - Significance level (scalar, default: 0.05)
 * 
 * Outputs:
 *   pvals_fwer         - P-values with FWER (Bonferroni) correction
 *   pvals_fdr          - Binary indicator of significance after FDR correction
 */

#include "mex.h"
#include "matrix.h"
#include <algorithm>
#include <vector>
#include <cmath>
#include <set>

// Apply FWER correction (Bonferroni)
void applyFWERCorrection(const double* pval_uncorr, double* pval_fwer, mwSize num_networks) {
    for (mwSize i = 0; i < num_networks; i++) {
        pval_fwer[i] = std::min(pval_uncorr[i] * num_networks, 1.0);
    }
}

// Apply FDR correction (Simes procedure)
void applyFDRCorrection(const double* pval_uncorr, double* pval_fdr, double alpha, mwSize num_networks) {
    // Create sorted indices for p-values
    std::vector<std::pair<double, mwSize>> p_indexed(num_networks);
    for (mwSize i = 0; i < num_networks; i++) {
        p_indexed[i] = std::make_pair(pval_uncorr[i], i);
    }
    
    // Sort by p-value
    std::sort(p_indexed.begin(), p_indexed.end());
    
    // Initialize all values to 1 (not significant)
    for (mwSize i = 0; i < num_networks; i++) {
        pval_fdr[i] = 1.0;
    }
    
    // Apply FDR procedure
    for (mwSize j = 0; j < num_networks; j++) {
        double threshold = (j + 1.0) / num_networks * alpha;
        if (p_indexed[j].first <= threshold) {
            // Mark as significant (p-value of 0)
            pval_fdr[p_indexed[j].second] = 0.0;
        } else {
            // Once we exceed the threshold, we can stop
            break;
        }
    }
}

// Main MEX function
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Check inputs
    if (nrhs < 3 || nrhs > 4) {
        mexErrMsgIdAndTxt("MATLAB:constrained_pval_mex:invalidNumInputs",
                "Three or four inputs required: edge_stats, permuted_edge_stats, network_indices, [alpha]");
    }
    
    // Get edge_stats
    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0])) {
        mexErrMsgIdAndTxt("MATLAB:constrained_pval_mex:invalidInput",
                "edge_stats must be a real double vector");
    }
    const double* edge_stats = mxGetPr(prhs[0]);
    mwSize num_edges = mxGetNumberOfElements(prhs[0]);
    
    // Get permuted_edge_stats
    if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1])) {
        mexErrMsgIdAndTxt("MATLAB:constrained_pval_mex:invalidInput",
                "permuted_edge_stats must be a real double matrix");
    }
    const double* permuted_edge_stats = mxGetPr(prhs[1]);
    mwSize num_perms = mxGetN(prhs[1]);  // Permutations are columns
    
    // Check dimensions
    if (mxGetM(prhs[1]) != num_edges) {
        mexErrMsgIdAndTxt("MATLAB:constrained_pval_mex:invalidDimensions",
                "permuted_edge_stats must have dimensions [num_edges x num_perms]");
    }
    
    // Get network_indices
    if (!mxIsDouble(prhs[2]) || mxIsComplex(prhs[2])) {
        mexErrMsgIdAndTxt("MATLAB:constrained_pval_mex:invalidInput",
                "network_indices must be a real double vector");
    }
    const double* network_indices = mxGetPr(prhs[2]);
    
    // Check that network_indices has the same length as edge_stats
    if (mxGetNumberOfElements(prhs[2]) != num_edges) {
        mexErrMsgIdAndTxt("MATLAB:constrained_pval_mex:invalidDimensions",
                "network_indices must have the same length as edge_stats");
    }
    
    // Get alpha (default: 0.05)
    double alpha = 0.05;
    if (nrhs > 3) {
        if (!mxIsDouble(prhs[3]) || mxIsComplex(prhs[3]) || mxGetNumberOfElements(prhs[3]) != 1) {
            mexErrMsgIdAndTxt("MATLAB:constrained_pval_mex:invalidInput",
                    "alpha must be a real scalar");
        }
        alpha = mxGetScalar(prhs[3]);
    }
    
    // Find unique network indices and the maximum index
    std::set<int> network_set;
    int max_network_idx = 0;
    for (mwSize i = 0; i < num_edges; i++) {
        int idx = static_cast<int>(network_indices[i]);
        
        // Zero is not a network
        if(idx == 0) continue;

        network_set.insert(idx);
        if (idx > max_network_idx) {
            max_network_idx = idx;
        }
    }
    mwSize num_networks = network_set.size();
    
    // Create array of unique networks (sorted)
    std::vector<int> unique_networks(network_set.begin(), network_set.end());
    
    // Allocate memory for calculations - using max_network_idx + 1 for direct indexing
    double* network_stats = new double[max_network_idx + 1]();  // () initializes to zero
    double* perm_network_stats = new double[max_network_idx + 1]();  // () initializes to zero
    mwSize* count = new mwSize[max_network_idx + 1]();  // () initializes to zero
    
    // Calculate network statistics for observed data
    for (mwSize e = 0; e < num_edges; e++) {
        int network_idx = static_cast<int>(network_indices[e]);
        
        if(network_idx == 0) continue;

        network_stats[network_idx] += edge_stats[e];
    }
    
    // For each permutation
    for (mwSize p = 0; p < num_perms; p++) {
        // Reset permutation stats to zero
        for (size_t i = 0; i < unique_networks.size(); i++) {
            int idx = unique_networks[i];
            perm_network_stats[idx] = 0.0;
        }
        
        // Get permutation data (column-major indexing)
        const double* perm_data = &permuted_edge_stats[p * num_edges];
        
        // Calculate network statistics for this permutation
        for (mwSize e = 0; e < num_edges; e++) {
            int network_idx = static_cast<int>(network_indices[e]);
            
            if(network_idx == 0) continue;

            perm_network_stats[network_idx] += perm_data[e];
        }
        
        // Compare with observed statistics
        for (size_t i = 0; i < unique_networks.size(); i++) {
            int idx = unique_networks[i];
            if (perm_network_stats[idx] >= network_stats[idx]) {
                count[idx]++;
            }
        }
    }
    
    // Allocate output arrays
    plhs[0] = mxCreateDoubleMatrix(1, num_networks, mxREAL);
    double* pval_fwer = mxGetPr(plhs[0]);
    
    plhs[1] = mxCreateDoubleMatrix(1, num_networks, mxREAL);
    double* pval_fdr = mxGetPr(plhs[1]);
    
    // Calculate uncorrected p-values
    double* pval_uncorr = new double[num_networks];
    for (size_t i = 0; i < unique_networks.size(); i++) {
        int idx = unique_networks[i];
        pval_uncorr[i] = static_cast<double>(count[idx]) / num_perms;
    }
    
    // Apply FWER correction
    applyFWERCorrection(pval_uncorr, pval_fwer, num_networks);
    
    // Apply FDR correction
    applyFDRCorrection(pval_uncorr, pval_fdr, alpha, num_networks);
    
    // Clean up
    delete[] network_stats;
    delete[] perm_network_stats;
    delete[] count;
    delete[] pval_uncorr;
}