/*==========================================================
 * ic_exact_tfce.cpp - Exact TFCE for FC (edge-based) data, IC-TFCE strategy
 * Please compile mex before using to guarantee binary is available
 *
 * Usage (MATLAB):
 *   tfced = ic_exact_tfce(img, H, E)
 *   tfced = ic_exact_tfce(img)         % defaults: H = 3.0, E = 0.4
 *
 * Compile:
 *   mex ic_exact_tfce.cpp
 *
 * Input : img   - N x N real double, symmetric. Only the upper triangle is read.
 *                 Edges with value <= 0 (or NaN) and the diagonal are ignored.
 *                 The input is NOT modified.
 * Output: tfced - N x N symmetric matrix of exact TFCE values.
 *
 * Implements the IC-TFCE Exact variant (manuscript Section 3.2.3):
 * Algorithm 1 where every edge defines its own threshold bin, and the
 * S / F node accumulation matrices are replaced by a per-node running
 * integral F[v] plus the value of F stored when each edge enters.
 *
 *   1. Collect edges with w > 0 and sort them in DESCENDING order
 *      (own bottom-up merge sort). Edge r defines bin r with heights
 *      h_0 >= h_1 >= ... >= h_{m-1} > h_m := 0.
 *   2. Every node starts as its own cluster (nodes {x}, edgeSize 0).
 *   3. For r = 0, ..., m-1:
 *        a. Add edge r (Algorithm 1, lines 20-28): if its endpoints are in
 *           different clusters, merge the smaller into the larger and relabel
 *           the absorbed nodes; otherwise increment edgeSize.
 *        b. Store the entry value of edge r: start[r] = F[i].
 *        c. For EVERY node v (Algorithm 1, lines 31-33 and 37-39):
 *             F[v] += edgeSize(cluster(v))^E * (h_r^(H+1) - h_(r+1)^(H+1)) / (H+1)
 *           The exact integral of h^H over the bin replaces T[h]^H * dh.
 *   4. TFCE(edge r) = F_final[i] - start[r].
 *
 * Complexity: sort O(N^2 log N); edge pass O(N^2) plus O(N log N) for merges;
 * node sweep O(n_th * N) with n_th = N(N-1)/2, i.e. O(N^3) overall.
 * Memory: O(N^2) (edge list and per-edge entry values) + O(N).
 *
 * Implementation note: edgeSize^E is cached per cluster and recomputed only
 * when that cluster's edgeSize changes, so step 3c is one multiply-add per
 * node instead of one pow() per node. This does not change the complexity.
 *========================================================*/

#ifdef EXACT_TFCE_STANDALONE
#include <cstddef>
typedef size_t mwSize;
#else
#include "mex.h"
#endif

#include <vector>
#include <cmath>
#include <cstddef>

