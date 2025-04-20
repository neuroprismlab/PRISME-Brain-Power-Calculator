#include <Eigen/Dense>
#include <vector>
#include <string>
#include <cmath>
#include <algorithm>
#include <mex.h>

// MEX gateway function for MATLAB interface
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Validate inputs
    if (nrhs != 1) {
        mexErrMsgTxt("One input required: GLM structure");
    }
    if (nlhs != 1) {
        mexErrMsgTxt("One output required: test_stat");
    }
    
    // Extract fields from the MATLAB structure
    mxArray *X_field = mxGetField(prhs[0], 0, "X");
    mxArray *y_field = mxGetField(prhs[0], 0, "y");
    mxArray *contrast_field = mxGetField(prhs[0], 0, "contrast");
    mxArray *test_field = mxGetField(prhs[0], 0, "test");
    mxArray *n_GLMs_field = mxGetField(prhs[0], 0, "n_GLMs");
    mxArray *n_observations_field = mxGetField(prhs[0], 0, "n_observations");
    mxArray *n_predictors_field = mxGetField(prhs[0], 0, "n_predictors");
    mxArray *ind_nuisance_field = mxGetField(prhs[0], 0, "ind_nuisance");
    
    // Convert MATLAB arrays to Eigen matrices for efficient computation
    double *X_ptr = mxGetPr(X_field);
    double *y_ptr = mxGetPr(y_field);
    double *contrast_ptr = mxGetPr(contrast_field);
    
    int n_observations = (int)mxGetScalar(n_observations_field);
    int n_predictors = (int)mxGetScalar(n_predictors_field);
    int n_GLMs = (int)mxGetScalar(n_GLMs_field);
    
    // Create Eigen matrices from MATLAB data
    Eigen::Map<Eigen::MatrixXd> X(X_ptr, n_observations, n_predictors);
    Eigen::Map<Eigen::MatrixXd> y(y_ptr, n_observations, n_GLMs);
    Eigen::Map<Eigen::VectorXd> contrast(contrast_ptr, n_predictors);
    
    // Create output array
    plhs[0] = mxCreateDoubleMatrix(1, n_GLMs, mxREAL);
    double *test_stat_ptr = mxGetPr(plhs[0]);
    Eigen::Map<Eigen::VectorXd> test_stat(test_stat_ptr, n_GLMs);
    
    // Get test type
    char test_type[64];
    mxGetString(test_field, test_type, sizeof(test_type));
    std::string test(test_type);
    
    // Compute beta (regression coefficients)
    Eigen::MatrixXd beta = X.colPivHouseholderQr().solve(y);
    
    // Round beta to remove numerical issues (equivalent to MATLAB's round to 14 decimals)
    beta = (beta * 1e14).array().round() / 1e14;
    
    // Compute test statistic based on test type
    if (test == "onesample" || test == "ttest") {
        // Compute residuals
        Eigen::MatrixXd resid = y - X * beta;
        
        // Mean squared error
        Eigen::VectorXd mse = resid.colwise().squaredNorm() / (n_observations - n_predictors);
        
        // Standard error using contrast
        double contrast_term = contrast.transpose() * (X.transpose() * X).inverse() * contrast;
        Eigen::VectorXd se = (mse.array() * contrast_term).sqrt();
        
        // Prevent division by zero
        for (int i = 0; i < se.size(); i++) {
            if (se(i) < 1e-15) se(i) = 1e-15;
        }
        
        // Compute t-statistic
        test_stat = (contrast.transpose() * beta).array() / se.array();
    }
    else if (test == "ftest") {
        // Initialize vectors for sums of squares
        Eigen::VectorXd sse = Eigen::VectorXd::Zero(n_GLMs);
        Eigen::VectorXd ssr = Eigen::VectorXd::Zero(n_GLMs);
        
        // Get mean of y for each column
        Eigen::VectorXd y_mean = y.colwise().mean();
        
        // Sum of squares due to error
        sse = (y - X * beta).colwise().squaredNorm();
        
        // Sum of squares due to regression
        for (int i = 0; i < n_GLMs; i++) {
            Eigen::VectorXd fitted = X * beta.col(i);
            Eigen::VectorXd mean_vec = Eigen::VectorXd::Constant(n_observations, y_mean(i));
            ssr(i) = (fitted - mean_vec).squaredNorm();
        }
        
        // Check if nuisance predictors are present
        if (mxIsEmpty(ind_nuisance_field)) {
            test_stat = (ssr.array() / (n_predictors - 1)) / (sse.array() / (n_observations - n_predictors));
        }
        else {
            // Extract nuisance indices
            int n_nuisance = (int)mxGetNumberOfElements(ind_nuisance_field);
            double *nuisance_ptr = mxGetPr(ind_nuisance_field);
            std::vector<int> ind_nuisance(n_nuisance);
            for (int i = 0; i < n_nuisance; i++) {
                ind_nuisance[i] = (int)nuisance_ptr[i] - 1; // Convert to 0-based indexing
            }
            
            // Create reduced model design matrix
            Eigen::MatrixXd X_new(n_observations, n_nuisance + 1);
            X_new.col(0) = Eigen::VectorXd::Ones(n_observations);
            for (int i = 0; i < n_nuisance; i++) {
                X_new.col(i + 1) = X.col(ind_nuisance[i]);
            }
            
            // Check rank of X_new
            Eigen::ColPivHouseholderQR<Eigen::MatrixXd> qr(X_new);
            int rankx = qr.rank();
            
            // Remove column of ones if rank deficient
            int v = 0;
            Eigen::MatrixXd X_reduced;
            if (rankx < n_nuisance + 1) {
                X_reduced = Eigen::MatrixXd(n_observations, n_nuisance);
                for (int i = 0; i < n_nuisance; i++) {
                    X_reduced.col(i) = X.col(ind_nuisance[i]);
                }
                v = (int)contrast.count(); // Number of non-zero elements in contrast
            }
            else {
                X_reduced = X_new;
                v = (int)contrast.count() - 1;
            }
            
            // Compute reduced model regression
            Eigen::MatrixXd b_red = X_reduced.colPivHouseholderQr().solve(y);
            
            // Compute reduced model sums of squares
            Eigen::VectorXd sse_red = (y - X_reduced * b_red).colwise().squaredNorm();
            Eigen::VectorXd ssr_red = Eigen::VectorXd::Zero(n_GLMs);
            
            for (int i = 0; i < n_GLMs; i++) {
                Eigen::VectorXd fitted = X_reduced * b_red.col(i);
                Eigen::VectorXd mean_vec = Eigen::VectorXd::Constant(n_observations, y_mean(i));
                ssr_red(i) = (fitted - mean_vec).squaredNorm();
            }
            
            // Compute F-statistic
            test_stat = ((ssr.array() - ssr_red.array()) / v) / (sse.array() / (n_observations - n_predictors));
        }
    }
    
    // Replace NaN values with zero
    for (int i = 0; i < n_GLMs; i++) {
        if (std::isnan(test_stat(i))) {
            test_stat(i) = 0;
        }
    }
}