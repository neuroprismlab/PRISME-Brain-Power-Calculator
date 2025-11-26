# C++ Integration

PRISME supports C++ implementations of statistical methods for performance-critical computations through MATLAB mex. 

Current C++ implementations include TFCE, Cluster Size, and cNBS methods.

## File Organization
```
statistical_methods/
├── mex_scripts/              # C++ source files (.cpp)
│   ├── apply_tfce_cpp.cpp
│   ├── size_pval_cpp.cpp
│   ├── constrained_pval_cpp.cpp
│   └── ...
└── mex_binaries/             # Compiled MEX files (generated)
    ├── apply_tfce_cpp.mexa64
    └── ...
```

## Compilation

Compile all C++ methods by running:
```matlab
compile_mex()
```

This script:
1. Cleans existing MEX binaries
2. Compiles all C++ files from `mex_scripts/`
3. Stores compiled binaries in `mex_binaries/`
4. Adds the binary directory to MATLAB path

Compilation is platform-specific - the script will generate the appropriate binary format for your system (.mexa64 for Linux, .mexmaci64 for macOS, .mexw64 for Windows).

## Naming Convention

C++ implementations use the `_cpp` suffix:
- MATLAB version: `Fast_TFCE.m`
- C++ version: `Fast_TFCE_cpp.m` (wrapper) + `apply_tfce_cpp.cpp` (implementation)

The MATLAB wrapper class calls the compiled MEX function.

## Adding a C++ Method

### Step 1: Write the C++ Function

Create your C++ file in `statistical_methods/mex_scripts/`:
```cpp
// my_method_cpp.cpp
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Get input data
    double *data = mxGetPr(prhs[0]);
    mwSize n = mxGetM(prhs[0]);
    
    // Allocate output
    plhs[0] = mxCreateDoubleMatrix(n, 1, mxREAL);
    double *output = mxGetPr(plhs[0]);
    
    // Your computation here
    for (mwSize i = 0; i < n; i++) {
        output[i] = data[i] * 2.0;  // Example
    }
}
```

### Step 2: Register in compile_mex

Add your file to the `source_files` list in `compile_mex.m`:
```matlab
source_files = {
    'statistical_methods/mex_scripts/apply_tfce_cpp.cpp', ...
    'statistical_methods/mex_scripts/my_method_cpp.cpp', ...  % Add here
    % ... other files
};
```

### Step 3: Create MATLAB Wrapper

Create a MATLAB class that calls your C++ function:
```matlab
classdef My_Method_cpp
    properties
        level = 'variable';
        permutation_based = true;
    end
    
    methods
        function pvals = run_method(obj, varargin)
            params = struct(varargin{:});
            edge_stats = params.edge_stats;
            perm_data = params.permuted_edge_data;
            
            % Call compiled C++ function
            pvals = my_method_cpp(edge_stats, perm_data);
        end
    end
end
```

### Step 4: Compile and Test
```matlab
% Compile
compile_mex();

% Test with developer mode
Params = setparams();
Params.all_cluster_stat_types = {'My_Method_cpp'};
Params.testing = true;
repetition_calculator();
```

## Memory Compatibility

**Critical:** Ensure all MATLAB variables are cast to `double` before passing to C++ functions:
```matlab
% Correct
pvals = my_cpp_function(double(edge_stats));

% Incorrect - may cause memory errors
pvals = my_cpp_function(edge_stats);  % If edge_stats is single precision
```

C++ MEX functions expect double precision by default. Type mismatches can cause crashes or incorrect results.

## Validation

When replacing a MATLAB method with C++:

1. Keep both versions initially
2. Run both on test data
3. Verify identical outputs
4. Benchmark performance improvement

PRISME's permutation recycling ensures both versions receive identical input, making validation straightforward.



## Computational Time Performance Benchmarking

Statistical methods are timed during PRISME calculation execution. Use this feature to benchmark the C++ implementation and see if it is the best for your statistical inference method.