namespace {

struct EdgeRec {
    double w;
    int i;
    int j;
};

struct Cluster {
    std::vector<int> nodes;   // node indices in this cluster
    long long edge_size;      // number of edges in this cluster
    double size_pow;          // edge_size^E (0 when edge_size == 0)
};

// Stable bottom-up merge sort, DESCENDING by w.
// Ties keep their original order (left run is taken unless right is strictly larger).
void merge_sort_desc(std::vector<EdgeRec> &a) {
    const size_t n = a.size();
    if (n < 2) return;

    std::vector<EdgeRec> buf(n);
    EdgeRec *src = a.data();
    EdgeRec *dst = buf.data();

    for (size_t width = 1; width < n; width *= 2) {
        for (size_t lo = 0; lo < n; lo += 2 * width) {
            size_t mid = (lo + width < n) ? lo + width : n;
            size_t hi  = (lo + 2 * width < n) ? lo + 2 * width : n;
            size_t l = lo, r = mid, k = lo;
            while (l < mid && r < hi) {
                if (src[r].w > src[l].w)
                    dst[k++] = src[r++];
                else
                    dst[k++] = src[l++];
            }
            while (l < mid)
                dst[k++] = src[l++];
            while (r < hi)
                dst[k++] = src[r++];
        }
        EdgeRec *tmp = src; src = dst; dst = tmp;
    }

    // After the last pass the sorted data lives in 'src'.
    if (src != a.data()) {
        for (size_t k = 0; k < n; k++) a[k] = src[k];
    }
}

void ic_exact_tfce_impl(const double *img, size_t N, double H, double E, double *out) {
    for (size_t k = 0; k < N * N; k++) out[k] = 0.0;

    // ---- 1. collect positive edges (upper triangle, column-major) and sort ----
    std::vector<EdgeRec> edges;
    edges.reserve(N * (N > 0 ? N - 1 : 0) / 2);
    for (size_t j = 1; j < N; j++) {
        for (size_t i = 0; i < j; i++) {
            double w = img[i + j * N];
            if (w > 0.0) {               // also rejects NaN
                EdgeRec e = { w, (int)i, (int)j };
                edges.push_back(e);
            }
        }
    }
    const size_t m = edges.size();
    if (m == 0) return;

    merge_sort_desc(edges);

    // Bin boundaries: hp[r] = h_r^(H+1), with h_m = 0
    const double Hp1 = H + 1.0;
    std::vector<double> hp(m + 1);
    for (size_t r = 0; r < m; r++) hp[r] = std::pow(edges[r].w, Hp1);
    hp[m] = 0.0;

    // ---- 2. initialise singleton clusters (Algorithm 1, lines 12-15) ----
    std::vector<Cluster> clusters(N);
    std::vector<int> cluster_label(N);
    for (size_t x = 0; x < N; x++) {
        clusters[x].nodes.assign(1, (int)x);
        clusters[x].edge_size = 0;
        clusters[x].size_pow = 0.0;
        cluster_label[x] = (int)x;
    }

    auto update_pow = [&](Cluster &c) {
        c.size_pow = (c.edge_size > 0) ? std::pow((double)c.edge_size, E) : 0.0;
    };

    std::vector<double> F(N, 0.0);   // running TFCE integral per node
    std::vector<double> start(m);    // F[i] when edge r entered

    // ---- 3. one bin per edge, from the highest height to the lowest ----
    for (size_t r = 0; r < m; r++) {
        const int i = edges[r].i;
        const int j = edges[r].j;
        const int ci = cluster_label[i];
        const int cj = cluster_label[j];

        // 3a. add edge r
        if (ci != cj) {
            // merge smaller (by node count) into larger, relabel absorbed nodes
            int target = ci, absorbed = cj;
            if (clusters[cj].nodes.size() > clusters[ci].nodes.size()) {
                target = cj;
                absorbed = ci;
            }
            Cluster &t = clusters[target];
            Cluster &a = clusters[absorbed];
            for (size_t k = 0; k < a.nodes.size(); k++) {
                cluster_label[a.nodes[k]] = target;
                t.nodes.push_back(a.nodes[k]);
            }
            t.edge_size += a.edge_size + 1;
            a.nodes.clear();
            a.edge_size = 0;
            a.size_pow = 0.0;
            update_pow(t);
        } else {
            clusters[ci].edge_size += 1;
            update_pow(clusters[ci]);
        }

        // 3b. entry value of edge r (both endpoints now share a cluster)
        start[r] = F[i];

        // 3c. accumulate the bin integral for every node
        const double dint = (hp[r] - hp[r + 1]) / Hp1;
        if (dint != 0.0) {           // tied heights give zero-width bins
            for (size_t v = 0; v < N; v++) {
                F[v] += clusters[cluster_label[v]].size_pow * dint;
            }
        }
    }

    // ---- 4. TFCE(edge r) = F_final[i] - start[r] ----
    for (size_t r = 0; r < m; r++) {
        const size_t i = (size_t)edges[r].i;
        const size_t j = (size_t)edges[r].j;
        const double v = F[i] - start[r];
        out[i + j * N] = v;
        out[j + i * N] = v;
    }
}

} // namespace

#ifndef EXACT_TFCE_STANDALONE
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if (nrhs < 1 || nrhs > 3)
        mexErrMsgIdAndTxt("MATLAB:ic_exact_tfce:invalidNumInputs",
                "Usage: tfced = ic_exact_tfce(img, H, E)");
    if (nlhs > 1)
        mexErrMsgIdAndTxt("MATLAB:ic_exact_tfce:maxlhs",
                "Too many output arguments.");

    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]))
        mexErrMsgIdAndTxt("MATLAB:ic_exact_tfce:invalidInput",
                "Input matrix must be real and of type double.");
    if (mxGetNumberOfDimensions(prhs[0]) != 2 || mxGetM(prhs[0]) != mxGetN(prhs[0]))
        mexErrMsgIdAndTxt("MATLAB:ic_exact_tfce:invalidInput",
                "Input matrix must be square.");

    double H = 3.0;
    double E = 0.4;
    if (nrhs >= 2) {
        if (!mxIsDouble(prhs[1]) || mxGetNumberOfElements(prhs[1]) != 1)
            mexErrMsgIdAndTxt("MATLAB:ic_exact_tfce:invalidInput",
                    "H must be a double scalar.");
        H = mxGetScalar(prhs[1]);
    }
    if (nrhs >= 3) {
        if (!mxIsDouble(prhs[2]) || mxGetNumberOfElements(prhs[2]) != 1)
            mexErrMsgIdAndTxt("MATLAB:ic_exact_tfce:invalidInput",
                    "E must be a double scalar.");
        E = mxGetScalar(prhs[2]);
    }
    if (!(H > -1.0))
        mexErrMsgIdAndTxt("MATLAB:ic_exact_tfce:invalidInput",
                "H must be greater than -1 (the closed-form integral uses H+1).");

    const size_t N = (size_t)mxGetN(prhs[0]);
    plhs[0] = mxCreateDoubleMatrix((mwSize)N, (mwSize)N, mxREAL);
    ic_exact_tfce_impl(mxGetPr(prhs[0]), N, H, E, mxGetPr(plhs[0]));
}
#endif