# Adding New Statistical Methods

PRISME's architecture was designed to facilitate the addition of new statistical inference methods by creating a single MATLAB class file. This guide explains the API and provides examples.



## Important: Implement One-Sided Tests Only

**Your method should implement one-sided tests.** PRISME calls your method twice: once with the original statistics and once with negated statistics. This is because PRISME calculates power separately for positive and negative effects according to its algorithm. 



### Why 

PRISME compares detected effects against ground truth by direction:
- `tpr` - Power for correctly detected positive effects
- `tpr_neg` - Power for correctly detected negative effects

An effect is only counted as correctly detected if both:
1. The p-value is significant in the correct direction of the ground truth
2. The direction matches the ground truth

Two-sided implementations will result in significance being marked repeatedly in tpr and tpr_neg. Please check the algorithm and power definition in the paper for more clarification. 





## Method Class Structure

Place your method class in the `statistical_methods/` directory. The class must define specific properties and implement a `run_method` function.



### Required Properties



**`level`** (string, required)
- Determines what your method returns p-values for
- Options:
  - `'variable'` - One p-value per edge or voxel
  - `'network'` - One p-value per network
  - `'whole_brain'` - Single omnibus p-value

**`permutation_based`** (boolean, required)
- `true` if your method uses permutation testing
- `false` for parametric methods (getting p-values from a statistical distribution)



### Optional Properties

**`submethod`** (cell array, optional)

- Specify multiple return approaches that share the same computation.

- Example: `{'FWER', 'FDR'}` for methods that support both corrections
- When defined, `run_method` must return a struct with one field per submethod. For example, the method must return pvals.FWER and pvals.FDR. 
- A submethod can extend beyond multiple comparisons. At any point, if you wish to reuse the calculations from a method into multiple outputs, please create new submethods. Submethods are simply a way to return more than one set of p-values from a single inference method

**`permutations`** (integer, optional)
- Override the global permutation count for method-specific needs. More computationally extensive methods likely benefit from a number of permutation reductions
- If not specified, uses `Params.n_perms`

**`method_params`** (struct, optional)
- A struct that stores method-specific parameters 

## The run_method Function

Your method receives data through key-value pairs passed to `run_method`:
```matlab
methods
    function pvals = run_method(obj, varargin)
        % Convert key-value pairs to struct
        params = struct(varargin{:});
        
        % Extract inputs
        STATS = params.statistical_parameters;
        edge_stats = params.edge_stats;
        network_stats = params.network_stats;
        perm_edge = params.permuted_edge_data;
        perm_network = params.permuted_network_data;
        
        % Your method implementation here
        pvals = your_computation(edge_stats, perm_edge, STATS);
    end
end
```

**Key pattern:** Convert `varargin` to a struct with `params = struct(varargin{:})`, then access fields directly.



### Input Arguments

PRISME passes these arguments to `run_method`:

**`statistical_parameters`** (struct)

- `n_var` - Number of variables (edges or voxels)

- `n_perms` - Number of permutations
- `variable_type` - Type of data ('edge' or 'node')
- `mask` - Logical mask for flattening/unflattening data
- `edge_groups` - Network assignments for each variable
- `test_type` - Statistical test type ('t', 't2', or 'r')
- `thresh` - T-statistic threshold (for cluster methods)
- `alpha` - Significance threshold
- `submethods` - Struct indicating which submethods to compute
- Helper functions: `unflatten_matrix`, flatten_matrix -  To avoid errors, please avoid using the mask for flattening

**`edge_stats`** (vector)
- T-statistics for each variable from the current repetition
- Size: `[n_var × 1]`

**`network_stats`** (vector)
- Average t-statistics for each network
- Size: `[n_networks × 1]`

**`glm_parameters`** (struct)
- GLM fitting parameters (e.g., degrees of freedom)

**`permuted_edge_data`** (matrix, only if `permutation_based = true`)
- T-statistics from permutations
- Size: `[n_var × n_perms]`

**`permuted_network_data`** (matrix, only if `permutation_based = true`)
- Network-averaged t-statistics from permutations
- Size: `[n_networks × n_perms]`

### Return Value

**Single method (no submethods):**
- Return a vector of p-values
- Size depends on `level`:
  - `'variable'`: `[n_var × 1]`
  - `'network'`: `[n_networks × 1]`
  - `'whole_brain'`: `[1 × 1]`

**Method with submethods:**
- Return a struct where each field is a submethod name
- Each field contains the appropriate p-value vector
```matlab
% Example with submethods
pvals.FWER = fwer_corrected_pvals;
pvals.FDR = fdr_corrected_pvals;
```

## Complete Examples

### Example 1: Simple Parametric Method
```matlab
classdef SimpleParametric
    properties
        level = 'variable';
        permutation_based = false;
    end
    
    methods
        function pvals = run_method(obj, varargin)
            % Convert key-value pairs to struct
            params = struct(varargin{:});
            
            edge_stats = params.edge_stats;
            dof = params.glm_parameters.dof;
            
            % One-sided test: test if statistics are significantly positive
            pvals = 1 - tcdf(edge_stats, dof);
        end
    end
end
```

### Example 2: Permutation-Based Method
```matlab
classdef PermutationMethod
    properties
        level = 'variable';
        permutation_based = true;
    end
    
    methods
        function pvals = run_method(obj, varargin)
            % Convert key-value pairs to struct
            params = struct(varargin{:});
            
            edge_stats = params.edge_stats;
            perm_data = params.permuted_edge_data;
            
            % Calculate p-values from permutation distribution (one-sided)
            n_perms = size(perm_data, 2);
            pvals = zeros(size(edge_stats));
            
            for i = 1:length(edge_stats)
                % Count permutations with values >= observed statistic
                n_extreme = sum(perm_data(i,:) >= edge_stats(i));
                pvals(i) = n_extreme / n_perms;
            end
        end
    end
end
```

### Example 3: Method with Submethods
```matlab
% Note: The Bonferroni and FDR functions below are examples only
classdef MultiCorrectionMethod
    properties
        level = 'variable';
        permutation_based = false;
        submethod = {'FWER', 'FDR'};
    end
    
    methods
        function pvals = run_method(obj, varargin)
            % Convert key-value pairs to struct
            params = struct(varargin{:});
            
            edge_stats = params.edge_stats;
            dof = params.glm_parameters.dof;
            STATS = params.statistical_parameters;
            
            % Compute uncorrected p-values (one-sided)
            uncorrected = 1 - tcdf(edge_stats, dof);
            
            % Initialize output struct
            pvals = struct();
            
            % Apply FWER correction if requested
            if STATS.submethods.FWER
                pvals.FWER = bonferroni_correction(uncorrected);
            end
            
            % Apply FDR correction if requested
            if STATS.submethods.FDR
                pvals.FDR = fdr_correction(uncorrected);
            end
        end
    end
end
```



## Testing Your Method

Please check `power_calculator_test_script.m`. It uses several datasets with known effects to test inference methods. It should work as a sanity test.

Also, please use the developer parameters for a test run to check if the method was correctly implemented.