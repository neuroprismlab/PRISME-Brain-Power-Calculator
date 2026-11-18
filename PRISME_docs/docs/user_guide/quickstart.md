# Quick Start

This page shows how to run a power analysis using PRISME. It covers the main necessary steps.

## 1. Install

Clone the repository and open it in MATLAB (R2024a or later recommended):

```bash
git clone https://github.com/neuroprismlab/PRISME-Brain-Power-Calculator.git
```

All commands below need to be run from the repository root in MATLAB.

## 2. Prepare the input data

PRISME reads a single `.mat` file containing three variables: `brain_data`, `study_info` and `outcome`.
Convert your data to this format by following [Input Data Format](../user_guide/input_format.md).

Preprocessed datasets in PRISME format (e.g., HCP, ABCD) may be shared with researchers who hold approved access to the original data. 
Requests can be sent to fabriciocravo [at] gmail [dot] com and must include proof of approved access from the original data repository. 
Sharing is subject to the original repositories' data use terms and to institutional approval, and may require a data use agreement between institutions. 
We do not distribute data for which the requester does not have approved access.

The test type is inferred from `outcome`:
| Study type | How to define it in `outcome` |
|---|---|
| One-sample t-test | `contrast = {'TASK'}` (one condition) |
| Paired t-test | `contrast = {'TASK', 'REST'}` with mostly the same subjects in both conditions |
| Two-sample t-test | `contrast = {'TASK', 'REST'}` with mostly different subjects, or a `score` with two unique values (group labels) |
| Correlation | `score` = continuous measure per subject, `score_label` = its name, `reference_condition` = the condition in `brain_data` to use, `contrast = NaN` |

The test datasets in `./data/` (`test_hcp_fc.mat`, `test_t2_fc.mat`, `test_r_fc.mat`, `test_act_act.mat`) are working examples of each format.

## 3. Set the parameters

Set your analysis parameters in `setparams.m`, located in the repository root. 
See [Configuration Parameters](../user_guide/parameters.md) for a description of every option.

## 4. Run the workflow

```matlab
repetition_calculator;   % 1. subsampled repetitions (slowest step - resumes from checkpoints if interrupted)
calculate_gt;            % 2. ground truth from the full dataset
calculate_power;         % 3. power per variable and method
```

All three read their settings from `setparams.m`.

## 5. Results

Results are saved under `./power_calculator_results/`:

| Step | Location |
|---|---|
| Repetitions | `<output>/repetitions/` |
| Ground truth | `<output>/ground_truth/` |
| Power | `power_calculation/<output>/`, files prefixed `pr-` |

In each power file, every method has a `tpr` field (power for positive effects) and a `tpr_neg` field (power for negative effects), 
with one value per variable or network. See [Running Workflows](../user_guide/workflows.md) for the full output structure.
