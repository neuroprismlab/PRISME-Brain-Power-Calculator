/*==========================================================
 * ic_exact_tfce.cpp - Exact TFCE for FC (edge-based) data using IC-TFCE
 * Please compile mex before using to guarantee binary is available 
 *
 * Usage (MATLAB):
 *   tfced = ic_exact_tfce(img, H, E)
 *   tfced = ic_exact_tfce(img)         % defaults: H = 3.0, E = 0.4
 *
 * Compile:
 *   mex apply_exact_tfce_cpp.cpp
 *
 * Input : img   - N x N real double, symmetric. Only the upper triangle is read.
 *                 Edges with value <= 0 (or NaN) and the diagonal are ignored.
 *                 The input is NOT modified.
 * Output: tfced - N x N symmetric matrix of exact TFCE values.
 *d.
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
    long long size;     // number of edges in the cluster
    double last_h;      // height up to which 'score' has been integrated
    double last_hp;     // last_h^(H+1), cached
    double score;       // integral accumulated from creation height down to last_h
    int tree_parent;    // cluster created when this one was merged (-1 if root)
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

void exact_tfce_impl(const double *img, size_t N, double H, double E, double *out) {
    for (size_t k = 0; k < N * N; k++) out[k] = 0.0;

    // ---- 1. collect positive edges (upper triangle, column-major) ----
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

    // ---- 2. sort descending ----
    merge_sort_desc(edges);

    // ---- 3. incremental cluster construction with lazy integration ----
    const double Hp1 = H + 1.0;

    std::vector<Cluster> cl;
    std::vector<int> dsu;
    cl.reserve(2 * N);
    dsu.reserve(2 * N);

    std::vector<int> node_cluster(N, -1);      // first cluster id a node joined
    std::vector<int> start_c(m);               // entry cluster of each sorted edge
    std::vector<double> start_s(m);            // score of that cluster at entry

    // Bring cluster c's score down to height h.
    auto flush = [&](int c, double h) {
        Cluster &k = cl[c];
        if (h == k.last_h) return;
        double hp = std::pow(h, Hp1);
        k.score += std::pow((double)k.size, E) * (k.last_hp - hp) / Hp1;
        k.last_h = h;
        k.last_hp = hp;
    };

    auto find = [&](int c) {
        int r = c;
        while (dsu[r] != r) r = dsu[r];
        while (dsu[c] != r) { int nx = dsu[c]; dsu[c] = r; c = nx; }
        return r;
    };

    auto new_cluster = [&](double h, long long size) {
        Cluster k;
        k.size = size;
        k.last_h = h;
        k.last_hp = std::pow(h, Hp1);
        k.score = 0.0;
        k.tree_parent = -1;
        cl.push_back(k);
        int id = (int)cl.size() - 1;
        dsu.push_back(id);
        return id;
    };

    for (size_t r = 0; r < m; r++) {
        const int i = edges[r].i;
        const int j = edges[r].j;
        const double h = edges[r].w;

        int ci = (node_cluster[i] < 0) ? -1 : find(node_cluster[i]);
        int cj = (node_cluster[j] < 0) ? -1 : find(node_cluster[j]);

        if (ci < 0 && cj < 0) {
            // both endpoints new: new cluster with this single edge
            int c = new_cluster(h, 1);
            node_cluster[i] = c;
            node_cluster[j] = c;
            start_c[r] = c;
            start_s[r] = 0.0;
        } else if (ci < 0 || cj < 0) {
            // one endpoint already clustered: edge joins that cluster, other node is absorbed
            int c = (ci >= 0) ? ci : cj;
            int v = (ci >= 0) ? j : i;
            flush(c, h);
            cl[c].size += 1;
            node_cluster[v] = c;
            start_c[r] = c;
            start_s[r] = cl[c].score;
        } else if (ci != cj) {
            // merge two clusters into a new cluster object
            flush(ci, h);
            flush(cj, h);
            long long sz = cl[ci].size + cl[cj].size + 1;
            int c = new_cluster(h, sz);
            cl[ci].tree_parent = c;
            cl[cj].tree_parent = c;
            dsu[ci] = c;
            dsu[cj] = c;
            start_c[r] = c;
            start_s[r] = 0.0;
        } else {
            // same cluster: only the edge count grows
            flush(ci, h);
            cl[ci].size += 1;
            start_c[r] = ci;
            start_s[r] = cl[ci].score;
        }
    }

    // ---- 4. flush every root down to h = 0 ----
    const int nc = (int)cl.size();
    for (int c = 0; c < nc; c++) {
        if (dsu[c] == c) flush(c, 0.0);
    }

    // ---- 5. propagate totals from parents to children (parent id > child id) ----
    std::vector<double> total(nc);
    for (int c = nc - 1; c >= 0; c--) {
        int p = cl[c].tree_parent;
        total[c] = cl[c].score + ((p >= 0) ? total[p] : 0.0);
    }

    // ---- 6. write edge values ----
    for (size_t r = 0; r < m; r++) {
        double v = total[start_c[r]] - start_s[r];
        size_t i = (size_t)edges[r].i;
        size_t j = (size_t)edges[r].j;
        out[i + j * N] = v;
        out[j + i * N] = v;
    }
}

} // namespace

#ifndef EXACT_TFCE_STANDALONE
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if (nrhs < 1 || nrhs > 3)
        mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce_cpp:invalidNumInputs",
                "Usage: tfced = apply_exact_tfce_cpp(img, H, E)");
    if (nlhs > 1)
        mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce_cpp:maxlhs",
                "Too many output arguments.");

    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]))
        mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce_cpp:invalidInput",
                "Input matrix must be real and of type double.");
    if (mxGetNumberOfDimensions(prhs[0]) != 2 || mxGetM(prhs[0]) != mxGetN(prhs[0]))
        mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce_cpp:invalidInput",
                "Input matrix must be square.");

    double H = 3.0;
    double E = 0.4;
    if (nrhs >= 2) {
        if (!mxIsDouble(prhs[1]) || mxGetNumberOfElements(prhs[1]) != 1)
            mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce_cpp:invalidInput",
                    "H must be a double scalar.");
        H = mxGetScalar(prhs[1]);
    }
    if (nrhs >= 3) {
        if (!mxIsDouble(prhs[2]) || mxGetNumberOfElements(prhs[2]) != 1)
            mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce_cpp:invalidInput",
                    "E must be a double scalar.");
        E = mxGetScalar(prhs[2]);
    }
    if (!(H > -1.0))
        mexErrMsgIdAndTxt("MATLAB:apply_exact_tfce_cpp:invalidInput",
                "H must be greater than -1 (the closed-form integral uses H+1).");

    const size_t N = (size_t)mxGetN(prhs[0]);
    plhs[0] = mxCreateDoubleMatrix((mwSize)N, (mwSize)N, mxREAL);
    exact_tfce_impl(mxGetPr(prhs[0]), N, H, E, mxGetPr(plhs[0]));
}
#endif