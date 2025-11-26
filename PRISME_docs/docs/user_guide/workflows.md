# Running Workflows

PRISME uses a three-step workflow to calculate statistical power. This page describes how to run each step and interpret the outputs.

## Quick Start

After making the necessary changes to the `setparams.m` script (see [Configuration Parameters](parameters.md)), run these three commands:
```matlab
% Step 1: Generate subsampled repetitions (this takes the longest and uses chec)
repetition_calculator;

% Step 2: Calculate ground truth from full dataset (normally fast)
calculate_gt;

% Step 3: Calculate power by comparing repetitions to ground truth (normally fast)
calculate_power;
```

## Workflow Details

### Step 1: Subsampling Repetitions (`repetition_calculator.m`)

This script performs the repeated subsampling analysis. For each combination of study, sample size, and inference method, it:

1. Randomly samples n subjects from the full dataset
2. Fits a GLM to generate t-statistics for each brain variable
3. Applies the same GLM to permuted versions of the data
4. Passes t-statistics to all specified inference methods
5. Each method produces p-values indicating statistical significance

This process repeats R times (specified by `Params.n_repetitions`).

**Output location:** `./power_calculator_results/[output_name]/repetitions/`

**Filename convention:** `output_name-outcome-test_type-subject_number`

**Checkpoint system:** Results are saved after each batch of repetitions (set by `Params.batch_size`). If interrupted, the script automatically resumes from the last checkpoint.

#### Output Structure

Each output file is a MATLAB struct containing:

- `edge_level_stats` - Sum of t-statistics for each variable (edge or voxel) across all repetitions
- `network_level_stats` - Sum of t-statistics for each network across all repetitions
- `edge_mean_squared_error` - Mean squared error for edge-level statistics (used to calculate variance)
- `network_mean_squared_error` - Mean squared error for network-level statistics (used to calculate variance)
- `meta_data` - Calculation parameters and metadata
- `[inference_method_1]` - Results from first inference method
  - `total_time` - Cumulative computation time for this method across all repetitions
  - `positives` - Count of how many times each variable was found significant (positive effects)
  - `negatives` - Count of how many times each variable was found significant (negative effects)
  - `total_calculations` - Number of repetitions processed
- `[inference_method_2]` - Results from the second inference method
- ... (one field per method)

**Note:** To calculate average t-statistics and variance, calculate_power uses this accumated sums 

### Step 2: Ground Truth Calculation (`calculate_gt.m`)

This script estimates ground truth effects using all N subjects in the dataset. It:

1. Fits the GLM to the complete dataset
2. Computes t-statistics for all variables
3. Derives network-level statistics by averaging variable-level t-statistics
4. Saves results for comparison with subsampled repetitions

**Output location:** `./power_calculator_results/[output_name]/ground_truth/`

**Filename convention:** `output_name-outcome-Ground_Truth-subject_number`

#### Output Structure

- `edge_level_stats` - T-statistics for each variable
- `network_level_stats` - T-statistics for each network
- `meta_data` - Calculation parameters
- `Ground_Truth` - Placeholder method field (returns p-value of 1 for consistency)

### Step 3: Power Calculation (`calculate_power_per_method.m`)

This script calculates statistical power by comparing subsampled repetitions against ground truth. It:

1. Constructs ground truth significance vectors based on t-statistic signs
   - Positive effects: where `edge_level_stats` > `tpr_dthresh` threshold (0 by default)
   - Negative effects: where `edge_level_stats` < `-tpr_dthresh` threshold (0 by default)
2. For whole-brain inference: registers a true positive if any network has a non-zero effect
3. For each method: loads the `positives` and `negatives` counts from repetition files (which track how many times each variable was found significant across all repetitions)
4. Calculates power by dividing these counts by the total number of repetitions (`total_calculations`)

**Output location:** `./power_calculator_results/power_calculation/[output_name]/`

**Filename convention:** `pr-output_name-outcome-test_type-subject_number`

#### Output Structure

- `meta_data` - Calculation parameters
- `edge_level_stats_mean` - Mean t-statistics for each variable across repetitions
- `network_level_stats_mean` - Mean t-statistics for each network across repetitions
- `edge_level_stats_std` - Standard deviation of t-statistics for each variable
- `network_level_stats_std` - Standard deviation of t-statistics for each network
- `[inference_method_1]` - Power results for first method (e.g., `Exact_FC_TFCE_cpp`)
  - `tpr` - True positive rate (power): proportion of correctly detected positive effects
  - `tpr_neg` - True positive rate for negative effects
  - `meta_data` - Method-specific metadata
- `[inference_method_2]` - Power results for the second method
- ... (one field per method)

**Note:** The `tpr` (true positive rate) fields directly represent statistical power for each variable or network, calculated as the proportion of repetitions where the effect was correctly detected.

## Resuming Interrupted Calculations

If `repetition_calculator` is interrupted:

1. The script automatically detects already existing files and missing repetitions from each file
2. Run `repetition_calculator` again (or ‘calculate_gt’)
3. Calculation resumes from the last completed batch

To force a complete recalculation, set `Params.recalculate = true`.