# Input Data Format

PRISME accepts neuroimaging data as MATLAB `.mat` files with a specific structure. This section describes the required format.

## Overview

Your dataset file must contain three components:

- `brain_data` - The neuroimaging data (FC matrices or voxel activations)
- `study_info` - Metadata about the dataset
- `outcome` - Study definitions and test specifications

## brain_data 

The `brain_data` component is a MATLAB struct where each field represents a condition or task (e.g., REST, EMOTION, SOCIAL).

Each condition field contains:

- **data**: Flattened neuroimaging data where each column represents one subject
  - For FC data: Each row is an edge measuring the correlation between two ROI time series
  - For voxel data: Each row is a voxel measuring activation (referred to as nodes in graph representation)
- **sub_ids**: Subject IDs corresponding to each column in the data matrix
- **mask**: (Optional - can be stored in study_info if consistent across tasks) A logical structure that maps flattened variables back to their original spatial positions (ROI pairs for connectivity matrices, brain coordinates for voxels)

## study_info Structure

The `study_info` component contains metadata describing your dataset.

Required fields:

- `dataset` - Dataset identifier (e.g., 'HCP', 'ABCD')
- `map` - Data type (e.g., 'functional_connectivity', 'activation')
- `mask` - A logical structure that maps flattened variables to their original spatial positions

## outcome Structure

The `outcome` component defines the studies PRISME will analyze. Each study is stored as a struct, and the number of elements in `outcome` equals the number of studies.

Required fields for all test types:

- `sub_ids` - Subject identifiers included in this study (can also be stored in brain_data)
- `reference_condition` - Baseline condition (e.g., 'REST')
- `category` - Study category label

Additional fields by test type:

**For correlation analyses:**
- `score` - Continuous measures (e.g., age, behavioral scores)
- `score_label` - Description of the measure

**For condition contrasts:**
- `contrast` - For studies analyzing the difference between two conditions, this specifies both conditions to contrast

### Test Type Inference

PRISME automatically infers the test type (one-sample, two-sample, or correlation) from the `outcome` structure. The function `infer_test_from_data` uses the following logic:

1. **One-sample t-test**: If `score` contains only one unique value, or if `contrast` specifies a single condition
2. **Correlation test**: If `score` is numeric with more than 2 unique values
3. **Two-sample or paired t-test**: If `score` has exactly 2 unique values, or if `contrast` specifies 2 conditions:
   - Calculates subject overlap between the two groups
   - If overlap ≥ unique subjects → One-sample t-test (paired design)
   - If overlap < unique subjects → Two-sample t-test (independent groups)

## Converting Your Data

If your data is not in PRISME format, you'll need to write a conversion script that matches the description above. 
Please follow the data description. 
We also provide dummy datasets that are used for testing in the repository. Please check `test` named datasets under 
`/data/` as a reference to the input data format.

## Example Datasets

Preprocessed HCP and ABCD data in PRISME format can be obtained from the authors upon verification of approved data access from the respective repositories.