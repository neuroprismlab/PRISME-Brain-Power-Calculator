# Configuration Parameters

This page describes the parameters in `setparams.m`. This file is located in the project root directory and serves as the configuration file for PRISME. Please modify it to run your analysis. We recommend reviewing the file before going through this guide.

## Quick Reference

- `data_dir` - Path to your dataset used for the analysis
- `list_of_nsubset` - List of sample sizes to perform the power calculation
- `n_repetitions` - Number of subsampling repetitions to be used
- `all_cluster_stat_types` - List of statistical inference methods used in the analysis 
- `n_perms` - Number of permutations used for the non-parametric inference methods

## Data and Output Paths

All attributes here are fields in the Params struct defined in the setparams.m file.

**`data_dir`** (string, required)

Path to the input dataset `.mat` file used for the power calculation. See [Input Data Format](input_format.md) for more instructions.
```matlab
Params.data_dir = './data/my_dataset.mat';
```

**`output`** (string, optional)

Name for the output directory. If not specified, defaults to the dataset filename. PRISME saves the results from the subsampling repetitions in a directory folder called `repetitions`, the ground truth calculation in `ground_truth`, and the power calculation in `power_calculation`. All three folders are contained in a directory named after Params.output within `power_calculator_results`.
```matlab
Params.output = 'my_power_analysis';
```

**`save_directory`** (string, optional)

The directory where all results are saved. Default: `'./power_calculator_results/'`
```matlab
Params.save_directory = './my_results/';
```

**`subsample_file_type`** (string, optional)

Output file format: `'full_file'` or `'compact_file'`. Full files save all relevant p-values and all estimated t-statistics. Therefore, they consume significantly more storage and are slower to checkpoint. Compact files only save the average t-statistic and the number of times each variable was found significant. Default: `'compact_file'`
```matlab
Params.subsample_file_type = 'compact_file';
```

**`atlas_file`** (string or NaN, optional)

Path to a custom brain atlas file. Default: NaN. If no atlas is provided, PRISME cannot assign variables to networks, and network-level inference methods will not be performed.
```matlab
Params.atlas_file = './atlases/schaefer_268.mat';
% or
Params.atlas_file = NaN;  % No atlas
```

**`recalculate`** (boolean, optional)

If `true`, recalculates existing results. If `false`, resumes from existing checkpoints. Default: `false`
```matlab
Params.recalculate = true;  % Force recalculation
```

**`list_of_nsubset`** (cell array, required)

Sample sizes to test in your power analysis.
```matlab
Params.list_of_nsubset = {20, 40, 80, 120, 200};
```

Note: For two-sample t-tests, this is the size per group (total N = 2n).

**`n_repetitions`** (integer, required)

Number of subsampling repetitions.
```matlab
Params.n_repetitions = 100;
```

**`batch_size`** (integer, optional)

Number of repetitions per checkpoint batch. Results are only saved to disk once a batch is completed. Therefore, this parameter balances how much data will be stored in RAM before saving it to disk and checkpointing. The larger it is, the faster the overall calculation, but the more RAM memory will be necessary.
```matlab
Params.batch_size = 50;  % Process 50 repetitions before saving
```

**`tests_to_skip`** (function handle, optional)

Function handle that defines which studies to skip based on their index. Default skips nothing. This will be replaced in a future update.
```matlab
% Skip studies 5-10
ranges = {[5, 10]};
Params.tests_to_skip = @(x) any(cellfun(@(r) (x >= r(1)) && (x <= r(2)), ranges));
```

## Statistical Settings

**`all_cluster_stat_types`** (cell array, required)

Statistical inference methods to evaluate. Some of the available methods:

- `'Parametric'` - Parametric inference using t-distribution
- `'Size_cpp'` - Cluster-size inference with C++ implementation
- `'Fast_TFCE_cpp'` - TFCE with incremental cluster and C++ 
- `'Constrained_cpp'` - cNBS with C++ implementation
- `'Omnibus_cNBS'` - Multivariate whole-brain test

Non-C++ versions are named identically without the `_cpp` suffix.
```matlab
Params.all_cluster_stat_types = {'Parametric', 'Fast_TFCE_cpp', 'Constrained_cpp'};
```

**`all_submethods`** (cell array, optional)

Multiple comparison correction methods. Current options: `'FWER'`, `'FDR'`
```matlab
Params.all_submethods = {'FWER', 'FDR'};
```

**`n_perms`** (integer, required for non-parametric methods)

Number of permutations for non-parametric inference.
```matlab
Params.n_perms = 1000;
```

**`force_permute`** (boolean, optional)

If `true`, forces permutation generation even if parametric methods that don't require permutations are chosen. Default: `false`
```matlab
Params.force_permute = true;
```

**`pthresh_second_level`** (float, optional)

Significance threshold (alpha level). This significance threshold is applied to multiple-comparison corrected p-values when applicable.
```matlab
Params.pthresh_second_level = 0.05;  % 5% significance level
```

**`tthresh_first_level`** (float, optional)

T-statistic threshold for initial cluster formation. Only used by the Cluster Size method. Default: 3.1. This parameter will be moved into method-specific implementations in a future update.
```matlab
Params.tthresh_first_level = 3.1;  % Approximately p=0.001-0.005
```

**`tpr_dthresh`** (float, optional)

Threshold for defining true effects from ground truth. If the magnitude is above this value, the ground truth effect is considered a true effect. Default: 0
```matlab
Params.tpr_dthresh = 0;
```

**`save_significance_thresh`** (float, optional)

Only p-values below this threshold are saved to disk (memory optimisation). Default: 0.15. This only applies to the full_file structure. Compact files only save the number of times a variable was found significant.
```matlab
Params.save_significance_thresh = 0.15;
```

**`cluster_size_type`** (string, optional)

For Cluster Size method: `'Extent'` (cluster size) or `'Intensity'` (cluster mass). Default: `'Extent'`. This parameter will be moved into method-specific implementations in a future update.
```matlab
Params.cluster_size_type = 'Extent';
```

## Parallel Processing

**`parallel`** (boolean, optional)

Enable parallel processing across repetitions. Default: `true`
```matlab
Params.parallel = true;
```

**`n_workers`** (integer, optional)

Number of parallel workers. Set to the number of available CPU cores. Default: `10`
```matlab
Params.n_workers = 16;  % Use 16 cores
```

## Advanced Parameters

**`gt_origin`** (string, deprecated)

Ground truth calculation origin. Deprecated.
```matlab
Params.gt_origin = 'power_calculator';
```

**`nbs_dir`** (string, internal)

Path to NBS directory for internal dependencies.
```matlab
Params.nbs_dir = './NBS1.2';
```

**`other_scripts_dir`** (string, internal)

Deprecated - path to old cNBS scripts.
```matlab
Params.other_scripts_dir = './NBS_benchmarking/support_scripts/';
```

## Developer Options

These parameters enable faster execution for testing and development. **Do not use for actual power calculations.**

**`testing`** (boolean, optional)

Enables testing mode with reduced parameters. Default: `false`
```matlab
Params.testing = true;
```

**`test_n_perms`** (integer, optional)

Reduced permutation count for testing. Default: `10`
```matlab
Params.test_n_perms = 10;
```

**`test_n_repetitions`** (integer, optional)

Reduced repetition count for testing. Default: `5`
```matlab
Params.test_n_repetitions = 5;
```

**`test_n_workers`** (integer, optional)

Worker count for testing. Default: `1`
```matlab
Params.test_n_workers = 1;
```

**`test_disable_save`** (boolean, optional)

Disables saving results during testing. Default: `false`
```matlab
Params.test_disable_save = true;
```